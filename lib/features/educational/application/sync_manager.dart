import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../../../config/app_environment.dart';
import '../../../features/network/data/backend_availability_cache.dart';
import '../../../features/network/domain/endpoint_builder.dart';
import '../models/educational_models.dart';

/// Pack synchronization with backend PiHub
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() {
    return _instance;
  }

  SyncManager._internal();

  /// Check for pack updates from backend
  Future<Map<String, String>> checkForPackUpdates() async {
    try {
      // Consult cached backend status to avoid redundant 30s timeout
      final cached = BackendAvailabilityCache().cachedStatus;
      if (cached == false) {
        AppEnvironment.log('SYNC', '[SyncManager] Skipping pack check — backend cached as unavailable');
        return {};
      }

      AppEnvironment.log('SYNC', '[SyncManager] Checking for pack updates');

      final endpoint = EndpointBuilder.fromEnvironment().packsSync;
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updates = <String, String>{};

        if (data['packages'] is List) {
          for (final pkg in data['packages']) {
            updates[pkg['packId']] = pkg['version'];
          }
        }

        AppEnvironment.log('SYNC', '[SyncManager] Found ${updates.length} pack updates');
        return updates;
      } else {
        AppEnvironment.log(
          'SYNC',
          '[SyncManager] Update check failed: ${response.statusCode}',
        );
        return {};
      }
    } catch (e) {
      AppEnvironment.log('SYNC', '[SyncManager] Error checking updates: $e');
      return {};
    }
  }

  /// Sync specific pack with backend
  Future<bool> syncPackWithBackend(String packId, String localVersion) async {
    try {
      AppEnvironment.log('SYNC', '[SyncManager] Syncing pack: $packId');

      final endpoint = '${EndpointBuilder.fromEnvironment().packsSync}/$packId';

      final delta = {
        'action': 'sync',
        'packId': packId,
        'localVersion': localVersion,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(delta),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppEnvironment.log('SYNC', '[SyncManager] Pack sync complete: $packId');
        return true;
      } else {
        AppEnvironment.log('SYNC', '[SyncManager] Pack sync failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppEnvironment.log('SYNC', '[SyncManager] Error syncing pack: $e');
      return false;
    }
  }

  /// Fetch delta updates for efficient sync
  Future<Map<String, dynamic>?> fetchDeltaUpdates(
    String packId,
    String fromVersion,
  ) async {
    try {
      AppEnvironment.log(
        'SYNC',
        '[SyncManager] Fetching delta updates: $packId from $fromVersion',
      );

      final endpoint = '${EndpointBuilder.fromEnvironment().syncDelta}/$packId';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-From-Version': fromVersion,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      AppEnvironment.log('SYNC', '[SyncManager] Error fetching deltas: $e');
      return null;
    }
  }

  /// Sync learner progress to backend
  Future<bool> syncLearnerProgress(int chapterId, Map<String, dynamic> progress) async {
    try {
      final endpoint = EndpointBuilder.fromEnvironment().progressUpdate;

      final payload = {
        'chapterId': chapterId,
        'progress': progress,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppEnvironment.log('SYNC', '[SyncManager] Error syncing progress: $e');
      return false;
    }
  }

  /// Validate cache integrity against backend
  Future<bool> validateCacheIntegrity(String packId) async {
    try {
      final endpoint = '${EndpointBuilder.fromEnvironment().packsSync}/$packId/validate';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isValid = data['valid'] == true;

        if (!isValid) {
          AppEnvironment.log(
            'SYNC',
            '[SyncManager] Cache validation failed for $packId',
          );
        }

        return isValid;
      }

      return false;
    } catch (e) {
      AppEnvironment.log('SYNC', '[SyncManager] Error validating cache: $e');
      return false;
    }
  }
}

/// Conflict resolution for concurrent updates
class ConflictResolver {
  /// Resolve conflicts between local and remote versions
  /// Strategy: Last-write-wins with timestamp comparison
  static EducationalPackModel resolvePackConflict(
    EducationalPackModel local,
    EducationalPackModel remote,
  ) {
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      AppEnvironment.log('SYNC', '[ConflictResolver] Remote version newer for ${local.packId}');
      return remote;
    }

    AppEnvironment.log('SYNC', '[ConflictResolver] Local version retained for ${local.packId}');
    return local;
  }

  /// Resolve conflicts between local and remote progress
  static LearnerProgressModel resolveProgressConflict(
    LearnerProgressModel local,
    LearnerProgressModel remote,
  ) {
    // Merge conflicting progress (take best scores and furthest progress)
    final localAttempts = local.quizAttempts ?? 0;
    final remoteAttempts = remote.quizAttempts ?? 0;
    final localBestScore = local.quizBestScore ?? 0;
    final remoteBestScore = remote.quizBestScore ?? 0;
    final localFlashcards = local.flashcardsReviewed ?? 0;
    final remoteFlashcards = remote.flashcardsReviewed ?? 0;

    final localLastAccessed = local.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remoteLastAccessed = remote.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    return LearnerProgressModel(
      id: local.id,
      chapterId: local.chapterId,
      completionState: _mergeCompletionState(local.completionState, remote.completionState),
      readingProgressPercent: math.max(
        local.readingProgressPercent,
        remote.readingProgressPercent,
      ),
      quizAttempts: localAttempts + remoteAttempts,
      quizBestScore: math.max(localBestScore, remoteBestScore),
      flashcardsReviewed: localFlashcards + remoteFlashcards,
        lastAccessedAt: localLastAccessed.isAfter(remoteLastAccessed)
          ? localLastAccessed
          : remoteLastAccessed,
      completedAt: local.completionState == 'completed' ? local.completedAt : null,
      createdAt: local.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String _mergeCompletionState(String local, String remote) {
    const priority = {
      'completed': 3,
      'in-progress': 2,
      'not-started': 1,
    };

    final localPriority = priority[local] ?? 0;
    final remotePriority = priority[remote] ?? 0;

    return remotePriority >= localPriority ? remote : local;
  }
}

/// Bandwidth optimizer for sync operations
class BandwidthOptimizer {
  /// Check available bandwidth
  static Future<bool> hasAdequateBandwidth() async {
    // TODO: Implement actual bandwidth detection
    // For now, assume adequate if connected
    return true;
  }

  /// Calculate optimal chunk size for large pack downloads
  static int calculateOptimalChunkSize({
    required int totalSize,
    required int availableBandwidth, // Kbps
  }) {
    // Target ~30 second chunks
    const targetDurationSeconds = 30;
    final bandwidthBytesPerSecond = (availableBandwidth * 1024) ~/ 8;
    final chunkSize = bandwidthBytesPerSecond * targetDurationSeconds;

    // Clamp between 256KB and 10MB
    return chunkSize.clamp(256 * 1024, 10 * 1024 * 1024);
  }

  /// Compress data for efficient transfer
  static String compressPayload(Map<String, dynamic> payload) {
    return jsonEncode(payload); // TODO: Add gzip compression
  }

  /// Decompress received data
  static Map<String, dynamic> decompressPayload(String compressed) {
    return jsonDecode(compressed); // TODO: Add gzip decompression
  }
}

/// Sync queue for managing sync operations
class SyncQueue {
  final List<SyncOperation> _queue = [];
  bool _isProcessing = false;

  /// Add operation to queue
  void enqueue(SyncOperation operation) {
    _queue.add(operation);
    _processQueue();
  }

  /// Process sync queue
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final operation = _queue.removeAt(0);
      try {
        await operation.execute();
        AppEnvironment.log('SYNC', '[SyncQueue] Completed: ${operation.id}');
      } catch (e) {
        AppEnvironment.log('SYNC', '[SyncQueue] Failed: ${operation.id} - $e');
        // Optionally requeue on failure
      }
    }

    _isProcessing = false;
  }

  /// Get queue status
  Map<String, dynamic> getStatus() {
    return {
      'queueSize': _queue.length,
      'isProcessing': _isProcessing,
      'nextOperation': _queue.isNotEmpty ? _queue.first.id : null,
    };
  }
}

/// Base sync operation
abstract class SyncOperation {
  String get id;
  Future<void> execute();
  SyncOperation withRetry({int maxAttempts = 3});
}

/// Pack download sync operation
class PackDownloadOperation implements SyncOperation {
  @override
  final String id;
  final String packId;
  final String remoteUrl;
  final String localPath;

  PackDownloadOperation({
    required this.id,
    required this.packId,
    required this.remoteUrl,
    required this.localPath,
  });

  @override
  Future<void> execute() async {
    AppEnvironment.log('SYNC', '[PackDownloadOp] Starting download: $packId');
    // TODO: Implement actual download with progress
  }

  @override
  SyncOperation withRetry({int maxAttempts = 3}) {
    // Wrap with retry logic
    return this;
  }
}

/// Progress upload sync operation
class ProgressUploadOperation implements SyncOperation {
  @override
  final String id;
  final int chapterId;
  final Map<String, dynamic> progressData;

  ProgressUploadOperation({
    required this.id,
    required this.chapterId,
    required this.progressData,
  });

  @override
  Future<void> execute() async {
    AppEnvironment.log('SYNC', '[ProgressUploadOp] Uploading progress: $chapterId');
    await SyncManager().syncLearnerProgress(chapterId, progressData);
  }

  @override
  SyncOperation withRetry({int maxAttempts = 3}) {
    return this;
  }
}
