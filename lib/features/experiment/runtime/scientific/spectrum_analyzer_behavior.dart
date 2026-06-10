import 'dart:math' as math;

import '../measurements/runtime_measurement_store.dart';
import '../models/runtime_object_state.dart';
import '../objects/behavior/runtime_object_behavior.dart';
import 'runtime_multi_binding.dart';
import 'scientific_value_reader.dart';
import 'spectrum_analyzer_state.dart';

class SpectrumAnalyzerBehavior extends PlaceholderRuntimeObjectBehavior {
  static const int defaultBins = 64;

  final RuntimeMeasurementStore? measurementStore;
  final Map<String, dynamic>? objectJson;

  SpectrumAnalyzerBehavior({this.measurementStore, this.objectJson});

  SpectrumAnalyzerState buildState() {
    final object = objectJson ?? const <String, dynamic>{};
    final properties = objectProperties(object);
    final binding = RuntimeMultiBinding.fromObjectJson(object);
    final variableId =
        binding.variableForRole('value') ?? binding.variableForRole('source');
    if (variableId == null || variableId.isEmpty || measurementStore == null) {
      return const SpectrumAnalyzerState.empty();
    }
    final history = measurementStore!.getMeasurements(variableId);
    if (history.length < 2) return const SpectrumAnalyzerState.empty();

    final sampleCount = propertyInt(
      properties,
      'bins',
      defaultBins,
    ).clamp(2, history.length);
    final samples = history
        .sublist(history.length - sampleCount)
        .map((measurement) {
          final field =
              properties['field']?.toString() ?? properties['axis']?.toString();
          return numericValue(measurement.value, field: field);
        })
        .toList(growable: false);
    final sampleRate = propertyDouble(properties, 'sampleRate', 60);
    final amplitudes = <double>[];
    final frequencies = <double>[];
    final bins = <int>[];
    final maxBin = samples.length ~/ 2;
    for (var k = 0; k < maxBin; k++) {
      var real = 0.0;
      var imaginary = 0.0;
      for (var n = 0; n < samples.length; n++) {
        final angle = 2 * math.pi * k * n / samples.length;
        real += samples[n] * math.cos(angle);
        imaginary -= samples[n] * math.sin(angle);
      }
      final amplitude =
          math.sqrt(real * real + imaginary * imaginary) / samples.length;
      bins.add(k);
      frequencies.add(sampleRate * k / samples.length);
      amplitudes.add(amplitude);
    }
    var peakFrequency = 0.0;
    var peakAmplitude = -1.0;
    for (var i = 0; i < amplitudes.length; i++) {
      if (amplitudes[i] > peakAmplitude) {
        peakAmplitude = amplitudes[i];
        peakFrequency = frequencies[i];
      }
    }
    return SpectrumAnalyzerState(
      bins: bins,
      amplitudes: amplitudes,
      frequencies: frequencies,
      peakFrequency: peakFrequency,
      updatedAt: DateTime.now(),
    );
  }

  @override
  ValidationResult validateState(RuntimeObjectState state) {
    return const ValidationResult.valid();
  }
}
