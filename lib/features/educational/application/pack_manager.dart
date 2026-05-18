import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../config/app_environment.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';

/// Manages the lifecycle of educational packs
/// 
/// Responsibilities:
/// - Discover packs from local storage and IDP/textbooks/
/// - Track pack metadata and sync state
/// - Install/uninstall packs
/// - Version management
class PackManager {
  static final PackManager _instance = PackManager._internal();

  factory PackManager() {
    return _instance;
  }

  PackManager._internal();

  /// Get local application documents directory for pack storage
  Future<Directory> _getPackStorageDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final packsDir = Directory(path.join(dir.path, 'educational_packs'));
    if (!await packsDir.exists()) {
      await packsDir.create(recursive: true);
    }
    return packsDir;
  }

  /// Discover all available educational packs from textbooks directory
  /// 
  /// Scans IDP/textbooks/ and generates pack identifiers from chapter names
  /// Example: "Nutrition in Plants" → "nutrition_in_plants"
  Future<List<EducationalPackModel>> discoverAvailablePacks() async {
    AppEnvironment.log('SYNC', 'Discovering educational packs...');
    
    try {
      final textbooksDir = Directory('/home/akash/Desktop/IDP/TEXTBOOKS');
      
      if (!await textbooksDir.exists()) {
        AppEnvironment.log('SYNC', 'Textbooks directory not found');
        return [];
      }

      final packs = <EducationalPackModel>[];
      final storageDir = await _getPackStorageDirectory();

      // Scan subdirectories for content (e.g., "maths 1 to 10", "science 5-10")
      final entities = textbooksDir.listSync();
      
      for (final entity in entities) {
        if (entity is Directory && !entity.path.startsWith('.')) {
          // Generate pack ID from directory name
          final dirName = path.basename(entity.path);
          final packId = _generatePackId(dirName);
          
          // Check if already in database
          final existing = await EducationalRepository.getPackByPackId(packId);
          
          if (existing == null) {
            final pack = EducationalPackModel(
              packId: packId,
              name: dirName,
              description: 'Educational content from $dirName',
              version: '1.0.0',
              localPath: path.join(storageDir.path, packId),
              syncState: 'discovered',
              isOfflineAvailable: false,
            );
            packs.add(pack);
            AppEnvironment.log('SYNC', 'Discovered pack: $packId');
          }
        }
      }

      AppEnvironment.log('SYNC', 'Pack discovery complete: ${packs.length} packs found');
      return packs;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error discovering packs: $e');
      return [];
    }
  }

  /// Register a discovered pack in the database
  Future<int> registerPack(EducationalPackModel pack) async {
    try {
      final id = await EducationalRepository.insertPack(pack);
      AppEnvironment.log('SYNC', 'Pack registered: ${pack.name} (id: $id)');
      return id;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error registering pack: $e');
      rethrow;
    }
  }

  /// Get all registered packs
  Future<List<EducationalPackModel>> getAllPacks() async {
    try {
      return await EducationalRepository.getAllPacks();
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error fetching packs: $e');
      return [];
    }
  }

  /// Get packs for a specific grade
  Future<List<EducationalPackModel>> getPacksForGrade(int gradeId) async {
    try {
      return await EducationalRepository.getPacksByGradeId(gradeId);
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error fetching grade packs: $e');
      return [];
    }
  }

  /// Mark a pack for download/sync
  Future<void> queuePackForSync(String packId) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack != null) {
        final updated = pack.copyWith(syncState: 'pending');
        await EducationalRepository.updatePack(updated);
        AppEnvironment.log('SYNC', 'Pack queued for sync: $packId');
      }
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error queueing pack: $e');
      rethrow;
    }
  }

  /// Update pack sync progress
  Future<void> updatePackProgress(
    String packId, {
    required double progress,
    required int downloadedChapters,
  }) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack != null) {
        final updated = pack.copyWith(
          downloadProgress: progress,
          downloadedChapters: downloadedChapters,
        );
        await EducationalRepository.updatePack(updated);
      }
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error updating pack progress: $e');
    }
  }

  /// Mark pack as available offline
  Future<void> markPackOfflineAvailable(String packId) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack != null) {
        final updated = pack.copyWith(
          isOfflineAvailable: true,
          syncState: 'synced',
          lastSyncedAt: DateTime.now(),
          downloadProgress: 1.0,
        );
        await EducationalRepository.updatePack(updated);
        AppEnvironment.log('SYNC', 'Pack marked offline available: $packId');
      }
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error marking pack offline available: $e');
      rethrow;
    }
  }

  /// Get pack installation status
  Future<PackInstallationStatus> getPackStatus(String packId) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack == null) {
        return PackInstallationStatus.notFound;
      }
      
      if (pack.isOfflineAvailable) {
        return PackInstallationStatus.installed;
      }
      
      if (pack.syncState == 'pending') {
        return PackInstallationStatus.downloading;
      }
      
      if (pack.syncState == 'failed') {
        return PackInstallationStatus.failed;
      }
      
      return PackInstallationStatus.discovered;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error getting pack status: $e');
      return PackInstallationStatus.error;
    }
  }

  /// Delete a pack and free storage
  Future<void> deletePack(String packId) async {
    try {
      final pack = await EducationalRepository.getPackByPackId(packId);
      if (pack != null) {
        final packDir = Directory(pack.localPath);
        if (await packDir.exists()) {
          await packDir.delete(recursive: true);
          AppEnvironment.log('SYNC', 'Pack directory deleted: $packId');
        }
        // TODO: Delete from database when delete method is added to repository
      }
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error deleting pack: $e');
      rethrow;
    }
  }

  /// Generate pack ID from human-readable name
  /// Example: "Nutrition in Plants" → "nutrition_in_plants"
  /// "10th Kan Maths Part - 2" → "10th_kan_maths_part_2"
  static String _generatePackId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars except - and _
        .trim()
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(RegExp(r'_+'), '_') // Collapse multiple underscores
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
  }

  /// Extension method for convenient copyWith pattern
}

extension on EducationalPackModel {
  EducationalPackModel copyWith({
    int? id,
    String? packId,
    String? name,
    String? description,
    String? version,
    String? localPath,
    String? syncState,
    double? downloadProgress,
    int? gradeId,
    int? subjectId,
    int? totalChapters,
    int? downloadedChapters,
    DateTime? lastSyncedAt,
    DateTime? nextSyncDueAt,
    bool? isOfflineAvailable,
  }) {
    return EducationalPackModel(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      localPath: localPath ?? this.localPath,
      syncState: syncState ?? this.syncState,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      gradeId: gradeId ?? this.gradeId,
      subjectId: subjectId ?? this.subjectId,
      totalChapters: totalChapters ?? this.totalChapters,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      nextSyncDueAt: nextSyncDueAt ?? this.nextSyncDueAt,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    );
  }
}

/// Installation status of an educational pack
enum PackInstallationStatus {
  discovered, // Found but not installed
  downloading, // Currently syncing
  installed, // Fully available offline
  failed, // Sync failed
  notFound, // Not in database
  error, // Error occurred
}
