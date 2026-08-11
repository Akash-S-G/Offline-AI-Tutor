# Recovered Source Knowledge Reference

Consolidated knowledge recovered from truncated Kotlin sources during prior recovery reads.
Used as a quick-access reference for architecture, JNI bindings, P2P flows, and Android method channels.

---

## 1. InferenceEngine Interface

File: `android/app/src/main/kotlin/com/arm/aichat/internal/` (package `com.arm.aichat.internal`)

```kotlin
interface InferenceEngine {
    val state: StateFlow<InferenceEngine.State>
    suspend fun loadModel(modelPath: String)
    suspend fun setSystemPrompt(systemPrompt: String)
    suspend fun sendUserPrompt(userPrompt: String, predictLength: ...): Flow<String>
    suspend fun generateFastResponse(userPrompt: String, maxTokens: Int): String
    suspend fun bench(pp: Int, tg: Int, pl: Int, nr: Int): String
    fun cleanUp()
    fun stopGeneration()
    fun destroy()
}
```

- `DEFAULT_PREDICT_LENGTH = 1024`

### States (nested `InferenceEngine.State`)
- `Uninitialized`, `Initializing`, `Initialized`, `LoadingModel`, `ModelReady`,
  `ProcessingSystemPrompt`, `ProcessingUserPrompt`, `Generating`, `Benchmarking`,
  `UnloadingModel`, `Error` (holds exception).

---

## 2. InferenceEngineImpl (322 lines — fully recovered)

Path: `android/app/src/main/kotlin/com/arm/aichat/internal/InferenceEngineImpl.kt`

```kotlin
internal class InferenceEngineImpl private constructor(
    private val nativeLibDir: String
) : InferenceEngine {

    companion object {
        fun getInstance(context: Context): InferenceEngineImpl {
            return InferenceEngineImpl(context.applicationInfo.nativeLibraryDir)
        }
    }
}
```

### Native externals (declared)
- `nativeInit()`
- `nativeLoad(path)`
- `nativePrepare(systemPrompt)` / `prepare`
- `systemInfo()`
- `benchModel(pp, tg, pl, nr)`
- `processUserPrompt(message, predictLength)`
- `generateNextToken()`
- `requestStopGeneration()`
- `unload()` / `shutdown()`

> Recovery note: `@FastNative` external declarations surface multiple variants;
> exact method names for `init`/`load`/`unload`/`shutdown` are `init`, `load`,
> `prepare`, `systemInfo`, `benchModel`, `processUserPrompt`, `generateNextToken`,
> `requestStopGeneration`, `unload`, `shutdown`.

### State machine
- `_state: MutableStateFlow<InferenceEngine.State>` exposed as `state: StateFlow`.
- `readyForSystemPrompt: Boolean` — system prompt processed separately once, not per call.
- `cancelGeneration: Boolean` — external stop flag checked inside the generate loop.
- `initReady: CountDownLatch` / `llamaDispatcher` backing all native work via
  `withContext(llamaDispatcher)` / `runBlocking(llamaDispatcher)`.

### `sendUserPrompt` flow
```kotlin
override suspend fun sendUserPrompt(message, predictLength): Flow<String> = flow {
    initReady.await()
    check(_state.value is InferenceEngine.State.ModelReady) { "Model not ready: ..." }
    if (!readyForSystemPrompt) { ... process system prompt ... }

    val result = processUserPrompt(message, predictLength)
    if (result != 0) {
        Log.e(TAG, "[Engine] processUserPrompt FAILED result=$result")
        return@flow
    }

    _state.value = InferenceEngine.State.Generating
    Log.i(TAG, "[Engine] MODEL_GENERATE_START")
    println("[Engine] [TRACE] MODEL_GENERATE_START")

    while (!cancelGeneration) {
        val utf8token = generateNextToken()?.takeIf { it.isNotEmpty() }
        if (utf8token != null) emit(utf8token) else break
    }

    println("[Engine] [TRACE] MODEL_GENERATE_END")
    Log.i(TAG, "[Engine] MODEL_GENERATE_END")
    _state.value = InferenceEngine.State.ModelReady
}.catch { e ->
    when (e) {
        is CancellationException -> { _state.value = InferenceEngine.State.ModelReady; throw e }
        else -> { _state.value = InferenceEngine.State.Error(e); throw e }
    }
}.flowOn(llamaDispatcher)
```

### `generateFastResponse` (fast path — single native call)
```kotlin
override suspend fun generateFastResponse(userPrompt: String, maxTokens: Int): String =
    withContext(llamaDispatcher) {
        initReady.await()
        check(_state.value is InferenceEngine.State.ModelReady) { "Model not ready: ..." }
        _state.value = InferenceEngine.State.Generating
        try {
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
```

### `bench`
```kotlin
override suspend fun bench(pp: Int, tg: Int, pl: Int, nr: Int): String =
    withContext(llamaDispatcher) {
        check(_state.value is InferenceEngine.State.ModelReady) {
            "Benchmark request discarded due to: $state"
        }
        readyForSystemPrompt = false
        _state.value = InferenceEngine.State.Benchmarking
        benchModel(pp, tg, pl, nr).also { _state.value = InferenceEngine.State.ModelReady }
    }
```

### unload / destroy
- `cleanUp()`: sets `cancelGeneration = true`; in `runBlocking(llamaDispatcher)`:
  - `ModelReady` → `readyForSystemPrompt=false`, `UnloadingModel`, `unload()`, `Initialized`
  - `Error` → `Initialized`
  - blocks states (`LoadingModel`, `ProcessingSystemPrompt/UserPrompt`, `Generating`,
    `Benchmarking`, `UnloadingModel`, `Initializing`) → force `Initialized`
  - `Initialized`/`Uninitialized` → nothing
  - `else` → `throw IllegalStateException("Cannot unload model in ${state.javaClass.simpleName}")`

```kotlin
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
            else -> { unload(); shutdown() }
        }
    }
}
```

---

## 3. LlamaEngine (881 lines — fully recovered)

Path: `android/app/src/main/kotlin/com/example/offline_tutor_app/LlamaEngine.kt`

### Model metadata
- Model: **phi-2** (~1.66 GB), `ACTIVE_MODEL = "phi-2"`
- `CHAT_TEMPLATE = ChatML/Phi-2`

### Key methods
- `askStreamFast(...)` — streaming ask using `generateFastResponse`-style path
- `isRunawayRepetition(text)`: regex `(?:\\n\\s*(a|b):\\s*){3,}`; skipped when length < 80
- Model lifetime helpers:
  - `prepareModelForNativeLoad()` — copies model file via `copyFile`)
  - `validateModelFile(path)` — GGUF magic + ≥ 1 MB check
  - `ensureModelLoadedWithRecovery()` — retries when `IllegalStateException`
    message contains `"Cannot load model in"`
  - `copyFile(src, dst, onProgress)` — 1 MB buffer, reports integer percent
- `runPerformanceProbe()` — runs `bench(pp, tg, pl, nr)`
- `close()` — releases LlamaEngine/InferenceEngine resources
- Field `inferenceEngine: InferenceEngine` created via `AiChat.getInferenceEngine(context)`

### Display-truncated gaps (content read, output truncated)
- ~723–734: `close()` tail
- ~788–794: `copyFile` progress loop
- ~843–855: `prepareModelForNativeLoad` copy invocation

---

## 4. MainActivity (477 lines — fully recovered)

Path: `android/app/src/main/kotlin/com/example/offline_tutor_app/MainActivity.kt`

### Method channels
- `offline_tutor/llm_stream` — streaming tokens
- `offline_tutor/llm_metrics` — performance telemetry

### LLM stream flush policy
- Flush `llm_stream` on `'\n'`, ≥ 64 chars, or ≥ 30 ms

### Failure detection
- Message matches `startsWith("Failed to") || startsWith("Model cannot")`
  → mapped to `"LLM_FAILURE"`

### Method call handlers
- `stopGeneration`, `getGenerationConfig`, `updateGenerationConfig`, `resetEngine`,
  `runPerformanceProbe`, `getEngineStatus`, `preloadModel`, `runEngineSelfTest`,
  `getModelPath`, `getEngineMetadata`, `setModelPath`

### Engine bootstrap
- `AiChat.getInferenceEngine(context)` → `InferenceEngineImpl.getInstance(context)`
- Scoped to Activity; engine cleaned in `onDestroy`

---

## 5. P2PManager (854 lines — fully recovered)

Path: `android/app/src/main/kotlin/com/example/offline_tutor_app/P2PManager.kt`

### Discovery constants
- `DISCOVERY_PROBE`, `DISCOVERY_REPLY_PREFIX` (`"$DISCOVERY_REPLY_PREFIX:"` framed packets)
- `UDP_PORT` for broadcast probes (DatagramSocket)
- `TCP_PORT` for ServerSocket transfers
- `RECEIVE_APPROVAL_TIMEOUT_MS` — incoming transfer approval latch timeout
- WiFi Direct: `WifiP2pManager`, `requestPeers` fired after `900L`, `CountDownLatch(1)`,
  `addWifiDirectPeer(...)`

### startReceiver()
```kotlin
receiverRunning = true
thread(isDaemon = true, name = "p2p-discovery-responder") { runDiscoveryResponderLoop() }
receiverThread = thread { 
    val serverSocket = ServerSocket(TCP_PORT)
    while (...) { val socket = serverSocket.accept(); receiveBundle(socket); socket.closeInFinallyO }
}
```

- Discovery failure → `activeTransport = "wifi-direct-discovery"`, `lastRouteDecision = "WIFI_DIRECT_FALLBACK"`
- Else → `"wifi-lan-tcp"`, `lastRouteDecision = "NONE"`; peers stored in `lastDiscoveredPeers`

### Incoming bundle approval flow
- `pending = IncomingTransfer(...)`: `sanitizeFileName(fileName)`, `sizeBytes`, `createdAt = now`
- Sets `receiveTelemetry = TransferTelemetry(direction="receive", stage="awaiting-approval",
  peerAddress=pending.senderAddress, fileName=pending.fileName, totalBytes=size,
  transferredBytes=0L, startedAtMs=now, updatedAtMs=now, done=false, success=false, errorMessage="")`
- `pendingIncomingTransfers[pending.id] = pending`
- `pending.decisionLatch.await(RECEIVE_APPROVAL_TIMEOUT_MS, TimeUnit.MILLISECONDS)`
- `finally { pendingIncomingTransfers.remove(pending.id) }`
- Rejected/timeout → `lastTransferError = "Incoming transfer rejected or timed out: ${pending.fileName}"`,
  telemetry `copy(stage="rejected", done=true, success=false)`,
  `throw IllegalStateException("Incoming transfer not approved")`
- Approved → `receiveTelemetry.copy(...)`

### Peer resolution & discovery
- `resolvePeerIpFromArp(targetMac)`: parses `/proc/net/arp`, skips header + rows < 4 cols,
  `cols[0]=ip`, `cols[3]=mac` (lowercased); returns ip only if `mac == normalizedMac && isIpv4Address(ip)`;
  wrapped in `runCatching { }.getOrNull()`
- `hasWifiDirectRuntimePermissions()`: `ACCESS_FINE_LOCATION` and (SDK ≥ 33/TIRAMISU)
  `NEARBY_WIFI_DEVICES` both `PERMISSION_GRANTED`

### `discoverPeersOnLan()` (starts line 737)
```kotlin
val localIp = getLocalIpv4Address() ?: return emptyList()
val socket = DatagramSocket().apply {
    broadcast = true
    soTimeout = 800
}
try {
    val probeBytes = DISCOVERY_PROBE.toByteArray()
    for (addr in getBroadcastAddresses()) {
        DatagramPacket(probeBytes, probeBytes.size, addr, UDP_PORT).let { runCatching { socket.send(it) } }
    }
    val endAt = System.currentTimeMillis() + 1200
    while (System.currentTimeMillis() < endAt) {
        try {
            val packet = DatagramPacket(ByteArray(512), 512)
            socket.receive(packet)
            val text = String(packet.data, 0, packet.length)
            if (!text.startsWith("$DISCOVERY_REPLY_PREFIX:")) continue
            val parts = text.split(':')
            if (parts.size < 4) continue
            val name = parts[1]; val ip = parts[2]
            if (ip == localIp) continue
            results[ip] = mapOf("name" to name, "address" to ip, "transport" to "wifi-lan")
        } catch (_: SocketTimeoutException) { break }
    }
} catch (e: Throwable) {
    lastTransferError = e.message ?: "Peer discovery failed"
} finally {
    runCatching { socket.close() }
}
return results.values.toList().sortedBy { it["name"] }
```

### Network helpers
- `inboxDir()`: `File(context.filesDir, "p2p_inbox")`, mkdirs on demand
- `sanitizeFileName(name)`: `name.replace(Regex("[^a-zA-Z0-9._-]"), "_")`
- `isIpv4Address(value)`: 4 dot-parts, each `0..255`
- `getLocalIpv4Address()`: first up, non-loopback, non-IPv6 interface addr
- `getBroadcastAddresses()`: interface `broadcast` addresses; default `255.255.255.255`

---

## 6. Dart App Context (`lib/`)
- Display: **OfflineTutorApp** 0.1.0+1; API/SDK `^3.11.1`
- Engine: `AiChat.getInferenceEngine(context)` → `InferenceEngineImpl.getInstance(context)`
- `OfflineTutorService` singleton = `RetrievalRouter` + `LocalSearchService`

## 7. Workspace Layout (root)
- `android/` — Kotlin engine + Activity
- `assets/`, `lib/` (Dart app), `test/`, `tools/`, `scene_kits/`, `docs/` + audit dirs