class ExperimentCheckpoint {
  final String id;
  final String label;
  final bool completed;
  final DateTime? completedAt;

  const ExperimentCheckpoint({
    required this.id,
    required this.label,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'completed': completed,
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };
}
