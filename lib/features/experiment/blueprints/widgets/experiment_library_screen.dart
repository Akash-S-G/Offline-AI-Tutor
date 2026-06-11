import 'package:flutter/material.dart';

import '../models/experiment_blueprint.dart';
import '../registry/built_in_blueprints.dart';
import 'experiment_detail_screen.dart';

class ExperimentLibraryScreen extends StatelessWidget {
  final List<ExperimentBlueprint> blueprints;
  final ValueChanged<ExperimentBlueprint>? onStart;

  ExperimentLibraryScreen({
    super.key,
    List<ExperimentBlueprint>? blueprints,
    this.onStart,
  }) : blueprints = blueprints ?? BuiltInBlueprints.all();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experiment Library')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: blueprints.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final blueprint = blueprints[index];
          return Card(
            child: ListTile(
              title: Text(blueprint.name),
              subtitle: Text(
                '${blueprint.subject} | ${blueprint.grade} | ${blueprint.estimatedTime}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExperimentDetailScreen(
                      blueprint: blueprint,
                      onStart: onStart,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
