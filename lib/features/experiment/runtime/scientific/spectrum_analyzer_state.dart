class SpectrumAnalyzerState {
  final List<int> bins;
  final List<double> amplitudes;
  final List<double> frequencies;
  final double peakFrequency;
  final DateTime? updatedAt;

  const SpectrumAnalyzerState({
    required this.bins,
    required this.amplitudes,
    required this.frequencies,
    required this.peakFrequency,
    required this.updatedAt,
  });

  const SpectrumAnalyzerState.empty()
    : bins = const [],
      amplitudes = const [],
      frequencies = const [],
      peakFrequency = 0,
      updatedAt = null;

  int get binCount => bins.length;

  Map<String, dynamic> toObjectState() {
    return {
      'bins': bins,
      'amplitudes': amplitudes,
      'frequencies': frequencies,
      'peakFrequency': peakFrequency,
      'binCount': binCount,
    };
  }
}
