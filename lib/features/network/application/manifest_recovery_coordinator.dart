import 'dart:async';
import 'pack_version_manager.dart';

class ManifestValidationResult {
  const ManifestValidationResult({
    required this.isValid,
    required this.packId,
    this.errorMessage,
  });

  final bool isValid;
  final String packId;
  final String? errorMessage;
}

class PartialDownloadState {
  const PartialDownloadState({
    required this.packId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.timestamp,
  });

  final String packId;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime timestamp;

  double get percentComplete => downloadedBytes / totalBytes;

  bool get isResumable => downloadedBytes > 0 && downloadedBytes < totalBytes;
}

class ManifestRecoveryCoordinator {
  ManifestRecoveryCoordinator({
    required PackVersionManager versionManager,
    this.checksumValidationEnabled = true,
  })  : _versionManager = versionManager,
        _recoveryStream = StreamController<PackManifest>.broadcast();

  final PackVersionManager _versionManager;
  final bool checksumValidationEnabled;
  final StreamController<PackManifest> _recoveryStream;
  final Map<String, PartialDownloadState> _partialDownloads =
      <String, PartialDownloadState>{};

  Stream<PackManifest> get recoveredManifests => _recoveryStream.stream;

  Future<ManifestValidationResult> validateManifest(
    PackManifest manifest,
  ) async {
    if (manifest.packId.isEmpty) {
      return ManifestValidationResult(
        isValid: false,
        packId: manifest.packId,
        errorMessage: 'Pack ID cannot be empty',
      );
    }

    if (manifest.version <= 0) {
      return ManifestValidationResult(
        isValid: false,
        packId: manifest.packId,
        errorMessage: 'Invalid version: ${manifest.version}',
      );
    }

    if (checksumValidationEnabled && manifest.checksum.isEmpty) {
      return ManifestValidationResult(
        isValid: false,
        packId: manifest.packId,
        errorMessage: 'Checksum required but empty',
      );
    }

    return ManifestValidationResult(
      isValid: true,
      packId: manifest.packId,
    );
  }

  bool needsUpdate(PackManifest incoming) {
    return _versionManager.needsUpdate(incoming);
  }

  void recordPartialDownload({
    required String packId,
    required int downloadedBytes,
    required int totalBytes,
  }) {
    _partialDownloads[packId] = PartialDownloadState(
      packId: packId,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      timestamp: DateTime.now(),
    );
  }

  PartialDownloadState? getPartialDownload(String packId) {
    final state = _partialDownloads[packId];
    if (state == null) return null;

    // Clear stale partial downloads (older than 24 hours)
    final age = DateTime.now().difference(state.timestamp);
    if (age.inHours > 24) {
      _partialDownloads.remove(packId);
      return null;
    }

    return state;
  }

  Future<void> resumeInterruptedDownload(String packId) async {
    final partial = getPartialDownload(packId);
    if (partial == null || !partial.isResumable) {
      return;
    }

    // Recovery event is signaled through the stream
    _recoveryStream.add(
      PackManifest(
        packId: packId,
        version: 0, // Placeholder
        checksum: '', // Will be set during actual resume
      ),
    );
  }

  void clearPartialDownload(String packId) {
    _partialDownloads.remove(packId);
  }

  List<PartialDownloadState> getAllPendingDownloads() {
    return List<PartialDownloadState>.from(_partialDownloads.values);
  }

  Map<String, double> getRecoveryProgress() {
    final progress = <String, double>{};
    for (final state in _partialDownloads.values) {
      progress[state.packId] = state.percentComplete;
    }
    return progress;
  }

  void close() {
    _recoveryStream.close();
  }
}
