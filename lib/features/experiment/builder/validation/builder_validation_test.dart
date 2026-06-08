// ignore_for_file: avoid_print

import '../controllers/experiment_builder_controller.dart';
import '../models/builder_scene.dart';
import '../models/builder_variable.dart';
import '../models/builder_object.dart';
import '../models/builder_rule.dart';
import '../../application/execution_definition_mapper.dart';
import '../../runtime/playground/engine/simulation_playground_engine.dart';
import '../storage/builder_draft_manager.dart';
import '../storage/builder_draft_repository.dart';
import '../data/repositories/experiment_manifest_repository.dart';
import '../data/api/experiment_manifest_api_service.dart';
import '../../../network/domain/backend_config.dart';
import 'dart:convert';

class BuilderValidationTest {
  Future<void> runTest() async {
    print('--------------------------------------------------');
    print('EXPERIMENT BUILDER VALIDATION');
    print('--------------------------------------------------');

    final config = BackendConfig(baseUrl: 'http://localhost', apiKey: 'dummy');
    final apiService = ExperimentManifestApiService(config);
    final repo = ExperimentManifestRepositoryImpl(apiService);
    final draftManager = BuilderDraftManager(SharedPreferencesBuilderDraftRepository());
    
    final controller = ExperimentBuilderController(
      draftManager: draftManager,
      manifestRepository: repo,
    );

    // 1. Setup Scene
    controller.updateScene(BuilderScene(
      id: 'scene_pendulum',
      name: 'Pendulum Demo',
      description: 'A test pendulum scene',
      tags: ['physics', 'test'],
    ));

    // 2. Setup Variables
    controller.addVariable(BuilderVariable(
      id: 'var_gravity',
      name: 'gravity',
      type: 'number',
      defaultValue: 9.81,
      description: 'Gravity constant',
    ));
    controller.addVariable(BuilderVariable(
      id: 'var_length',
      name: 'length',
      type: 'number',
      defaultValue: 2.0,
      description: 'Pendulum length',
    ));

    // 3. Setup Objects
    controller.addObject(BuilderObject(
      id: 'obj_pendulum',
      name: 'pendulum_ball',
      type: 'pendulum',
      properties: {
        'radius': 10,
        'mass': 5,
      },
    ));

    // 4. Setup Rules
    controller.addRule(BuilderRule(
      id: 'rule_gravity_changed',
      name: 'gravity_changed',
      condition: {'variable': 'gravity', 'operator': 'changed'},
      action: {'type': 'update_physics'},
      description: 'Updates engine when gravity changes',
    ));

    // 5. Validate Manifest
    final isValid = controller.validateManifest();
    print('Validation Success: $isValid');
    if (!isValid) {
      print('Errors: ${controller.validationResult?.errors}');
    }

    final manifest = controller.generateManifest();
    final String jsonString = jsonEncode(manifest);
    final Map<String, dynamic> decodedManifest = jsonDecode(jsonString);
    print('Manifest Generated: ${manifest.isNotEmpty}');

    // 7. Load into Runtime Preview
    final engine = SimulationPlaygroundEngine();
    try {
      final sceneModel = ExecutionDefinitionMapper.mapToScene(decodedManifest);
      engine.loadSceneModel(sceneModel);
      print('Runtime Preview Loads: SUCCESS');
      print('Loaded Objects: ${sceneModel.objects.length}');
      print('Loaded Variables: ${sceneModel.variables.length}');
      print('Loaded Rules: ${sceneModel.rules.length}');
    } catch (e) {
      print('Runtime Preview Loads: FAILED - $e');
    } finally {
      engine.dispose();
      controller.dispose();
    }

    print('--------------------------------------------------');
  }
}
