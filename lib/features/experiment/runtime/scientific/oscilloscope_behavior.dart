import '../measurements/runtime_measurement.dart';
import '../measurements/runtime_measurement_store.dart';
import '../models/runtime_object_state.dart';
import '../objects/behavior/runtime_object_behavior.dart';
import 'oscilloscope_state.dart';
import 'runtime_multi_binding.dart';
import 'scientific_value_reader.dart';

class OscilloscopeBehavior extends PlaceholderRuntimeObjectBehavior {
  static const int sampleWindow = 200;

  final RuntimeMeasurementStore? measurementStore;
  final Map<String, dynamic>? objectJson;

  OscilloscopeBehavior({this.measurementStore, this.objectJson});

  OscilloscopeState buildState() {
    final object = objectJson ?? const <String, dynamic>{};
    final properties = objectProperties(object);
    final binding = RuntimeMultiBinding.fromObjectJson(object);
    final variableId =
        binding.variableForRole('value') ?? binding.variableForRole('source');
    if (variableId == null || variableId.isEmpty || measurementStore == null) {
      return const OscilloscopeState.empty();
    }

    final history = measurementStore!.getMeasurements(variableId);
    if (history.isEmpty) return const OscilloscopeState.empty();
    final visible = _latestWindow(history)
        .map((measurement) {
          final field =
              properties['field']?.toString() ?? properties['axis']?.toString();
          return numericValue(measurement.value, field: field);
        })
        .toList(growable: false);
    final maxAbs = visible.fold<double>(
      0,
      (max, value) => value.abs() > max ? value.abs() : max,
    );
    final sampleRate = propertyDouble(properties, 'sampleRate', 60);
    return OscilloscopeState(
      samples: visible,
      sampleRate: sampleRate,
      amplitudeScale: propertyDouble(
        properties,
        'amplitudeScale',
        maxAbs == 0 ? 1 : maxAbs,
      ),
      timeWindow: propertyDouble(
        properties,
        'timeWindow',
        sampleRate == 0 ? 0 : visible.length / sampleRate,
      ),
      updatedAt: DateTime.now(),
    );
  }

  List<RuntimeMeasurement> _latestWindow(List<RuntimeMeasurement> history) {
    if (history.length <= sampleWindow) return history;
    return history.sublist(history.length - sampleWindow);
  }

  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return const ValidationResult.valid();
  }
}
