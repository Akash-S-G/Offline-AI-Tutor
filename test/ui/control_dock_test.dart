import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/experiment/experience/workspace/floating_control_dock.dart';
import 'package:offline_tutor_app/features/experiment/runtime/runtime_loader.dart';

void main() {
  testWidgets('control dock updates slider state', (tester) async {
    final world = RuntimeLoader.loadFromManifest({
      'metadata': {'title': 'Control Dock Test'},
      'scene': {
        'sceneId': 'control_dock_test',
        'name': 'Control Dock Test',
        'variables': const [],
        'objects': [
          {
            'id': 'slider_1',
            'objectId': 'slider_1',
            'type': 'slider',
            'objectType': 'slider',
            'state': {'label': 'Length', 'value': 1, 'min': 0, 'max': 10},
          },
        ],
        'rules': const [],
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingControlDock(
                objectRegistry: world.objects,
                eventBus: world.eventBus,
                onRun: () {},
                onReset: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(7);
    await tester.pump();

    expect(world.objects.getObjectState('slider_1')?.state['value'], 7);

    world.dispose();
  });
}
