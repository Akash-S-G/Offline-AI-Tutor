import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/experiment/experience/engine/runtime_experience_engine.dart';
import 'package:offline_tutor_app/features/experiment/experience/models/runtime_experience.dart';
import 'package:offline_tutor_app/features/experiment/experience/workspace/lab_workspace_analytics.dart';
import 'package:offline_tutor_app/features/experiment/experience/workspace/runtime_lab_workspace.dart';
import 'package:offline_tutor_app/features/experiment/runtime/runtime_loader.dart';

void main() {
  testWidgets('landscape shows immersive lab workspace', (tester) async {
    final world = _world();
    final experience = RuntimeExperience.fromWorld(world);
    final engine = RuntimeExperienceEngine(eventBus: world.eventBus)
      ..load(experience);

    await tester.pumpWidget(
      _host(
        RuntimeLabWorkspace(
          world: world,
          experience: experience,
          engine: engine,
          onRecordObservation: world.recordObservation,
          onRun: world.start,
          onReset: world.stop,
          analytics: LabWorkspaceAnalytics(),
        ),
      ),
    );

    expect(find.text('Lab Test'), findsWidgets);
    expect(find.text('Readings'), findsNothing);
    expect(find.text('Run'), findsWidgets);

    engine.dispose();
    world.dispose();
  });

  testWidgets('instrument dock record action creates observation', (
    tester,
  ) async {
    final world = _world();
    final experience = RuntimeExperience.fromWorld(world);
    final engine = RuntimeExperienceEngine(eventBus: world.eventBus)
      ..load(experience);

    await tester.pumpWidget(
      _host(
        RuntimeLabWorkspace(
          world: world,
          experience: experience,
          engine: engine,
          onRecordObservation: world.recordObservation,
          onRun: world.start,
          onReset: world.stop,
          isRunning: true,
          analytics: LabWorkspaceAnalytics(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.playlist_add_check).first);
    await tester.pump();

    expect(world.observationStore.rowCount, 1);

    engine.dispose();
    world.dispose();
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 900, height: 500, child: child)),
  );
}

dynamic _world() {
  return RuntimeLoader.loadFromManifest({
    'metadata': {'title': 'Lab Test'},
    'scene': {
      'sceneId': 'lab_test',
      'name': 'Lab Test',
      'variables': [
        {'id': 'var_length', 'name': 'Length', 'type': 'number', 'value': 1},
      ],
      'objects': [
        {
          'id': 'control_length',
          'objectId': 'control_length',
          'type': 'slider',
          'objectType': 'slider',
          'state': {'label': 'Length', 'value': 1, 'min': 0, 'max': 5},
        },
      ],
      'rules': const [],
    },
  });
}
