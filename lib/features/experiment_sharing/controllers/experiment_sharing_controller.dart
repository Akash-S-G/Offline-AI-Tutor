// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import '../models/experiment_package.dart';
import '../repositories/experiment_sharing_repository.dart';
import '../../experiment/builder/data/repositories/experiment_manifest_repository.dart';
import '../../experiment/builder/storage/builder_draft_manager.dart';
import '../../experiment/analytics/telemetry_service.dart';

class ExperimentSharingController extends ChangeNotifier {
  final ExperimentSharingRepository _sharingRepository;
  final ExperimentManifestRepository _manifestRepository;
  final BuilderDraftManager _draftManager;

  ExperimentSharingController({
    required ExperimentSharingRepository sharingRepository,
    required ExperimentManifestRepository manifestRepository,
    required BuilderDraftManager draftManager,
  })  : _sharingRepository = sharingRepository,
        _manifestRepository = manifestRepository,
        _draftManager = draftManager;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ExperimentPackage? _previewPackage;
  ExperimentPackage? get previewPackage => _previewPackage;

  ManifestValidationResponse? _validationResult;
  ManifestValidationResponse? get validationResult => _validationResult;

  ManifestCompatibilityResponse? _compatibilityResult;
  ManifestCompatibilityResponse? get compatibilityResult => _compatibilityResult;

  /// Starts the export process for a given draft manifest.
  Future<void> exportDraft(String title, Map<String, dynamic> manifest) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final package = ExperimentPackage.create(
        manifest: manifest,
        author: 'Local Student', // Or fetch from a user profile
      );

      final path = await _sharingRepository.exportPackage(package, title);
      TelemetryService().trackEvent('experiment_package_exported');
      print('[SHARING] EXPORT_SUCCESS path=$path');
      _error = 'Exported to: $path'; // Using error field to show success snackbar later, or we can use a callback
    } catch (e) {
      _error = e.toString();
      print('[SHARING] EXPORT_FAILED error=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts the import flow: select file -> verify signature -> validate -> preview.
  Future<void> beginImportFlow() async {
    _isLoading = true;
    _error = null;
    _previewPackage = null;
    _validationResult = null;
    _compatibilityResult = null;
    notifyListeners();

    try {
      final package = await _sharingRepository.importPackage();
      if (package == null) {
        _isLoading = false;
        notifyListeners();
        return; // User canceled
      }

      print('[SHARING] IMPORT_FILE_SELECTED');

      if (!package.isSignatureValid) {
        _error = 'Signature verification failed. The package may have been tampered with.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('[SHARING] SIGNATURE_VERIFIED');

      _previewPackage = package;

      // Backend checks (if available offline, they will fallback or succeed)
      _compatibilityResult = await _manifestRepository.checkCompatibility(package.manifest);
      print('[SHARING] COMPATIBILITY_CHECKED');

      _validationResult = await _manifestRepository.validate(package.manifest);
      print('[SHARING] VALIDATION_CHECKED');

    } catch (e) {
      _error = e.toString();
      print('[SHARING] IMPORT_FAILED error=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Finalizes import by pushing to drafts
  Future<void> importToDrafts() async {
    if (_previewPackage == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final scene = _previewPackage!.manifest['scene'] as Map<String, dynamic>? ?? {};
      final title = scene['name'] ?? 'Imported Experiment';
      
      await _draftManager.createDraft('$title (Imported)', _previewPackage!.manifest);
      TelemetryService().trackEvent('experiment_package_imported');
      print('[SHARING] IMPORT_TO_DRAFTS_SUCCESS');
      clearPreview();
    } catch (e) {
      _error = e.toString();
      print('[SHARING] IMPORT_TO_DRAFTS_FAILED error=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPreview() {
    _previewPackage = null;
    _validationResult = null;
    _compatibilityResult = null;
    _error = null;
    notifyListeners();
  }
}
