// ignore_for_file: avoid_print

import 'dart:async';
import '../engine/simulation_playground_engine.dart';

class PlaygroundValidator {
  Future<void> validate() async {
    print('--------------------------------------------------');
    print('PLAYGROUND CORE VALIDATION');
    print('--------------------------------------------------');

    final engine = SimulationPlaygroundEngine();
    
    // Subscribe to engine events
    final subscription = engine.eventStream.listen((event) {
      print('  -> Playground Event: ${event.eventType.name} Payload: ${event.payload}');
    });

    await engine.initialize();

    final demoScene = {
      'sceneId': 'demo_123',
      'name': 'Pendulum Demo',
      'description': 'A simple demo scene',
      'objects': [
        {
          'objectId': 'ball_1',
          'objectType': 'sphere',
          'name': 'Bob',
          'properties': {'mass': 5.0},
          'state': {'x': 0, 'y': 10}
        }
      ],
      'variables': [
        {
          'name': 'gravity',
          'type': 'float',
          'value': 9.8,
          'minValue': 1.0,
          'maxValue': 20.0,
          'unit': 'm/s^2'
        }
      ],
      'rules': [
        {
          'ruleId': 'rule_1',
          'name': 'Update Velocity',
          'trigger': 'variableChanged',
          'condition': {},
          'action': {},
          'enabled': true
        }
      ]
    };

    await engine.loadScene(demoScene);

    await engine.start();
    await Future.delayed(const Duration(milliseconds: 100));

    print('=== Modifying Variables ===');
    engine.updateVariable('gravity', 1.62); // Moon gravity
    
    print('=== Updating Objects ===');
    engine.updateObjectState('ball_1', {'x': 5, 'y': 8});

    await Future.delayed(const Duration(milliseconds: 100));

    await engine.pause();
    await Future.delayed(const Duration(milliseconds: 100));

    await engine.resume();
    await Future.delayed(const Duration(milliseconds: 100));

    await engine.stop();
    await Future.delayed(const Duration(milliseconds: 100));

    await subscription.cancel();
    await engine.dispose();

    print('--------------------------------------------------');
  }
}
