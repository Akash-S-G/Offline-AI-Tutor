import '../models/experiment_trial.dart';

abstract class TrialRepository {
  Future<void> save(ExperimentTrial trial);
  Future<void> delete(String trialId);
  Future<List<ExperimentTrial>> loadAll();
}

class InMemoryTrialRepository implements TrialRepository {
  final Map<String, ExperimentTrial> _trials = {};

  @override
  Future<void> save(ExperimentTrial trial) async {
    _trials[trial.trialId] = trial;
  }

  @override
  Future<void> delete(String trialId) async {
    _trials.remove(trialId);
  }

  @override
  Future<List<ExperimentTrial>> loadAll() async {
    return _trials.values.toList(growable: false);
  }
}
