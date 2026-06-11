import '../models/experiment_trial.dart';

class ObservationComparator {
  List<Map<String, dynamic>> compare(List<ExperimentTrial> trials) {
    return trials
        .map((trial) {
          final latest = trial.observations.isEmpty
              ? null
              : trial.observations.last.values;
          return {
            'trial': trial.trialNumber,
            'note': latest ?? const <String, dynamic>{},
          };
        })
        .toList(growable: false);
  }
}
