import 'package:flutter/material.dart';

import '../validation/builder_validator.dart';

enum LaunchReadinessLevel { ready, warning, error }

class LaunchReadiness {
  final LaunchReadinessLevel level;
  final String message;

  const LaunchReadiness({required this.level, required this.message});
}

class LaunchReadinessCard extends StatelessWidget {
  final BuilderValidationResult validation;

  const LaunchReadinessCard({super.key, required this.validation});

  static LaunchReadiness fromValidation(BuilderValidationResult validation) {
    if (validation.isValid) {
      return const LaunchReadiness(
        level: LaunchReadinessLevel.ready,
        message: 'Ready To Launch',
      );
    }
    final missingBinding = validation.errors.any(
      (error) =>
          error.toLowerCase().contains('missing') ||
          error.toLowerCase().contains('references'),
    );
    return LaunchReadiness(
      level: missingBinding
          ? LaunchReadinessLevel.warning
          : LaunchReadinessLevel.error,
      message: missingBinding ? 'Missing Variable Bindings' : 'Cannot Launch',
    );
  }

  @override
  Widget build(BuildContext context) {
    final readiness = fromValidation(validation);
    final color = switch (readiness.level) {
      LaunchReadinessLevel.ready => Colors.green,
      LaunchReadinessLevel.warning => Colors.orange,
      LaunchReadinessLevel.error => Colors.red,
    };
    final icon = switch (readiness.level) {
      LaunchReadinessLevel.ready => Icons.check_circle,
      LaunchReadinessLevel.warning => Icons.warning_amber_rounded,
      LaunchReadinessLevel.error => Icons.cancel,
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(readiness.message),
        subtitle: validation.errors.isEmpty
            ? const Text('Validation passed')
            : Text('${validation.errors.length} issue(s) found'),
      ),
    );
  }
}
