package com.example.offline_tutor_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val P2P_PERMISSION_REQUEST_CODE = 44091
		private var sharedLlamaEngine: LlamaEngine? = null
	}

	private val channelName = "offline_tutor/llm"
	private val streamChannelName = "offline_tutor/llm_stream"
	private val metricsChannelName = "offline_tutor/llm_metrics"
	private val modelCopyProgressChannelName = "offline_tutor/model_copy_progress"
	private val p2pChannelName = "offline_tutor/p2p"
	private lateinit var llamaEngine: LlamaEngine
	private lateinit var p2pManager: P2PManager
	private var pendingP2PPermissionResult: MethodChannel.Result? = null
	private var modelCopyProgressSink: EventChannel.EventSink? = null
	private var llmMetricsSink: EventChannel.EventSink? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		llamaEngine = sharedLlamaEngine ?: LlamaEngine(applicationContext).also {
			sharedLlamaEngine = it
		}
		p2pManager = P2PManager(applicationContext)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, streamChannelName)
			.setStreamHandler(
				object : EventChannel.StreamHandler {
					override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
						Log.i("LLM", "[LLM] onListen called for stream channel")
						val args = arguments as? Map<*, *>
						val question = args?.get("question") as? String
						val trimmed = question?.trim().orEmpty()
						if (trimmed.isEmpty()) {
							runOnUiThread {
								events.error("INVALID_INPUT", "Question is empty", null)
							}
							return
						}

						Thread {
							val startTime = SystemClock.elapsedRealtime()
							val emittedAnyToken = java.util.concurrent.atomic.AtomicBoolean(false)
							val flushWindowMs = 30L
							val tokenBuffer = StringBuilder()
							val bufferLock = Any()
							var lastFlushAt = startTime


							fun emitSuccessOnMainThread(payload: String) {
								runOnUiThread {
									events.success(payload)
								}
							}

							fun emitErrorOnMainThread(code: String, message: String) {
								runOnUiThread {
									events.error(code, message, null)
								}
							}

							fun endStreamOnMainThread() {
								runOnUiThread {
									events.endOfStream()
								}
							}

							fun emitMetricsOnMainThread(totalMs: Long, tokens: Int, tokensPerSec: Int) {
								runOnUiThread {
									llmMetricsSink?.success(
										mapOf(
											"totalMs" to totalMs,
											"tokens" to tokens,
											"tokensPerSec" to tokensPerSec,
										),
									)
								}
							}

							fun flushBufferedTokens(force: Boolean = false) {
								val payload: String
								synchronized(bufferLock) {
									if (tokenBuffer.isEmpty()) {
										return
									}

									val now = SystemClock.elapsedRealtime()
									if (!force && now - lastFlushAt < flushWindowMs) {
										return
									}

									payload = tokenBuffer.toString()
									tokenBuffer.setLength(0)
									lastFlushAt = now
								}

								emitSuccessOnMainThread(payload)
								emittedAnyToken.set(true)
							}

							try {
								println("[LLM] [TRACE] STREAM_THREAD=${Thread.currentThread().name}")
								println("[LLM] 🚀 Starting inference: '${trimmed.take(50)}...'")
								println("[LLM] [TRACE] CALLING_ASK_STREAM_FAST promptLength=${trimmed.length}")

								println("[LLM] Inference starting (may take 30-60s for large models)...")
								val finalAnswer = llamaEngine.askStreamFast(trimmed) { token ->
									if (token.isEmpty()) {
										return@askStreamFast
									}

									var shouldFlush = false
									synchronized(bufferLock) {
										tokenBuffer.append(token)
										val now = SystemClock.elapsedRealtime()
										shouldFlush = token.contains('\n') ||
													tokenBuffer.length >= 64 ||
											now - lastFlushAt >= flushWindowMs
									}

									if (shouldFlush) {
										flushBufferedTokens(force = true)
									}
								}



								println("[LLM] [TRACE] ASK_STREAM_FAST_RETURNED answerLength=${finalAnswer.length}")
								flushBufferedTokens(force = true)

								val totalTimeMs = SystemClock.elapsedRealtime() - startTime
								val responseLength = finalAnswer.length
								val estimatedTokens = responseLength / 4
								val tokensPerSec = if (totalTimeMs > 0) {
									(estimatedTokens * 1000.0 / totalTimeMs).toInt()
								} else {
									0
								}

								println("[LLM] ✓ Complete: ${totalTimeMs}ms | Speed: $tokensPerSec t/s | Tokens: $estimatedTokens")

								val failed =
									finalAnswer.startsWith("Failed to") || finalAnswer.startsWith("Model cannot")

								if (failed && !emittedAnyToken.get()) {
									println("[LLM] [TRACE] EMITTING_ERROR")
									emitErrorOnMainThread("LLM_FAILURE", finalAnswer)
								} else {
									if (!emittedAnyToken.get() && finalAnswer.isNotBlank()) {
										println("[LLM] [TRACE] EMITTING_FINAL_ANSWER (no streaming tokens)")
										emitSuccessOnMainThread(finalAnswer)
									}
									emitMetricsOnMainThread(totalTimeMs, estimatedTokens, tokensPerSec)
									println("[LLM] [TRACE] ENDING_STREAM")
									endStreamOnMainThread()
								}
							} catch (e: Throwable) {

								println("[LLM] [TRACE] EXCEPTION: ${e.javaClass.simpleName}: ${e.message}")
								flushBufferedTokens(force = true)
								if (emittedAnyToken.get()) {
									endStreamOnMainThread()
								} else {
									emitErrorOnMainThread("LLM_ERROR", e.message ?: "Inference failed")
								}
							}
						}.start()
					}

					override fun onCancel(arguments: Any?) {
						llamaEngine.stopGeneration()
						println("[LLM] ⏹️  Generation stopped by user")
					}
				},
			)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, metricsChannelName)
			.setStreamHandler(
				object : EventChannel.StreamHandler {
					override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
						llmMetricsSink = events
					}

					override fun onCancel(arguments: Any?) {
						llmMetricsSink = null
					}
				},
			)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, modelCopyProgressChannelName)
			.setStreamHandler(
				object : EventChannel.StreamHandler {
					override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
						modelCopyProgressSink = events
					}

					override fun onCancel(arguments: Any?) {
						modelCopyProgressSink = null
					}
				},
			)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"stopGeneration" -> {
						result.success(llamaEngine.stopGeneration())
					}

					"getGenerationConfig" -> {
						result.success(llamaEngine.getGenerationConfig())
					}

					"updateGenerationConfig" -> {
						val maxTokens = call.argument<Int>("maxTokens")
						val timeoutMs = call.argument<Int>("timeoutMs")
						val systemPrompt = call.argument<String>("systemPrompt")
						try {
							val updated = llamaEngine.updateGenerationConfig(
								maxTokens = maxTokens,
								timeoutMs = timeoutMs,
								systemPrompt = systemPrompt,
							)
							result.success(updated)
						} catch (e: Throwable) {
							result.error(
								"UPDATE_CONFIG_FAILED",
								e.message ?: "Failed to update generation config",
								null,
							)
						}
					}

					"resetEngine" -> {
						result.success(llamaEngine.resetEngine())
					}

					"runPerformanceProbe" -> {
						val iterations = call.argument<Int>("iterations") ?: 3
						Thread {
							try {
								val probe = llamaEngine.runPerformanceProbe(iterations)
								runOnUiThread { result.success(probe) }
							} catch (e: Throwable) {
								runOnUiThread {
									result.error(
										"PERF_PROBE_FAILED",
										e.message ?: "Performance probe failed",
										null,
									)
								}
							}
						}.start()
					}

					"getEngineStatus" -> {
						result.success(llamaEngine.getEngineStatus())
					}

					"preloadModel" -> {
						val success = llamaEngine.preloadModel()
						result.success(success)
					}

					"runEngineSelfTest" -> {
						Thread {
							try {
								val probe = llamaEngine.runInferenceHealthCheck()
								runOnUiThread { result.success(probe) }
							} catch (e: Throwable) {
								runOnUiThread {
									result.error(
										"SELF_TEST_FAILED",
										e.message ?: "Inference health check failed",
										null,
									)
								}
							}
						}.start()
					}

					"getModelPath" -> {
						val status = llamaEngine.getEngineStatus()
						result.success(status["modelPath"] as? String ?: "")
					}

					"getModelMetadata" -> {
						result.success(llamaEngine.getModelMetadata())
					}

					"setModelPath" -> {
						val modelPath = call.argument<String>("modelPath")?.trim().orEmpty()
						if (modelPath.isEmpty()) {
							result.error("INVALID_MODEL_PATH", "Model path is empty", null)
							return@setMethodCallHandler
						}

					Thread {
						try {
							val updated = llamaEngine.setModelPath(modelPath) { progress ->
								runOnUiThread {
									modelCopyProgressSink?.success(progress)
								}
							}
							runOnUiThread {
								result.success(updated)
							}
						} catch (e: Throwable) {
							runOnUiThread {
								result.error(
									"SET_MODEL_PATH_FAILED",
									e.message ?: "Failed to set model path",
									null,
								)
							}
						}
					}.start()
					}

					"streamQuestionFast" -> {
						val question = call.argument<String>("question")?.trim().orEmpty()
						if (question.isEmpty()) {
							result.error("INVALID_INPUT", "Question is empty", null)
							return@setMethodCallHandler
						}

						Thread {
							try {
								llamaEngine.askStreamFast(question) { token ->
									runOnUiThread {
										result.success(token)
									}
								}
								runOnUiThread { result.success(null) }
							} catch (e: Throwable) {
								runOnUiThread {
									result.error(
										"LLM_STREAM_FAILURE",
										e.message ?: "Failed to stream response",
										null,
									)
								}
							}
						}.start()
					}

					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, p2pChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getStatus" -> result.success(p2pManager.getStatus())
					"getTransferTelemetry" -> result.success(p2pManager.getTransferTelemetry())
					"listPeers" -> result.success(p2pManager.listPeers())
					"getPermissionStatus" -> result.success(getP2PPermissionStatus())
					"requestPermissions" -> requestP2PPermissions(result)
					"startReceiver" -> result.success(p2pManager.startReceiver())
					"stopReceiver" -> result.success(p2pManager.stopReceiver())
					"listReceivedBundles" -> result.success(p2pManager.listReceivedBundles())
					"listPendingIncomingTransfers" -> result.success(p2pManager.listPendingIncomingTransfers())
					"approveIncomingTransfer" -> {
						val id = call.argument<String>("id")?.trim().orEmpty()
						if (id.isEmpty()) {
							result.error("INVALID_INPUT", "id is required", null)
						} else {
							result.success(p2pManager.approveIncomingTransfer(id))
						}
					}
					"rejectIncomingTransfer" -> {
						val id = call.argument<String>("id")?.trim().orEmpty()
						if (id.isEmpty()) {
							result.error("INVALID_INPUT", "id is required", null)
						} else {
							result.success(p2pManager.rejectIncomingTransfer(id))
						}
					}
					"sendBundle" -> {
						val address = call.argument<String>("address")?.trim().orEmpty()
						val filePath = call.argument<String>("filePath")?.trim().orEmpty()
						if (address.isEmpty() || filePath.isEmpty()) {
							result.error("INVALID_INPUT", "address and filePath are required", null)
						} else {
							result.success(p2pManager.sendBundle(address, filePath))
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun getP2PPermissionStatus(): Map<String, Any> {
		val locationGranted = ContextCompat.checkSelfPermission(
			this,
			Manifest.permission.ACCESS_FINE_LOCATION,
		) == PackageManager.PERMISSION_GRANTED

		val requiresNearbyWifi = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
		val nearbyWifiGranted = if (requiresNearbyWifi) {
			ContextCompat.checkSelfPermission(
				this,
				Manifest.permission.NEARBY_WIFI_DEVICES,
			) == PackageManager.PERMISSION_GRANTED
		} else {
			true
		}

		return mapOf(
			"locationGranted" to locationGranted,
			"nearbyWifiGranted" to nearbyWifiGranted,
			"requiresNearbyWifi" to requiresNearbyWifi,
			"allGranted" to (locationGranted && nearbyWifiGranted),
		)
	}

	private fun requestP2PPermissions(result: MethodChannel.Result) {
		val status = getP2PPermissionStatus()
		val allGranted = status["allGranted"] as? Boolean ?: false
		if (allGranted) {
			result.success(status)
			return
		}

		if (pendingP2PPermissionResult != null) {
			result.error("PERMISSION_BUSY", "Another permission request is in progress.", null)
			return
		}

		val permissions = mutableListOf(Manifest.permission.ACCESS_FINE_LOCATION)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
		}

		pendingP2PPermissionResult = result
		ActivityCompat.requestPermissions(
			this,
			permissions.toTypedArray(),
			P2P_PERMISSION_REQUEST_CODE,
		)
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode != P2P_PERMISSION_REQUEST_CODE) {
			return
		}

		val pending = pendingP2PPermissionResult
		pendingP2PPermissionResult = null
		pending?.success(getP2PPermissionStatus())
	}

	override fun onDestroy() {
		if (::llamaEngine.isInitialized) {
			llamaEngine.close()
		}
		super.onDestroy()
	}
}
