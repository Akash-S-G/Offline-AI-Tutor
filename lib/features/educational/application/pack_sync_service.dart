import 'dart:async';
import 'dart:io';
import '../../../config/app_environment.dart';
import '../../../features/network/domain/endpoint_builder.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'pack_manager.dart';
import 'pack_installer.dart';

/// Synchronizes educational packs with the backend
/// 
/// Responsibilities:
/// - Check for available updates on backend
/// - Download new packs
/// - Update existing packs
/// - Handle sync failures and retries
/// - Track sync progress
class PackSyncService {
  final PackManager _packManager = PackManager();
  final EndpointBuilder _endpoints = EndpointBuilder.fromEnvironment();

  StreamController<SyncProgress>? _progressController;

  /// Stream of sync progress updates
  Stream<SyncProgress> get progressUpdates {
    _progressController ??= StreamController<SyncProgress>.broadcast();
    return _progressController!.stream;
  }

  /// Discover packs from both local storage and backend catalog
  Future<List<EducationalPackModel>> discoverPacks() async {
    try {
      AppEnvironment.log('SYNC', 'Starting pack discovery...');

      // Get local packs
      final localPacks = await _packManager.discoverAvailablePacks();
      
      // Register discovered packs
      for (final pack in localPacks) {
        final existing = await EducationalRepository.getPackByPackId(pack.packId);
        if (existing == null) {
          await _packManager.registerPack(pack);
          AppEnvironment.log('SYNC', 'Registered discovered pack: ${pack.packId}');
        }
      }

      // Try to fetch remote catalog from backend
      final remotePacks = await _fetchRemotePacks();
      
      AppEnvironment.log('SYNC', 'Pack discovery complete: ${localPacks.length} local, ${remotePacks.length} remote');
      
      return [...localPacks, ...remotePacks];
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error discovering packs: $e');
      return [];
    }
  }

  /// Fetch pack catalog from backend
  Future<List<EducationalPackModel>> _fetchRemotePacks() async {
    try {
      AppEnvironment.log('SYNC', 'Fetching remote pack catalog...');
      
      if (!AppEnvironment.enableBackend) {
        AppEnvironment.log('SYNC', 'Backend disabled, skipping remote fetch');
        return [];
      }

      // TODO: Implement HTTP request to fetch pack catalog from backend
      // For now, return empty list
      return [];
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error fetching remote packs: $e');
      return [];
    }
  }

  /// Sync a specific pack
  /// 
  /// Downloads if not available, updates if newer version exists
  Future<bool> syncPack(String packId) async {
    try {
      AppEnvironment.log('SYNC', 'Syncing pack: $packId');
      
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack == null) {
        AppEnvironment.log('SYNC', 'Pack not found: $packId');
        return false;
      }

      // Mark as pending
      await _packManager.queuePackForSync(packId);
      _emitProgress(packId, 0.0, 'Starting sync...');

      // Download if needed
      if (!pack.isOfflineAvailable) {
        final success = await _downloadPack(pack);
        if (!success) {
          AppEnvironment.log('SYNC', 'Failed to download pack: $packId');
          return false;
        }
      }

      // Mark as available offline
      await _packManager.markPackOfflineAvailable(packId);
      _emitProgress(packId, 1.0, 'Sync complete');

      AppEnvironment.log('SYNC', 'Pack synced successfully: $packId');
      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error syncing pack: $e');
      return false;
    }
  }

  /// Sync all available packs
  Future<void> syncAllPacks() async {
    try {
      AppEnvironment.log('SYNC', 'Starting full pack sync...');
      
      final packs = await _packManager.getAllPacks();
      int successCount = 0;

      for (final pack in packs) {
        if (!pack.isOfflineAvailable) {
          final success = await syncPack(pack.packId);
          if (success) successCount++;
        }
      }

      AppEnvironment.log('SYNC', 'Full sync complete: $successCount/${packs.length} packs synced');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error in full pack sync: $e');
    }
  }

  /// Sync packs for a specific grade
  Future<void> syncGradePacks(int gradeId) async {
    try {
      AppEnvironment.log('SYNC', 'Syncing packs for grade: $gradeId');
      
      final packs = await _packManager.getPacksForGrade(gradeId);
      
      for (final pack in packs) {
        if (!pack.isOfflineAvailable) {
          await syncPack(pack.packId);
        }
      }

      AppEnvironment.log('SYNC', 'Grade pack sync complete: $gradeId');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error syncing grade packs: $e');
    }
  }

  /// Download a pack from backend
  Future<bool> _downloadPack(EducationalPackModel pack) async {
    try {
      AppEnvironment.log('SYNC', 'Downloading pack: ${pack.name}');

      // TODO: Implement actual download from backend using:
      // - _endpoints.packsDownload
      // - HTTP GET request with stream
      // - Save to pack.localPath
      // - Call _packManager.updatePackProgress() for progress tracking

      // For now, simulate installation from local source
      return await _installPackFromLocal(pack);
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error downloading pack: $e');
      return false;
    }
  }

  /// Install pack from local textbooks directory
  Future<bool> _installPackFromLocal(EducationalPackModel pack) async {
    try {
      // Find source directory in textbooks
      final sourcePath = '/home/akash/Desktop/IDP/TEXTBOOKS/${pack.name}';
      final sourceDir = Directory(sourcePath);

      if (!await sourceDir.exists()) {
        AppEnvironment.log('SYNC', 'Local pack directory not found: $sourcePath');
        return false;
      }

      // Create installer
      final installer = PackInstaller(
        packId: pack.packId,
        sourcePath: sourcePath,
        targetPath: pack.localPath,
      );

      // Install with progress tracking
      final success = await installer.install(
        onProgress: (progress) {
          _emitProgress(pack.packId, progress, 'Installing...');
          _packManager.updatePackProgress(pack.packId, progress: progress, downloadedChapters: 0);
        },
      );

      if (success) {
        // Validate after installation
        final validated = await installer.validatePackIntegrity();
        if (!validated) {
          AppEnvironment.log('SYNC', 'Pack validation failed: ${pack.packId}');
          return false;
        }
      }

      return success;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error installing local pack: $e');
      return false;
    }
  }

  /// Check for updates for all packs
  Future<Map<String, String?>> checkForUpdates() async {
    try {
      AppEnvironment.log('SYNC', 'Checking for pack updates...');
      
      final updates = <String, String?>{};
      final packs = await _packManager.getAllPacks();

      for (final pack in packs) {
        final latestVersion = await _getRemotePackVersion(pack.packId);
        if (latestVersion != null && latestVersion != pack.version) {
          updates[pack.packId] = latestVersion;
        }
      }

      AppEnvironment.log('SYNC', 'Update check complete: ${updates.length} updates available');
      return updates;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error checking for updates: $e');
      return {};
    }
  }

  /// Get remote version of a pack
  Future<String?> _getRemotePackVersion(String packId) async {
    try {
      // TODO: Implement HTTP request to get pack version from backend
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a pack and free storage
  Future<bool> deletePack(String packId) async {
    try {
      AppEnvironment.log('SYNC', 'Deleting pack: $packId');
      await _packManager.deletePack(packId);
      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error deleting pack: $e');
      return false;
    }
  }

  /// Get sync status for a pack
  Future<SyncStatus> getPackSyncStatus(String packId) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack == null) {
        return SyncStatus(
          packId: packId,
          state: 'not_found',
          progress: 0.0,
          message: 'Pack not found',
        );
      }

      return SyncStatus(
        packId: packId,
        state: pack.syncState,
        progress: pack.downloadProgress,
        message: pack.isOfflineAvailable ? 'Available offline' : 'Not downloaded',
      );
    } catch (e) {
      return SyncStatus(
        packId: packId,
        state: 'error',
        progress: 0.0,
        message: 'Error: $e',
      );
    }
  }

  /// Emit progress update
  void _emitProgress(String packId, double progress, String message) {
    _progressController?.add(
      SyncProgress(
        packId: packId,
        progress: progress,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Close sync service
  Future<void> close() async {
    await _progressController?.close();
    _progressController = null;
  }
}

/// Sync progress information
class SyncProgress {
  final String packId;
  final double progress; // 0.0 to 1.0
  final String message;
  final DateTime timestamp;

  SyncProgress({
    required this.packId,
    required this.progress,
    required this.message,
    required this.timestamp,
  });
}

/// Sync status information
class SyncStatus {
  final String packId;
  final String state; // 'discovered', 'pending', 'downloading', 'synced', 'failed', 'not_found', 'error'
  final double progress;
  final String message;

  SyncStatus({
    required this.packId,
    required this.state,
    required this.progress,
    required this.message,
  });
}
