import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/experiment/experience/engine/runtime_experience_engine.dart';
import 'package:offline_tutor_app/features/experiment/experience/models/runtime_experience.dart';
import 'package:offline_tutor_app/features/experiment/experience/workspace/lab_workspace_analytics.dart';
import 'package:offline_tutor_app/features/experiment/experience/workspace/runtime_lab_workspace.dart';
import 'package:offline_tutor_app/features/experiment/runtime/runtime_loader.dart';

void main() {
  testWidgets('student mode starts immersive with collapsed lab sheet', (
    tester,
  ) async {
    final world = _world();
    final experience = RuntimeExperience.fromWorld(world);
    final analytics = LabWorkspaceAnalytics();
    final engine = RuntimeExperienceEngine(eventBus: world.eventBus)
      ..load(experience);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 500,
            child: RuntimeLabWorkspace(
              world: world,
              experience: experience,
              engine: engine,
              onRecordObservation: world.recordObservation,
              onRun: world.start,
              onReset: world.stop,
              analytics: analytics,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Readings'), findsNothing);
    expect(find.byIcon(Icons.fullscreen), findsNothing);
    expect(analytics.visibleCanvasPercentage, greaterThanOrEqualTo(0.8));

    engine.dispose();
    world.dispose();
  });
}

dynamic _world() {
  return RuntimeLoader.loadFromManifest({
    'metadata': {'title': 'Focus Test'},
    'scene': {
      'sceneId': 'focus_test',
      'name': 'Focus Test',
      'variables': [
        {'id': 'var_a', 'name': 'A', 'type': 'number', 'value': 1},
      ],
      'objects': const [],
      'rules': const [],
    },
  });
}
