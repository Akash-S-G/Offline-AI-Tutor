import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../runtime_world.dart';

class BuilderObjectComponent extends PositionComponent {
  final Map<String, dynamic> objectData;
  final RuntimeWorld world;

  BuilderObjectComponent(this.objectData, this.world) : super(size: Vector2.all(50), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Basic initialization based on objectType
    position = Vector2(100, 100);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Sync state from variable store if linked
    if (objectData.containsKey('properties')) {
      final props = objectData['properties'] as Map<String, dynamic>;
      
      if (props.containsKey('linked_variable')) {
        final varId = props['linked_variable'];
        final val = world.variables.get(varId);
        
        if (val is num) {
          if (objectData['objectType'] == 'pendulumSimulation') {
            angle = (val.toDouble() * 3.14159) / 180.0;
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final type = objectData['objectType'];
    final paint = Paint()..color = Colors.blueAccent;

    if (type == 'pendulumSimulation') {
      canvas.drawLine(Offset.zero, const Offset(0, 100), paint..strokeWidth = 2);
      canvas.drawCircle(const Offset(0, 100), 20, paint..color = Colors.red);
    } else if (type == 'plantSimulation') {
      final water = world.variables.get('var_water') ?? 50.0;
      final sun = world.variables.get('var_sunlight') ?? 50.0;
      final growth = ((water + sun) / 200.0) * 100.0; // dummy logic
      canvas.drawRect(Rect.fromLTWH(-10, -growth.toDouble(), 20, growth.toDouble()), paint..color = Colors.green);
    } else if (type == 'gauge' || type == 'interactiveDiagram') {
      canvas.drawCircle(Offset.zero, 40, paint..color = Colors.orange);
    } else {
      canvas.drawRect(Rect.fromLTWH(-25, -25, 50, 50), paint);
    }
  }
}

class PhysicsBall extends BodyComponent {
  final Vector2 initialPosition;
  
  PhysicsBall({required this.initialPosition});

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 2.0;
    final fixtureDef = FixtureDef(shape, restitution: 0.8, density: 1.0, friction: 0.4);
    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 2.0, Paint()..color = Colors.redAccent);
  }
}
