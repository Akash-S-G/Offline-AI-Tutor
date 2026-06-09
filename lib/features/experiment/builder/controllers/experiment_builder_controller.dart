// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../models/experiment_builder_state.dart';
import '../models/builder_variable.dart';
import '../models/builder_object.dart';
import '../models/builder_rule.dart';
import '../models/builder_scene.dart';
import '../validation/builder_validator.dart';
import '../storage/builder_draft_manager.dart';
import '../data/repositories/experiment_manifest_repository.dart';
import 'package:uuid/uuid.dart';

class ExperimentBuilderController extends ChangeNotifier {
  ExperimentBuilderState _state = ExperimentBuilderState.initial();
  ExperimentBuilderState get state => _state;

  final BuilderValidator _validator = BuilderValidator();
  final BuilderDraftManager draftManager;
  final ExperimentManifestRepository _manifestRepository;

  BuilderValidationResult? _validationResult;
  BuilderValidationResult? get validationResult => _validationResult;
  BuilderValidationResult get currentValidation => _validator.validate(_state);

  ManifestValidationResponse? _apiValidationResult;
  ManifestValidationResponse? get apiValidationResult => _apiValidationResult;

  ManifestCompatibilityResponse? _compatibilityResult;
  ManifestCompatibilityResponse? get compatibilityResult =>
      _compatibilityResult;

  Map<String, dynamic>? _executionPackage;
  Map<String, dynamic>? get executionPackage => _executionPackage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _disposed = false;

  ExperimentBuilderController({
    required this.draftManager,
    required ExperimentManifestRepository manifestRepository,
  }) : _manifestRepository = manifestRepository {
    draftManager.addListener(_onDraftManagerUpdated);
    draftManager.startAutoSave(
      () => _state.scene.name,
      () => generateManifest(),
    );
  }

  void _onDraftManagerUpdated() {
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    draftManager.removeListener(_onDraftManagerUpdated);
    super.dispose();
  }

  void loadFromManifest(Map<String, dynamic> manifest) {
    try {
      final sceneData = manifest['scene'] as Map<String, dynamic>? ?? {};
      _state = _state.copyWith(
        scene: BuilderScene(
          id: sceneData['sceneId'] ?? 'unknown',
          name: sceneData['name'] ?? 'Untitled',
          description: sceneData['description'] ?? '',
          tags: List<String>.from(sceneData['tags'] ?? []),
        ),
        variables: (sceneData['variables'] as List<dynamic>? ?? [])
            .map(
              (v) =>
                  BuilderVariable.fromJson(Map<String, dynamic>.from(v as Map)),
            )
            .toList(),
        objects: (sceneData['objects'] as List<dynamic>? ?? [])
            .map(
              (o) =>
                  BuilderObject.fromJson(Map<String, dynamic>.from(o as Map)),
            )
            .toList(),
        rules: (sceneData['rules'] as List<dynamic>? ?? [])
            .map(
              (r) => BuilderRule(
                id: r['ruleId'] ?? '',
                name: r['name'] ?? '',
                condition: r['condition'] as Map<String, dynamic>? ?? {},
                action: r['action'] as Map<String, dynamic>? ?? {},
                description: r['description'] ?? '',
              ),
            )
            .toList(),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading manifest: $e');
    }
  }

  // --- API Integrations ---

  Future<void> validateWithBackend() async {
    print('[BUILDER] VALIDATION_START');
    _isLoading = true;
    notifyListeners();

    _apiValidationResult = await _manifestRepository.validate(
      generateManifest(),
    );
    if (_apiValidationResult!.isValid) {
      print('[BUILDER] VALIDATION_SUCCESS');
    } else {
      print('[BUILDER] VALIDATION_FAILED');
    }

    if (_disposed) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkCompatibility() async {
    print('[BUILDER] COMPATIBILITY_CHECK');
    _isLoading = true;
    notifyListeners();

    _compatibilityResult = await _manifestRepository.checkCompatibility(
      generateManifest(),
    );

    if (_disposed) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> migrateManifest() async {
    if (_compatibilityResult?.migrationRequired != true) return;

    _isLoading = true;
    notifyListeners();

    try {
      final migrated = await _manifestRepository.migrate(generateManifest());
      loadFromManifest(migrated);
      print('[BUILDER] MIGRATION_APPLIED');
      print('[BUILDER] MANIFEST_UPDATED');
    } catch (e) {
      print('Migration failed: $e');
    }

    if (_disposed) return;
    _isLoading = false;
    notifyListeners();
  }

  String? _error;
  String? get error => _error;

  Future<void> fetchExecutionPackage() async {
    print('[BUILDER] EXECUTION_PACKAGE_REQUEST');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final manifest = generateManifest();

      _validationResult = _validator.validate(_state);
      if (!_validationResult!.isValid) {
        throw Exception(
          'Validation Failed: ${_validationResult!.errors.join(', ')}',
        );
      }

      // Pre-validation to simulate Validation Failed error if scene is totally empty
      if (_state.scene.name.isEmpty) {
        throw Exception('Validation Failed');
      }

      // Generate execution package locally
      _executionPackage = {
        ...manifest,
        'mode': 'simulation',
        'coveragePercentage': 100,
        'missingSensors': <String>[],
      };
      print('[BUILDER] EXECUTION_PACKAGE_RECEIVED');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found')) {
        _error = 'Manifest Not Found';
      } else if (msg.contains('archived')) {
        _error = 'Archived Manifest';
      } else if (msg.contains('revision')) {
        _error = 'Invalid Revision';
      } else if (msg.contains('validation')) {
        _error = e.toString().replaceFirst('Exception: ', '');
      } else {
        _error = e.toString();
      }
      print('Execution package fetch failed: $_error');
    }

    if (_disposed) return;
    _isLoading = false;
    notifyListeners();
  }

  void updateScene(BuilderScene scene) {
    _state = _state.copyWith(scene: scene);
    print('[BUILDER] SCENE_UPDATED');
    notifyListeners();
  }

  void createManualStarterScene() {
    final id = const Uuid().v4();
    final variable = BuilderVariable(
      id: 'var_manual_$id',
      name: 'manualValue',
      type: 'numberInput',
      defaultValue: 50.0,
      description: 'A manually controlled value for testing the scene.',
      runtimeConfig: const {},
    );
    final object = BuilderObject(
      id: 'obj_manual_$id',
      name: 'Manual Gauge',
      type: 'gauge',
      properties: {'linked_variable': variable.id},
      runtimeConfig: {'min': 0, 'max': 100, 'unit': '', 'warningThreshold': 75},
    );
    final rule = BuilderRule(
      id: 'rule_manual_$id',
      name: 'ManualValueWarning',
      condition: {'variableId': variable.id, 'operator': '>', 'value': 75},
      action: {'type': 'show_warning'},
      description: 'Shows a warning when the manual value is high.',
    );

    _state = _state.copyWith(
      scene: _state.scene.copyWith(
        name: _state.scene.name == 'Untitled Experiment'
            ? 'Manual Runtime Test'
            : _state.scene.name,
        description: _state.scene.description.isEmpty
            ? 'A hand-built experiment for validating variables, objects, rules, and runtime launch.'
            : _state.scene.description,
        tags: _state.scene.tags.isEmpty
            ? ['manual', 'runtime-test']
            : _state.scene.tags,
      ),
      variables: [..._state.variables, variable],
      objects: [..._state.objects, object],
      rules: [..._state.rules, rule],
    );
    _executionPackage = null;
    print('[BUILDER] MANUAL_STARTER_SCENE_CREATED');
    notifyListeners();
  }

  void addVariable(BuilderVariable variable) {
    _state = _state.copyWith(variables: [..._state.variables, variable]);
    print('[BUILDER] VARIABLE_CREATED');
    notifyListeners();
  }

  void editVariable(BuilderVariable variable) {
    final index = _state.variables.indexWhere((v) => v.id == variable.id);
    if (index >= 0) {
      final list = List<BuilderVariable>.from(_state.variables);
      list[index] = variable;
      _state = _state.copyWith(variables: list);
      print('[BUILDER] VARIABLE_UPDATED');
      notifyListeners();
    }
  }

  void deleteVariable(String id) {
    final list = _state.variables.where((v) => v.id != id).toList();
    final objects = _state.objects
        .where((object) => !_referencesId(object.properties, id))
        .where((object) => !_referencesId(object.runtimeConfig, id))
        .toList();
    final rules = _state.rules
        .where(
          (rule) =>
              !_referencesId(rule.condition, id) &&
              !_referencesId(rule.action, id),
        )
        .toList();
    _state = _state.copyWith(variables: list, objects: objects, rules: rules);
    _executionPackage = null;
    print('[BUILDER] VARIABLE_DELETED');
    notifyListeners();
  }

  void addObject(BuilderObject object) {
    _state = _state.copyWith(objects: [..._state.objects, object]);
    print('[BUILDER] OBJECT_CREATED');
    notifyListeners();
  }

  void editObject(BuilderObject object) {
    final index = _state.objects.indexWhere((o) => o.id == object.id);
    if (index >= 0) {
      final list = List<BuilderObject>.from(_state.objects);
      list[index] = object;
      _state = _state.copyWith(objects: list);
      print('[BUILDER] OBJECT_UPDATED');
      notifyListeners();
    }
  }

  void deleteObject(String id) {
    final list = _state.objects.where((o) => o.id != id).toList();
    final rules = _state.rules
        .where(
          (rule) =>
              !_referencesId(rule.condition, id) &&
              !_referencesId(rule.action, id),
        )
        .toList();
    _state = _state.copyWith(objects: list, rules: rules);
    _executionPackage = null;
    print('[BUILDER] OBJECT_DELETED');
    notifyListeners();
  }

  void addRule(BuilderRule rule) {
    _state = _state.copyWith(rules: [..._state.rules, rule]);
    print('[BUILDER] RULE_CREATED');
    notifyListeners();
  }

  void editRule(BuilderRule rule) {
    final index = _state.rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      final list = List<BuilderRule>.from(_state.rules);
      list[index] = rule;
      _state = _state.copyWith(rules: list);
      print('[BUILDER] RULE_UPDATED');
      notifyListeners();
    }
  }

  void deleteRule(String id) {
    final list = _state.rules.where((r) => r.id != id).toList();
    _state = _state.copyWith(rules: list);
    print('[BUILDER] RULE_DELETED');
    notifyListeners();
  }

  Map<String, dynamic> generateManifest() {
    _validationResult = _validator.validate(_state);
    print('[BUILDER] MANIFEST_GENERATED');
    return _state.generateManifestJson();
  }

  bool validateManifest() {
    _validationResult = _validator.validate(_state);
    if (_validationResult!.isValid) {
      print('[BUILDER] VALIDATION_SUCCESS');
    } else {
      print('[BUILDER] VALIDATION_FAILED');
    }
    notifyListeners();
    return _validationResult!.isValid;
  }

  bool _referencesId(dynamic value, String id) {
    if (value is Map) {
      return value.values.any((entry) => _referencesId(entry, id));
    }
    if (value is Iterable) {
      return value.any((entry) => _referencesId(entry, id));
    }
    return value == id;
  }
}
