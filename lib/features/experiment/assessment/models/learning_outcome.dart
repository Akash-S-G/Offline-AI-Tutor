class LearningOutcome {
  final String id;
  final String description;
  final String skill;
  final double weight;

  const LearningOutcome({
    required this.id,
    required this.description,
    required this.skill,
    this.weight = 1,
  });

  factory LearningOutcome.fromJson(Map<String, dynamic> json) {
    return LearningOutcome(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      skill: json['skill']?.toString() ?? 'scientific_reasoning',
      weight: json['weight'] is num
          ? (json['weight'] as num).toDouble()
          : double.tryParse(json['weight']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'skill': skill,
      'weight': weight,
    };
  }
}
