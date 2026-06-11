import 'package:flutter/material.dart';

import '../models/experiment_blueprint.dart';

class ExperimentDetailScreen extends StatelessWidget {
  final ExperimentBlueprint blueprint;
  final ValueChanged<ExperimentBlueprint>? onStart;

  const ExperimentDetailScreen({
    super.key,
    required this.blueprint,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(blueprint.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            blueprint.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Objectives',
            children: blueprint.objectives
                .map(
                  (objective) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(objective.title),
                    subtitle: Text(objective.description),
                  ),
                )
                .toList(),
          ),
          _Section(
            title: 'Parameters',
            children: blueprint.parameters
                .map(
                  (parameter) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune),
                    title: Text(parameter.displayName),
                    subtitle: Text(
                      '${parameter.minValue} - ${parameter.maxValue} ${parameter.unit}',
                    ),
                  ),
                )
                .toList(),
          ),
          _Section(
            title: 'Details',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${blueprint.subject} | ${blueprint.topic}'),
                subtitle: Text(
                  '${blueprint.grade} | ${blueprint.difficulty} | ${blueprint.estimatedTime}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onStart?.call(blueprint),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Experiment'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}
