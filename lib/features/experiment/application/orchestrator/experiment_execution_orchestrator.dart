// ignore_for_file: avoid_print

import 'dart:async';

import '../../domain/models/experiment_models.dart';
import '../experiment_capability_analyzer.dart';
import '../experiment_execution_planner.dart';
import '../../platform/experiment_capability_provider.dart';
import '../../runtime/base_experiment_runtime.dart';
import '../../runtime/runtime_factory.dart';
import '../../runtime/runtime_event.dart';

import 'experiment_execution_state.dart';
import 'experiment_execution_result.dart';

class ExperimentExecutionOrchestrator {
  final ExperimentCapabilityAnalyzer _analyzer = ExperimentCapabilityAnalyzer();
  final ExperimentExecutionPlanner _planner = ExperimentExecutionPlanner();
  final ExperimentCapabilityProvider _capabilityProvider;

  ExperimentExecutionState _state = ExperimentExecutionState.idle;
  ExperimentExecutionState get state => _state;

  BaseExperimentRuntime? _runtime;
  StreamSubscription<RuntimeEvent>? _eventSubscription;

  final StreamController<RuntimeEvent> _eventController = StreamController<RuntimeEvent>.broadcast();
  Stream<RuntimeEvent> get eventStream => _eventController.stream;

  ExperimentManifest? _manifest;
  DateTime? _startedAt;

  ExperimentExecutionOrchestrator(this._capabilityProvider);

  Future<void> prepare(ExperimentManifest manifest) async {
    print('[ORCHESTRATOR] PREPARE_START');
    _state = ExperimentExecutionState.preparing;
    _manifest = manifest;

    try {
      _state = ExperimentExecutionState.analyzing;
      final capabilities = await _capabilityProvider.getCapabilities();
      print('[ORCHESTRATOR] CAPABILITY_ANALYSIS_COMPLETE');

      _state = ExperimentExecutionState.planning;
      final report = _analyzer.analyze(manifest, capabilities);
      final plan = _planner.buildPlan(manifest, report);
      print('[ORCHESTRATOR] PLAN_CREATED');

      _state = ExperimentExecutionState.starting;
      _runtime = RuntimeFactory.createRuntime(plan);
      print('[ORCHESTRATOR] RUNTIME_CREATED');

      _eventSubscription = _runtime!.eventStream.listen(_onRuntimeEvent);

      await _runtime!.initialize();

    } catch (e) {
      _state = ExperimentExecutionState.failed;
      print('[ORCHESTRATOR] FAILED error=$e');
      rethrow;
    }
  }

  void _onRuntimeEvent(RuntimeEvent event) {
    // Forward to external listeners (UI in future)
    _eventController.add(event);

    // Track state internally based on events if needed, but metrics are handled by runtime.
    if (event.type == RuntimeEventType.sessionStarted) {
      _startedAt = DateTime.now();
      _state = ExperimentExecutionState.running;
      print('[ORCHESTRATOR] STARTED');
    } else if (event.type == RuntimeEventType.sessionPaused) {
      _state = ExperimentExecutionState.paused;
      print('[ORCHESTRATOR] PAUSED');
    } else if (event.type == RuntimeEventType.sessionResumed) {
      _state = ExperimentExecutionState.running;
      print('[ORCHESTRATOR] RESUMED');
    } else if (event.type == RuntimeEventType.sessionCompleted) {
      _state = ExperimentExecutionState.completed;
      print('[ORCHESTRATOR] COMPLETED');
    } else if (event.type == RuntimeEventType.error) {
      print('[ORCHESTRATOR] RUNTIME_ERROR message=${event.message}');
    }
  }

  Future<void> start() async {
    if (_runtime == null) throw Exception('Orchestrator not prepared.');
    _state = ExperimentExecutionState.starting;
    await _runtime!.start();
  }

  Future<void> pause() async {
    if (_runtime == null) throw Exception('Orchestrator not prepared.');
    await _runtime!.pause();
  }

  Future<void> resume() async {
    if (_runtime == null) throw Exception('Orchestrator not prepared.');
    await _runtime!.resume();
  }

  Future<void> stop() async {
    if (_runtime == null) throw Exception('Orchestrator not prepared.');
    await _runtime!.stop();
  }

  Future<ExperimentExecutionResult?> getResult() async {
    if (_runtime == null || _manifest == null || _startedAt == null) return null;

    final success = _state == ExperimentExecutionState.completed;
    return ExperimentExecutionResult(
      experimentId: _manifest!.id,
      runId: _runtime!.session.sessionId,
      executionMode: _runtime!.plan.selectedMode,
      startedAt: _startedAt!,
      completedAt: DateTime.now(),
      metrics: _runtime!.metrics,
      success: success,
      errorMessage: success ? null : 'Execution did not complete normally.',
    );
  }

  Future<void> dispose() async {
    _state = ExperimentExecutionState.disposed;
    await _eventSubscription?.cancel();
    await _eventController.close();
    await _runtime?.dispose();
    print('[ORCHESTRATOR] DISPOSED');
  }
}
