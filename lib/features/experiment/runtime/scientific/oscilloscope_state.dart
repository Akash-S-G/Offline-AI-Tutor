class OscilloscopeState {
  final List<double> samples;
  final double sampleRate;
  final double amplitudeScale;
  final double timeWindow;
  final DateTime? updatedAt;

  const OscilloscopeState({
    required this.samples,
    required this.sampleRate,
    required this.amplitudeScale,
    required this.timeWindow,
    required this.updatedAt,
  });

  const OscilloscopeState.empty()
    : samples = const [],
      sampleRate = 0,
      amplitudeScale = 1,
      timeWindow = 0,
      updatedAt = null;

  int get sampleCount => samples.length;

  Map<String, dynamic> toObjectState() {
    return {
      'samples': samples,
      'sampleRate': sampleRate,
      'amplitudeScale': amplitudeScale,
      'timeWindow': timeWindow,
      'sampleCount': sampleCount,
    };
  }
}
