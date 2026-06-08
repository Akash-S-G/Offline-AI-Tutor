import '../api/experiment_manifest_api_service.dart';

class ManifestValidationResponse {
  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
  ManifestValidationResponse({required this.isValid, this.warnings = const [], this.errors = const []});
}

class ManifestCompatibilityResponse {
  final String manifestVersion;
  final bool supported;
  final bool migrationRequired;
  final String targetVersion;

  ManifestCompatibilityResponse({
    required this.manifestVersion,
    required this.supported,
    required this.migrationRequired,
    required this.targetVersion,
  });
}

abstract class ExperimentManifestRepository {
  Future<ManifestValidationResponse> validate(Map<String, dynamic> manifest);
  Future<ManifestCompatibilityResponse> checkCompatibility(Map<String, dynamic> manifest);
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> manifest);
  Future<Map<String, dynamic>> getExecutionPackage(Map<String, dynamic> manifest, Map<String, bool> capabilities);
}

class ExperimentManifestRepositoryImpl implements ExperimentManifestRepository {
  final ExperimentManifestApiService _apiService;

  ExperimentManifestRepositoryImpl(this._apiService);

  @override
  Future<ManifestValidationResponse> validate(Map<String, dynamic> manifest) async {
    try {
      final data = await _apiService.validateManifest(manifest);
      return ManifestValidationResponse(
        isValid: data['isValid'] ?? false,
        warnings: List<String>.from(data['warnings'] ?? []),
        errors: List<String>.from(data['errors'] ?? []),
      );
    } catch (e) {
      return ManifestValidationResponse(isValid: false, errors: [e.toString()]);
    }
  }

  @override
  Future<ManifestCompatibilityResponse> checkCompatibility(Map<String, dynamic> manifest) async {
    try {
      final data = await _apiService.checkCompatibility(manifest);
      return ManifestCompatibilityResponse(
        manifestVersion: data['manifestVersion'] ?? '0.0.0',
        supported: data['supported'] ?? false,
        migrationRequired: data['migrationRequired'] ?? false,
        targetVersion: data['targetVersion'] ?? '0.0.0',
      );
    } catch (e) {
      return ManifestCompatibilityResponse(
        manifestVersion: 'unknown',
        supported: false,
        migrationRequired: false,
        targetVersion: 'unknown',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> manifest) async {
    return await _apiService.migrateManifest(manifest);
  }

  @override
  Future<Map<String, dynamic>> getExecutionPackage(Map<String, dynamic> manifest, Map<String, bool> capabilities) async {
    return await _apiService.fetchExecutionPackage(manifest, capabilities);
  }
}
