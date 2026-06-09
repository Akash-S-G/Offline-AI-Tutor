import '../measurements/runtime_measurement.dart';
import '../measurements/runtime_measurement_store.dart';
import '../models/runtime_object_state.dart';
import '../objects/behavior/runtime_object_behavior.dart';
import 'runtime_scatter_point.dart';
import 'scatter_plot_state.dart';

class ScatterPlotBehavior extends PlaceholderRuntimeObjectBehavior {
  static const int pointWindow = 100;

  final RuntimeMeasurementStore? measurementStore;

  ScatterPlotBehavior({this.measurementStore});

  ScatterPlotState buildState({
    required String? xVariableId,
    required String? yVariableId,
  }) {
    if (xVariableId == null ||
        xVariableId.isEmpty ||
        yVariableId == null ||
        yVariableId.isEmpty) {
      return ScatterPlotState.empty(
        xVariableId: xVariableId,
        yVariableId: yVariableId,
      );
    }

    final store = measurementStore;
    if (store == null) {
      return ScatterPlotState.empty(
        xVariableId: xVariableId,
        yVariableId: yVariableId,
      );
    }

    final xHistory = store.getMeasurements(xVariableId);
    final yHistory = store.getMeasurements(yVariableId);
    final pairCount = xHistory.length < yHistory.length
        ? xHistory.length
        : yHistory.length;
    if (pairCount == 0) {
      return ScatterPlotState.empty(
        xVariableId: xVariableId,
        yVariableId: yVariableId,
      );
    }

    final visibleCount = pairCount > pointWindow ? pointWindow : pairCount;
    final xWindow = _latestWindow(xHistory, visibleCount);
    final yWindow = _latestWindow(yHistory, visibleCount);
    final points = <RuntimeScatterPoint>[];
    for (var i = 0; i < visibleCount; i++) {
      points.add(
        RuntimeScatterPoint(
          x: _numeric(xWindow[i].value),
          y: _numeric(yWindow[i].value),
        ),
      );
    }

    final xValues = points.map((point) => point.x);
    final yValues = points.map((point) => point.y);
    return ScatterPlotState(
      points: points,
      minX: xValues.reduce((a, b) => a < b ? a : b),
      maxX: xValues.reduce((a, b) => a > b ? a : b),
      minY: yValues.reduce((a, b) => a < b ? a : b),
      maxY: yValues.reduce((a, b) => a > b ? a : b),
      updatedAt: DateTime.now(),
      xVariableId: xVariableId,
      yVariableId: yVariableId,
    );
  }

  List<RuntimeMeasurement> _latestWindow(
    List<RuntimeMeasurement> history,
    int visibleCount,
  ) {
    if (history.length <= visibleCount) return history;
    return history.sublist(history.length - visibleCount);
  }

  double _numeric(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return const ValidationResult.valid();
  }
}
