enum TrialTrend { increasing, decreasing, stable, oscillating, unknown }

class TrendDetector {
  const TrendDetector();

  TrialTrend detect(List<num> values) {
    if (values.length < 2) return TrialTrend.unknown;
    var increases = 0;
    var decreases = 0;
    var stable = 0;
    for (var i = 1; i < values.length; i++) {
      final delta = values[i] - values[i - 1];
      if (delta > 0) {
        increases++;
      } else if (delta < 0) {
        decreases++;
      } else {
        stable++;
      }
    }
    if (stable == values.length - 1) return TrialTrend.stable;
    if (increases > 0 && decreases == 0) return TrialTrend.increasing;
    if (decreases > 0 && increases == 0) return TrialTrend.decreasing;
    return TrialTrend.oscillating;
  }

  String describe(String label, TrialTrend trend) {
    switch (trend) {
      case TrialTrend.increasing:
        return '$label increased across trials.';
      case TrialTrend.decreasing:
        return '$label decreased across trials.';
      case TrialTrend.stable:
        return '$label stayed stable across trials.';
      case TrialTrend.oscillating:
        return '$label changed up and down across trials.';
      case TrialTrend.unknown:
        return 'More trial data is needed for $label.';
    }
  }
}
