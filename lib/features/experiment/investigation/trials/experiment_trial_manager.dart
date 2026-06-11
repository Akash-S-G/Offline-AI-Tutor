import 'package:flutter/foundation.dart';

import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_world.dart';
import '../analytics/investigation_analytics.dart';
import '../models/experiment_trial.dart';
import '../models/trial_snapshot.dart';
import '../models/trial_status.dart';
import '../storage/trial_repository.dart';

class ExperimentTrialManager extends ChangeNotifier {
  final RuntimeWorld world;
  final InvestigationAnalytics analytics;
  final TrialRepository repository;
  final List<ExperimentTrial> _trials = [];
  ExperimentTrial? _activeTrial;
  DateTime? _trialStartedAt;

  ExperimentTrialManager({
    required this.world,
    required this.analytics,
    TrialRepository? repository,
  }) : repository = repository ?? InMemoryTrialRepository();

  List<ExperimentTrial> get trials => List.unmodifiable(_trials);
  ExperimentTrial? get activeTrial => _activeTrial;
  bool get isRunning => _activeTrial != null;
  int get trialCount => _trials.length;
  int get completedTrialCount =>
      _trials.where((trial) => trial.status == TrialStatus.saved).length;
  double get averageTrialsPerExperiment => analytics.averageTrialsPerExperiment;

  ExperimentTrial startTrial({Map<String, dynamic>? parameterValues}) {
    if (_activeTrial != null) return _activeTrial!;
    final start = DateTime.now();
    final trial = ExperimentTrial(
      trialId: 'trial_${DateTime.now().microsecondsSinceEpoch}',
      trialNumber: _trials.length + 1,
      startTime: start,
      parameterValues: parameterValues ?? _currentParameterValues(),
      timestamp: start,
      status: TrialStatus.running,
    );
    _activeTrial = trial;
    _trialStartedAt = start;
    analytics.trialsStarted++;
    world.eventBus.emit(
      createEvent('TrialStarted', {
        'trialId': trial.trialId,
        'trialNumber': trial.trialNumber,
      }),
    );
    world.start();
    notifyListeners();
    return trial;
  }

  ExperimentTrial? stopTrial({bool save = true}) {
    final trial = _activeTrial;
    if (trial == null) return null;
    final duration = DateTime.now().difference(
      _trialStartedAt ?? trial.timestamp,
    );
    final endTime = DateTime.now();
    final snapshot = TrialSnapshot.fromWorld(world);
    final saved = trial.copyWith(
      endTime: endTime,
      observations: world.observationStore.getObservations(),
      measurements: {
        for (final id in world.measurementStore.trackedVariableIds)
          id: world.measurementStore.sampleCount(id),
      },
      duration: duration,
      snapshot: snapshot,
      status: save ? TrialStatus.saved : TrialStatus.discarded,
    );
    _activeTrial = null;
    _trialStartedAt = null;
    world.pause();
    if (save) {
      saveTrial(saved);
    }
    notifyListeners();
    return saved;
  }

  void saveTrial(ExperimentTrial trial) {
    final index = _trials.indexWhere((item) => item.trialId == trial.trialId);
    if (index >= 0) {
      _trials[index] = trial;
    } else {
      _trials.add(trial);
      analytics.trialsCompleted++;
    }
    repository.save(trial);
    world.eventBus.emit(
      createEvent('TrialCompleted', {
        'trialId': trial.trialId,
        'trialNumber': trial.trialNumber,
        'durationMs': trial.duration.inMilliseconds,
      }),
    );
    notifyListeners();
  }

  Future<List<ExperimentTrial>> loadTrials() async {
    final loaded = await repository.loadAll();
    _trials
      ..clear()
      ..addAll(loaded);
    notifyListeners();
    return trials;
  }

  ExperimentTrial? loadTrial(String trialId) {
    for (final trial in _trials) {
      if (trial.trialId == trialId) return trial;
    }
    return null;
  }

  Future<void> deleteTrial(String trialId) async {
    _trials.removeWhere((trial) => trial.trialId == trialId);
    await repository.delete(trialId);
    world.eventBus.emit(createEvent('TrialDeleted', {'trialId': trialId}));
    notifyListeners();
  }

  void resetTrial() {
    _activeTrial = null;
    _trialStartedAt = null;
    world.stop();
    notifyListeners();
  }

  Map<String, dynamic> _currentParameterValues() {
    return world.variables.allRuntimeVariables.map(
      (id, variable) =>
          MapEntry(variable.name.isEmpty ? id : variable.name, variable.value),
    );
  }

  RuntimeEvent createEvent(String message, Map<String, dynamic> metadata) {
    return RuntimeEvent(
      id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: RuntimeEventType.custom,
      message: message,
      metadata: metadata,
    );
  }
}
