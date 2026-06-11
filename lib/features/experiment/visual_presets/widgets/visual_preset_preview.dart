import 'package:flutter/material.dart';

import '../models/visual_preset_scene.dart';

class VisualPresetPreview extends StatelessWidget {
  final VisualPresetScene? scene;

  const VisualPresetPreview({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    final scene = this.scene;
    if (scene == null) {
      return const Center(child: Text('No visual preset selected'));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              scene.presetId,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Actors: ${scene.actors.length}'),
            Text('Bindings: ${scene.bindings.length}'),
            Text('Animations: ${scene.animations.length}'),
          ],
        ),
      ),
    );
  }
}
