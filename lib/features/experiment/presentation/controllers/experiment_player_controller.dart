// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/orchestrator/experiment_execution_orchestrator.dart';
import '../../application/orchestrator/experiment_execution_state.dart';
import '../../application/orchestrator/experiment_execution_result.dart';
import '../../domain/models/experiment_models.dart';
import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_metrics.dart';
import '../../platform/experiment_capability_provider_impl.dart';
import '../../platform/experiment_capability_cache.dart';

import '../../data/repositories/experiment_manifest_execution_repository_impl.dart';
import '../../data/experiment_api_service.dart';
import '../../../network/domain/backend_config.dart';
import '../../application/execution_definition_mapper.dart';

class ExperimentPlayerController extends ChangeNotifier {
  late final ExperimentExecutionOrchestrator _orchestrator;
  late final ExperimentManifestExecutionRepositoryImpl _repository;
  
  ExperimentExecutionState _state = ExperimentExecutionState.idle;
  ExperimentExecutionState get state => _state;

  RuntimeMetrics? _metrics;
  RuntimeMetrics? get metrics => _metrics;

  ExperimentExecutionResult? _executionResult;
  ExperimentExecutionResult? get executionResult => _executionResult;

  final List<RuntimeEvent> _events = [];
  List<RuntimeEvent> get events => List.unmodifiable(_events);
  Stream<RuntimeEvent> get eventStream => _orchestrator.eventStream;

  StreamSubscription<RuntimeEvent>? _eventSubscription;

  ExperimentPlayerController() {
    final cache = ExperimentCapabilityCache();
    final provider = ExperimentCapabilityProviderImpl(cache);
    _orchestrator = ExperimentExecutionOrchestrator(provider);
    
    // In a real app this would be injected via dependency injection
    final config = BackendConfig(baseUrl: 'http://localhost:3000', apiKey: 'dummy');
    _repository = ExperimentManifestExecutionRepositoryImpl(ExperimentApiService(config));
  }

  Future<void> prepare(ExperimentManifest manifest) async {
    try {
      print('[EXPERIMENT] EXECUTION_FETCH_START');
      final definitionJson = await _repository.getExecutionDefinition(manifest.id);
      
      if (definitionJson != null) {
        print('[EXPERIMENT] EXECUTION_FETCH_SUCCESS');
        final scene = ExecutionDefinitionMapper.mapToScene(definitionJson);
        print('[EXPERIMENT] EXECUTION_MAPPING_SUCCESS');
        print('[EXPERIMENT] PLAYGROUND_SCENE_LOADED sceneId=${scene.sceneId}');
        print('[EXPERIMENT] PLAYGROUND_OBJECTS_COUNT count=${scene.objects.length}');
        print('[EXPERIMENT] PLAYGROUND_VARIABLES_COUNT count=${scene.variables.length}');
        print('[EXPERIMENT] PLAYGROUND_RULES_COUNT count=${scene.rules.length}');
        
        await _orchestrator.prepare(manifest, scene);
      } else {
        print('[EXPERIMENT] NO_REMOTE_EXECUTION_DEFINITION_FOUND');
        await _orchestrator.prepare(manifest);
      }
      
      _updateState();
      
      _eventSubscription = _orchestrator.eventStream.listen((event) {
        _events.insert(0, event); // Newest first
        if (_events.length > 100) {
          _events.removeLast(); // Keep only last 100 events for UI
        }
        _updateState();
      });
    } catch (e) {
      print('[EXPERIMENT_UI] PREPARE_ERROR error=$e');
      _updateState();
    }
  }

  Future<void> start() async {
    print('[EXPERIMENT_UI] PLAYER_STARTED');
    await _orchestrator.start();
    _updateState();
  }

  Future<void> pause() async {
    print('[EXPERIMENT_UI] PLAYER_PAUSED');
    await _orchestrator.pause();
    _updateState();
  }

  Future<void> resume() async {
    print('[EXPERIMENT_UI] PLAYER_RESUMED');
    await _orchestrator.resume();
    _updateState();
  }

  Future<void> stop() async {
    print('[EXPERIMENT_UI] PLAYER_STOPPED');
    await _orchestrator.stop();
    _executionResult = await _orchestrator.getResult();
    _updateState();
  }

  void _updateState() {
    _state = _orchestrator.state;
    // In a full implementation, orchestrator would expose metrics actively
    // Here we assume orchestrator provides metrics upon completion or we can poll it.
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _orchestrator.dispose();
    super.dispose();
  }
}
