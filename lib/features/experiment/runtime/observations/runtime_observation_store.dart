import 'runtime_observation.dart';

class RuntimeObservationStore {
  final List<RuntimeObservation> _observations = [];

  RuntimeObservation addObservation(RuntimeObservation observation) {
    _observations.add(observation);
    return observation;
  }

  RuntimeObservation? removeObservation(String id) {
    final index = _observations.indexWhere(
      (observation) => observation.id == id,
    );
    if (index < 0) return null;
    return _observations.removeAt(index);
  }

  int clearObservations() {
    final count = _observations.length;
    _observations.clear();
    return count;
  }

  void restoreObservations(List<RuntimeObservation> observations) {
    _observations
      ..clear()
      ..addAll(observations);
  }

  List<RuntimeObservation> getObservations() {
    return List.unmodifiable(_observations);
  }

  RuntimeObservation? latestObservation() {
    if (_observations.isEmpty) return null;
    return _observations.last;
  }

  List<Map<String, dynamic>> exportJson() {
    return _observations
        .map((observation) {
          return {
            'runtimeSeconds': observation.runtimeSeconds,
            ...observation.values,
          };
        })
        .toList(growable: false);
  }

  int get rowCount => _observations.length;
}
