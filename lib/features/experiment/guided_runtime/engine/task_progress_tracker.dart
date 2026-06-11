class TaskProgressTracker {
  double progress({required int completedTasks, required int totalTasks}) {
    if (totalTasks <= 0) return 0;
    return (completedTasks / totalTasks).clamp(0, 1).toDouble();
  }
}
