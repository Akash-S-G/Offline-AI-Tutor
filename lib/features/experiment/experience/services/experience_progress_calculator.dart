class ExperienceProgressCalculator {
  const ExperienceProgressCalculator();

  double calculate({required int completedSteps, required int totalSteps}) {
    if (totalSteps <= 0) return 100;
    return ((completedSteps / totalSteps) * 100).clamp(0, 100).toDouble();
  }
}
