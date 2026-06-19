class AnimatedGraphProfile {
  final String graphType;
  final String enterAnimation;
  final String updateAnimation;
  final double animationDurationSeconds;
  final bool highlightsLatestData;

  const AnimatedGraphProfile({
    required this.graphType,
    required this.enterAnimation,
    required this.updateAnimation,
    this.animationDurationSeconds = 0.45,
    this.highlightsLatestData = true,
  });

  bool get isValid {
    return graphType.isNotEmpty &&
        enterAnimation.isNotEmpty &&
        updateAnimation.isNotEmpty &&
        animationDurationSeconds > 0 &&
        animationDurationSeconds <= 1.2;
  }
}
