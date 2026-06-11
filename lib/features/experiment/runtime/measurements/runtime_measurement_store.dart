import 'runtime_measurement.dart';

class RuntimeMeasurementStore {
  static const int defaultHistoryLimit = 500;

  final int historyLimit;
  final Map<String, List<RuntimeMeasurement>> _measurements = {};

  RuntimeMeasurementStore({this.historyLimit = defaultHistoryLimit});

  List<RuntimeMeasurement> addMeasurement(RuntimeMeasurement measurement) {
    final history = _measurements.putIfAbsent(
      measurement.variableId,
      () => <RuntimeMeasurement>[],
    );
    history.add(measurement);
    return trimHistory(measurement.variableId);
  }

  List<RuntimeMeasurement> getMeasurements(String variableId) {
    return List.unmodifiable(
      _measurements[variableId] ?? const <RuntimeMeasurement>[],
    );
  }

  RuntimeMeasurement? getLatestMeasurement(String variableId) {
    final history = _measurements[variableId];
    if (history == null || history.isEmpty) return null;
    return history.last;
  }

  int clearMeasurements(String variableId) {
    return _measurements.remove(variableId)?.length ?? 0;
  }

  int clearAllMeasurements() {
    var count = 0;
    for (final history in _measurements.values) {
      count += history.length;
    }
    _measurements.clear();
    return count;
  }

  void restoreMeasurements(Map<String, List<RuntimeMeasurement>> measurements) {
    _measurements
      ..clear()
      ..addAll(measurements.map((key, value) => MapEntry(key, List.of(value))));
    for (final variableId in _measurements.keys.toList(growable: false)) {
      trimHistory(variableId);
    }
  }

  Map<String, List<RuntimeMeasurement>> exportMeasurements() {
    return _measurements.map(
      (key, value) => MapEntry(key, List.unmodifiable(value)),
    );
  }

  List<RuntimeMeasurement> trimHistory(String variableId) {
    final history = _measurements[variableId];
    if (history == null || history.length <= historyLimit) return const [];
    final discardCount = history.length - historyLimit;
    final discarded = history.take(discardCount).toList(growable: false);
    history.removeRange(0, discardCount);
    return discarded;
  }

  List<String> get trackedVariableIds =>
      List.unmodifiable(_measurements.keys.toList(growable: false));

  int sampleCount(String variableId) => _measurements[variableId]?.length ?? 0;

  int get trackedVariableCount => _measurements.length;
}
