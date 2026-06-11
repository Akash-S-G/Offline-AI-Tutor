import '../experiment_state/runtime_experiment_state.dart';
import '../experiment_state/runtime_experiment_status.dart';
import '../models/runtime_object_state.dart';
import '../models/runtime_variable.dart';
import '../measurements/runtime_measurement.dart';
import '../observations/runtime_observation.dart';
import '../runtime_event_bus.dart';
import '../runtime_world.dart';
import 'runtime_session.dart';
import 'runtime_session_events.dart';
import 'runtime_session_repository.dart';
import 'runtime_session_serializer.dart';

class RuntimeSessionManager {
  final RuntimeSessionRepository repository;
  final RuntimeSessionSerializer serializer;
  final RuntimeEventBus? eventBus;

  const RuntimeSessionManager({
    required this.repository,
    this.serializer = const RuntimeSessionSerializer(),
    this.eventBus,
  });

  Future<RuntimeSession> save(
    RuntimeWorld world, {
    String? sessionId,
    bool autosave = false,
  }) async {
    final now = DateTime.now();
    final experimentId = world.experimentState.state.experimentId;
    RuntimeSession? previous;
    if (sessionId != null) {
      previous = await repository.load(sessionId);
    }
    final resolvedSessionId =
        sessionId ?? 'session_${experimentId}_${now.microsecondsSinceEpoch}';
    final measurements = world.measurementStore.exportMeasurements();
    final session = RuntimeSession(
      sessionId: resolvedSessionId,
      experimentId: experimentId,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      status: world.experimentState.state.status,
      variables: world.variables.allRuntimeVariables.map(
        (id, variable) => MapEntry(id, variable.toJson()),
      ),
      objectStates: {
        for (final objectState in world.objects.allObjectStates)
          objectState.objectId: objectState.toJson(),
      },
      metrics: world.experimentState.state.metrics,
      observations: world.observationStore.getObservations(),
      measurementCounts: measurements.map(
        (variableId, entries) => MapEntry(variableId, entries.length),
      ),
      measurements: measurements,
      runtimeSeconds: world.clock.elapsedTime,
      autosaveCount: (previous?.autosaveCount ?? 0) + (autosave ? 1 : 0),
    );
    await repository.save(session);
    eventBus?.emit(
      runtimeSessionEvent(
        autosave
            ? RuntimeSessionEventType.autosaveCompleted
            : RuntimeSessionEventType.sessionSaved,
        sessionId: session.sessionId,
        experimentId: session.experimentId,
        metadata: {'autosaveCount': session.autosaveCount},
      ),
    );
    return session;
  }

  Future<RuntimeSession?> load(String sessionId) => repository.load(sessionId);

  Future<List<RuntimeSession>> list({String? experimentId}) {
    return repository.list(experimentId: experimentId);
  }

  Future<void> delete(String sessionId, {String? experimentId}) async {
    await repository.delete(sessionId);
    eventBus?.emit(
      runtimeSessionEvent(
        RuntimeSessionEventType.sessionDeleted,
        sessionId: sessionId,
        experimentId: experimentId ?? '',
      ),
    );
  }

  Future<RuntimeSession?> recoveryForExperiment(String experimentId) async {
    final session = await repository.latestForExperiment(experimentId);
    if (session != null) {
      eventBus?.emit(
        runtimeSessionEvent(
          RuntimeSessionEventType.sessionRecoveryAvailable,
          sessionId: session.sessionId,
          experimentId: session.experimentId,
        ),
      );
    }
    return session;
  }

  Future<void> restore(RuntimeWorld world, RuntimeSession session) async {
    final variables = serializer.variablesFromSession(session);
    final objectStates = serializer.objectStatesFromSession(session);
    world.restoreSessionState(
      variables: variables,
      objectStates: objectStates,
      experimentState: RuntimeExperimentState.fromJson({
        'experimentId': session.experimentId,
        'status': session.status.name,
        'runtimeSeconds': session.runtimeSeconds,
        'observations': session.observations.length,
        'measurements': session.measurementCounts.values.fold<int>(
          0,
          (sum, count) => sum + count,
        ),
        'warnings': session.metrics.warnings,
        'rulesTriggered': session.metrics.rulesTriggered,
        'startedAt': session.createdAt.toIso8601String(),
        'completedAt': null,
        'metrics': session.metrics.toJson(),
      }),
      observations: session.observations,
      measurements: session.measurements,
      runtimeSeconds: session.runtimeSeconds,
    );
    eventBus?.emit(
      runtimeSessionEvent(
        RuntimeSessionEventType.sessionLoaded,
        sessionId: session.sessionId,
        experimentId: session.experimentId,
      ),
    );
  }
}

extension RuntimeSessionWorldRestore on RuntimeWorld {
  void restoreSessionState({
    required Map<String, RuntimeVariable> variables,
    required List<RuntimeObjectState> objectStates,
    required RuntimeExperimentState experimentState,
    required List<RuntimeObservation> observations,
    required Map<String, List<RuntimeMeasurement>> measurements,
    required double runtimeSeconds,
  }) {
    this.variables.restoreVariables(variables);
    objects.restoreObjectStates(objectStates);
    this.experimentState.restore(experimentState);
    observationStore.restoreObservations(observations);
    measurementStore.restoreMeasurements(measurements);
    clock.restore(
      elapsedTime: runtimeSeconds,
      running: experimentState.status == RuntimeExperimentStatus.running,
    );
  }
}
