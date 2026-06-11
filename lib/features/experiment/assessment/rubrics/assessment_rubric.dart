class AssessmentRubricCriterion {
  final String id;
  final String label;
  final double weight;

  const AssessmentRubricCriterion({
    required this.id,
    required this.label,
    required this.weight,
  });

  factory AssessmentRubricCriterion.fromJson(Map<String, dynamic> json) {
    return AssessmentRubricCriterion(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['id']?.toString() ?? '',
      weight: json['weight'] is num
          ? (json['weight'] as num).toDouble()
          : double.tryParse(json['weight']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'weight': weight};
}

class AssessmentRubric {
  final List<AssessmentRubricCriterion> criteria;

  const AssessmentRubric({this.criteria = const []});

  factory AssessmentRubric.fromJson(Map<String, dynamic> json) {
    return AssessmentRubric(
      criteria: (json['criteria'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AssessmentRubricCriterion.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }

  factory AssessmentRubric.defaultRubric() {
    return const AssessmentRubric(
      criteria: [
        AssessmentRubricCriterion(
          id: 'observation_quality',
          label: 'Observation Quality',
          weight: 30,
        ),
        AssessmentRubricCriterion(
          id: 'trial_completion',
          label: 'Trial Completion',
          weight: 30,
        ),
        AssessmentRubricCriterion(
          id: 'question_accuracy',
          label: 'Question Accuracy',
          weight: 40,
        ),
      ],
    );
  }

  double normalizedWeight(String id) {
    final total = criteria.fold<double>(0, (sum, item) => sum + item.weight);
    if (total <= 0) return 0;
    final index = criteria.indexWhere((item) => item.id == id);
    return (index < 0 ? 0 : criteria[index].weight) / total;
  }

  Map<String, dynamic> toJson() {
    return {'criteria': criteria.map((item) => item.toJson()).toList()};
  }
}
