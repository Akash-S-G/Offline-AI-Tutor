# Phase 1 Integration Guide - Quick Start

## TL;DR - Getting Started

### Step 1: Configure Backend
```dart
// In your main.dart or app initialization
const backendConfig = BackendConfig(
  baseUrl: 'https://backend.example.com', // Set your backend URL
  apiKey: 'your-api-key-here',            // Set your API key
);
```

### Step 2: Initialize Services
```dart
// In MaterialApp or at app startup
final composer = DistributedServiceComposer();
await composer.initialize(
  backendConfig: backendConfig,
  platformGateway: getTutorInferenceGateway(), // Your existing gateway
);
```

### Step 3: Use in Chat
```dart
// Replace direct gateway calls with hybrid service
Stream<String> answers = composer.hybridInferenceService.streamAnswer(
  question: userInput,
  context: ragDocuments,      // Optional: pass RAG context
  systemPrompt: tutorPrompt,  // Optional: custom system prompt
);

await for (final chunk in answers) {
  setState(() => responseBuffer.write(chunk));
}
```

## Service Interfaces

### HybridInferenceService
```dart
class HybridInferenceService {
  /// Stream answers with automatic routing
  Stream<String> streamAnswer(
    String question, {
    String? context,
    String? systemPrompt,
    bool forceLocal = false,  // Force local-only inference
  });

  /// Get routing statistics
  Map<String, dynamic> getRoutingStats();

  /// Cleanup
  void close();
}
```

### NetworkStateService
```dart
class NetworkStateService {
  /// Stream connectivity snapshots
  Stream<ConnectivitySnapshot> get snapshots;
  
  /// Current quality: offline, online, slowBackend, moderateBackend, fastBackend
  NetworkQuality get quality;
  
  /// Current snapshot
  ConnectivitySnapshot? get currentSnapshot;
}
```

### BackendHealthMonitor
```dart
class BackendHealthMonitor {
  /// Stream health updates
  Stream<BackendHealthInfo> get healthUpdates;
  
  /// Current health: healthy, degraded, unavailable, unknown
  BackendHealthInfo get currentHealth;
}
```

## Accessing Services

```dart
final composer = DistributedServiceComposer();

// Access any service
final backendService = composer.backendService;
final networkState = composer.networkStateService;
final healthMonitor = composer.healthMonitor;
final hybridService = composer.hybridInferenceService;
```

## Common Patterns

### 1. Subscribe to Network Quality Changes
```dart
composer.networkStateService.snapshots.listen((snapshot) {
  print('Network: ${snapshot.isOnline}, Backend: ${snapshot.hasBackend}');
  // Update UI with network status
});
```

### 2. Monitor Backend Health
```dart
composer.healthMonitor.healthUpdates.listen((health) {
  if (health.status == BackendHealthStatus.unavailable) {
    // Show notification to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend temporarily unavailable')),
    );
  }
});
```

### 3. Force Local-Only Inference
```dart
// Use local model only (e.g., when offline)
Stream<String> localOnly = composer.hybridInferenceService.streamAnswer(
  question: question,
  forceLocal: true,  // Skip backend, use local only
);
```

### 4. Get Routing Decisions
```dart
final stats = composer.hybridInferenceService.getRoutingStats();
print('Cached responses: ${stats['cached_responses']}');
print('Network quality: ${stats['network_quality']}');
print('Local available: ${stats['local_available']}');
```

## Environment Configuration

### Using Environment Variables
```bash
# Set at build time
flutter run \
  --dart-define=BACKEND_BASE_URL=https://api.example.com \
  --dart-define=BACKEND_API_KEY=your-key
```

### Runtime Configuration
```dart
// Load from secure storage (recommended for production)
final apiKey = await _secureStorage.getApiKey();
final config = BackendConfig(
  baseUrl: 'https://api.example.com',
  apiKey: apiKey,
);
```

## Error Handling

### Graceful Degradation
```dart
try {
  await for (final chunk in composer.hybridInferenceService.streamAnswer(
    question: userQuestion,
  )) {
    responseBuffer.write(chunk);
  }
} catch (error) {
  // Automatically falls back to cache or local
  // User sees cached response if available
  showErrorMessage('Response quality degraded');
}
```

### Check Backend Availability
```dart
final health = composer.healthMonitor.currentHealth;
if (!health.isAvailable) {
  // Backend is down, use local model only
  useLocalOnly = true;
}
```

## Testing

### Mock Backend Configuration
```dart
const testConfig = BackendConfig(
  baseUrl: 'http://localhost:3000', // Local test server
  apiKey: 'test-key',
  connectTimeoutSeconds: 5,
  requestTimeoutSeconds: 10,
);
```

### Test with Simulated Network
```dart
// Force offline for testing
forceLocal = true;

// Or test specific routing
final decision = composer.inferenceRouter.route(
  'Complex question about physics',
  questionComplexity: 0.8,
  forceLocal: false,
);
// decision.route == InferenceRoute.backend (high complexity)
```

## Cleanup

### Shutdown Services
```dart
// On app exit or when no longer needed
composer.shutdown();
```

## Troubleshooting

### Services Not Initialized
**Error**: `Late initialization of 'backendService' hasn't been done yet`
**Fix**: Ensure `composer.initialize()` is called before using services

### Timeout Errors
**Issue**: Requests timing out
**Solution**: Increase timeouts in BackendConfig:
```dart
final config = BackendConfig(
  baseUrl: url,
  apiKey: key,
  connectTimeoutSeconds: 20,  // Increased from 10
  requestTimeoutSeconds: 60,   // Increased from 30
);
```

### Backend Not Reachable
**Issue**: Always falling back to local
**Solution**: Check backend URL and health:
```dart
final health = composer.healthMonitor.currentHealth;
if (!health.isAvailable) {
  print('Backend status: ${health.status}');
  print('Error: ${health.errorMessage}');
}
```

## Performance Tips

1. **Cache RAG Context**: Pass retrieved documents to reduce backend load
   ```dart
   final docs = await ragService.retrieve(question);
   await for (final chunk in composer.hybridInferenceService.streamAnswer(
     question: question,
     context: docs.join('\n'),
   )) { ... }
   ```

2. **Monitor Complexity**: Tune thresholds based on metrics
   ```dart
   final stats = composer.hybridInferenceService.getRoutingStats();
   // Adjust router threshold if backend is overused
   ```

3. **Batch Simple Queries**: Local model is faster for simple questions
   ```dart
   // Local inference: ~100-200ms for simple Q
   // Backend: ~2-5s (including network latency)
   ```

## Next Phase (Phase 2)

Phase 2 will add:
- Streaming UI improvements
- Stream cancellation handling
- Routing metrics tracking
- Performance profiling

For now, Phase 1 provides:
- ✅ Production-grade backend connectivity
- ✅ Network state management
- ✅ Health monitoring
- ✅ Intelligent routing
- ✅ Fallback handling
- ✅ Local model preserved

You're ready to integrate and test!
