import 'dart:math';

import '../measurements/runtime_measurement.dart';
import '../measurements/runtime_measurement_store.dart';
import 'line_graph_state.dart';
import 'runtime_graph_point.dart';

class LineGraphBehavior {
  static const int graphSampleWindow = 100;

  final RuntimeMeasurementStore measurementStore;

  const LineGraphBehavior({required this.measurementStore});

  LineGraphState buildStateForVariable(String? variableId) {
    if (variableId == null || variableId.isEmpty) {
      return const LineGraphState.empty();
    }
    final history = measurementStore.getMeasurements(variableId);
    if (history.isEmpty) {
      return LineGraphState.empty(linkedVariableId: variableId);
    }
    final visibleHistory = _latestWindow(history);
    final points = visibleHistory
        .map(
          (measurement) => RuntimeGraphPoint(
            x: measurement.runtimeSeconds,
            y: _numeric(measurement.value),
          ),
        )
        .toList(growable: false);
    final xValues = points.map((point) => point.x);
    final yValues = points.map((point) => point.y);
    return LineGraphState(
      points: points,
      minX: xValues.reduce((a, b) => a < b ? a : b),
      maxX: xValues.reduce((a, b) => a > b ? a : b),
      minY: yValues.reduce((a, b) => a < b ? a : b),
      maxY: yValues.reduce((a, b) => a > b ? a : b),
      sampleCount: points.length,
      linkedVariableId: variableId,
    );
  }

  List<RuntimeMeasurement> _latestWindow(List<RuntimeMeasurement> history) {
    if (history.length <= graphSampleWindow) return history;
    return history.sublist(history.length - graphSampleWindow);
  }

  double _numeric(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) {
      for (final key in const [
        'magnitude',
        'value',
        'amplitude',
        'lux',
        'distance',
        'accuracy',
        'speed',
        'altitude',
        'latitude',
      ]) {
        final entry = value[key];
        if (entry is num) return entry.toDouble();
      }
      final x = value['x'];
      final y = value['y'];
      final z = value['z'];
      if (x is num && y is num && z is num) {
        return sqrt(x * x + y * y + z * z);
      }
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
