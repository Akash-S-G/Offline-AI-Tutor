class ExperimentObjective {
  final String title;
  final String description;
  final bool required;

  const ExperimentObjective({
    required this.title,
    required this.description,
    this.required = true,
  });

  factory ExperimentObjective.fromJson(Map<String, dynamic> json) {
    return ExperimentObjective(
      title: json['title']?.toString() ?? 'Objective',
      description: json['description']?.toString() ?? '',
      required: json['required'] is bool ? json['required'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'required': required};
  }
}
