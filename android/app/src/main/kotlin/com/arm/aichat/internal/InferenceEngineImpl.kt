package com.arm.aichat.internal

import android.content.Context
import android.util.Log
import com.arm.aichat.InferenceEngine
import dalvik.annotation.optimization.FastNative
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException

internal class InferenceEngineImpl private constructor(
    private val nativeLibDir: String,
) : InferenceEngine {

    companion object {
        private val TAG = InferenceEngineImpl::class.java.simpleName

        internal fun getInstance(context: Context): InferenceEngine {
            val nativeLibDir = context.applicationInfo.nativeLibraryDir
            require(nativeLibDir.isNotBlank()) { "Expected a valid native library path" }
            return InferenceEngineImpl(nativeLibDir)
        }
    }

    @FastNative
    private external fun init(nativeLibDir: String)

    @FastNative
    private external fun load(modelPath: String): Int

    @FastNative
    private external fun prepare(): Int

    @FastNative
    private external fun systemInfo(): String

    @FastNative
    private external fun benchModel(pp: Int, tg: Int, pl: Int, nr: Int): String

    @FastNative
    private external fun processSystemPrompt(systemPrompt: String): Int

    @FastNative
    private external fun processUserPrompt(userPrompt: String, predictLength: Int): Int

    @FastNative
    private external fun generateNextToken(): String?

    @FastNative
    private external fun generateFullResponse(systemPrompt: String, userPrompt: String, predictLength: Int): String

    @FastNative
    private external fun requestStopGeneration()

    @FastNative
    private external fun unload()

    @FastNative
    private external fun shutdown()

    private val _state = MutableStateFlow<InferenceEngine.State>(InferenceEngine.State.Uninitialized)
    override val state: StateFlow<InferenceEngine.State> = _state.asStateFlow()
    private val initReady = CompletableDeferred<Unit>()

    private var readyForSystemPrompt = false
    @Volatile
    private var cancelGeneration = false

    @OptIn(ExperimentalCoroutinesApi::class)
    private val llamaDispatcher = Dispatchers.IO.limitedParallelism(1)

    init {
        runBlocking(llamaDispatcher) {
            try {
                check(_state.value is InferenceEngine.State.Uninitialized) {
                    "Cannot load native library in ${_state.value.javaClass.simpleName}"
                }
                _state.value = InferenceEngine.State.Initializing
                System.loadLibrary("ai-chat")
                init(nativeLibDir)
                _state.value = InferenceEngine.State.Initialized
                initReady.complete(Unit)
                Log.i(TAG, "Native library loaded: ${systemInfo()}")
            } catch (t: Throwable) {
                if (!initReady.isCompleted) {
                    initReady.completeExceptionally(t)
                }
                val e = if (t is Exception) t else RuntimeException(t.message ?: "Native init failed", t)
                _state.value = InferenceEngine.State.Error(e)
                Log.e(TAG, "Failed to initialize inference engine", t)
                throw e
            }
        }
    }

    override suspend fun loadModel(pathToModel: String) =
        withContext(llamaDispatcher) {
            initReady.await()

            if (_state.value is InferenceEngine.State.ModelReady) {
                return@withContext
            }

            when (_state.value) {
                is InferenceEngine.State.Error -> {
                    _state.value = InferenceEngine.State.Initialized
                }
                is InferenceEngine.State.LoadingModel -> {
                    // Recover from interrupted / failed previous load attempt.
                    _state.value = InferenceEngine.State.Initialized
                }
                is InferenceEngine.State.Initialized -> {
                    // expected state for loading a model
                }
                else -> {
                    throw IllegalStateException(
                        "Cannot load model in ${_state.value.javaClass.simpleName}",
                    )
                }
            }

            try {
                File(pathToModel).let {
                    require(it.exists()) { "File not found" }
                    require(it.isFile) { "Not a valid file" }
                    require(it.canRead()) { "Cannot read file" }
                }

                readyForSystemPrompt = false
                _state.value = InferenceEngine.State.LoadingModel

                val loadCode = load(pathToModel)
                if (loadCode != 0) {
                    throw IOException(
                        "Native model load failed (code=$loadCode). Check GGUF compatibility and free RAM.",
                    )
                }

                val prepareCode = prepare()
                if (prepareCode != 0) {
                    throw IOException(
                        "Native model prepare failed (code=$prepareCode). Try smaller context/model.",
                    )
                }

                readyForSystemPrompt = true
                cancelGeneration = false
                _state.value = InferenceEngine.State.ModelReady
            } catch (t: Throwable) {
                val e = if (t is Exception) t else RuntimeException(t.message ?: "Load failed", t)
                _state.value = InferenceEngine.State.Error(e)
                throw e
            }
        }

    override suspend fun setSystemPrompt(systemPrompt: String) =
        withContext(llamaDispatcher) {
            require(systemPrompt.isNotBlank()) { "Cannot process empty system prompt" }
            check(readyForSystemPrompt) { "System prompt must be set right after model load" }
            check(_state.value is InferenceEngine.State.ModelReady) {
                "Cannot process system prompt in ${_state.value.javaClass.simpleName}"
            }

            readyForSystemPrompt = false
            _state.value = InferenceEngine.State.ProcessingSystemPrompt
            processSystemPrompt(systemPrompt).let { result ->
                if (result != 0) {
                    RuntimeException("Failed to process system prompt: $result").also {
                        _state.value = InferenceEngine.State.Error(it)
                        throw it
                    }
                }
            }
            _state.value = InferenceEngine.State.ModelReady
        }

    override fun sendUserPrompt(message: String, predictLength: Int): Flow<String> =
        flow {
            require(message.isNotEmpty()) { "User prompt is empty" }
            check(_state.value is InferenceEngine.State.ModelReady) {
                "User prompt discarded due to: ${_state.value.javaClass.simpleName}"
            }

            try {
                cancelGeneration = false
                readyForSystemPrompt = false
                _state.value = InferenceEngine.State.ProcessingUserPrompt

                processUserPrompt(message, predictLength).let { result ->
                    if (result != 0) {
                        Log.e(TAG, "Failed to process user prompt: $result")
                        return@flow
                    }
                }

                _state.value = InferenceEngine.State.Generating
                while (!cancelGeneration) {
                    generateNextToken()?.let { utf8token ->
                        if (utf8token.isNotEmpty()) emit(utf8token)
                    } ?: break
                }

                _state.value = InferenceEngine.State.ModelReady
            } catch (e: CancellationException) {
                _state.value = InferenceEngine.State.ModelReady
                throw e
            } catch (e: Exception) {
                _state.value = InferenceEngine.State.Error(e)
                throw e
            }
        }.flowOn(llamaDispatcher)

    override suspend fun bench(pp: Int, tg: Int, pl: Int, nr: Int): String =
        withContext(llamaDispatcher) {
            check(_state.value is InferenceEngine.State.ModelReady) {
                "Benchmark request discarded due to: $state"
            }

            readyForSystemPrompt = false
            _state.value = InferenceEngine.State.Benchmarking
            benchModel(pp, tg, pl, nr).also {
                _state.value = InferenceEngine.State.ModelReady
            }
        }

    override fun cleanUp() {
        cancelGeneration = true
        runBlocking(llamaDispatcher) {
            when (val state = _state.value) {
                is InferenceEngine.State.ModelReady -> {
                    readyForSystemPrompt = false
                    _state.value = InferenceEngine.State.UnloadingModel
                    unload()
                    _state.value = InferenceEngine.State.Initialized
                }
                is InferenceEngine.State.Error -> {
                    _state.value = InferenceEngine.State.Initialized
                }
                is InferenceEngine.State.LoadingModel,
                is InferenceEngine.State.ProcessingSystemPrompt,
                is InferenceEngine.State.ProcessingUserPrompt,
                is InferenceEngine.State.Generating,
                is InferenceEngine.State.Benchmarking,
                is InferenceEngine.State.UnloadingModel,
                is InferenceEngine.State.Initializing -> {
                    // Force a recoverable state for the next load attempt.
                    readyForSystemPrompt = false
                    _state.value = InferenceEngine.State.Initialized
                }
                is InferenceEngine.State.Initialized,
                is InferenceEngine.State.Uninitialized -> {
                    // Nothing to clean.
                }
                else -> {
                    throw IllegalStateException("Cannot unload model in ${state.javaClass.simpleName}")
                }
            }
        }
    }

    // NEW FAST PATH: Generate complete response in ONE native call (no per-token overhead)
    // System prompt is processed separately before first generation, not in every call
    override suspend fun generateFastResponse(
        userPrompt: String,
        maxTokens: Int
    ): String = withContext(llamaDispatcher) {
        initReady.await()
        check(_state.value is InferenceEngine.State.ModelReady) {
            "Model not ready: ${_state.value.javaClass.simpleName}"
        }

        _state.value = InferenceEngine.State.Generating
        return@withContext try {
            val result = generateFullResponse("", userPrompt, maxTokens)
            Log.i(TAG, "Fast generation complete: ${result.length} chars")
            result
        } catch (e: Exception) {
            _state.value = InferenceEngine.State.Error(e)
            throw e
        } finally {
            if (_state.value is InferenceEngine.State.Generating) {
                _state.value = InferenceEngine.State.ModelReady
            }
        }
    }

    override fun stopGeneration() {
        cancelGeneration = true
        runCatching { requestStopGeneration() }
    }

    override fun destroy() {
        cancelGeneration = true
        runBlocking(llamaDispatcher) {
            readyForSystemPrompt = false
            when (_state.value) {
                is InferenceEngine.State.Uninitialized -> {}
                is InferenceEngine.State.Initialized -> shutdown()
                else -> {
                    unload()
                    shutdown()
                }
            }
        }
    }
}
