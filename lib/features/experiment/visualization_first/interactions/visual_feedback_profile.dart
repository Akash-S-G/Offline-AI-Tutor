class VisualFeedbackProfile {
  final String trigger;
  final String targetCategory;
  final List<String> effects;
  final double durationSeconds;

  const VisualFeedbackProfile({
    required this.trigger,
    required this.targetCategory,
    required this.effects,
    this.durationSeconds = 0.6,
  });

  bool get isMobileSafe {
    return effects.length <= 3 && durationSeconds <= 1.2;
  }
}
