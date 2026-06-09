import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../runtime_world.dart';

abstract class InteractiveObjectComponent extends PositionComponent {
  final Map<String, dynamic> objectData;
  final RuntimeWorld runtimeWorld;

  String get objectId =>
      objectData['objectId']?.toString() ?? objectData['id']?.toString() ?? '';

  InteractiveObjectComponent(this.objectData, this.runtimeWorld)
    : super(size: Vector2(180, 64), anchor: Anchor.center);

  Map<String, dynamic> get state =>
      runtimeWorld.objects.getObjectState(objectId)?.state ?? const {};

  bool get enabled => state['enabled'] == false ? false : true;
}

class RuntimeSliderComponent extends InteractiveObjectComponent
    with DragCallbacks, TapCallbacks {
  RuntimeSliderComponent(super.objectData, super.runtimeWorld);

  @override
  void onTapDown(TapDownEvent event) {
    _setFromLocalX(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _setFromLocalX(event.localEndPosition.x);
  }

  void _setFromLocalX(double localX) {
    if (!enabled) return;
    final min = _numState('min', 0);
    final max = _numState('max', 100);
    final step = _numState('step', 1);
    final trackStart = 16.0;
    final trackEnd = size.x - 16.0;
    final ratio = ((localX - trackStart) / (trackEnd - trackStart)).clamp(
      0.0,
      1.0,
    );
    final rawValue = min + ((max - min) * ratio);
    final stepped = step <= 0 ? rawValue : (rawValue / step).round() * step;
    final value = stepped.clamp(min, max);
    runtimeWorld.objectVariableAdapter.changeSlider(objectId, value);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = enabled ? Colors.blueGrey : Colors.grey;
    final value = _numState('value', 0);
    final min = _numState('min', 0);
    final max = _numState('max', 100);
    final ratio = max <= min ? 0.0 : ((value - min) / (max - min)).clamp(0, 1);
    final trackStart = Offset(16, size.y / 2);
    final trackEnd = Offset(size.x - 16, size.y / 2);
    final thumb = Offset(
      trackStart.dx + ((trackEnd.dx - trackStart.dx) * ratio),
      trackStart.dy,
    );

    canvas.drawLine(trackStart, trackEnd, paint..strokeWidth = 4);
    canvas.drawCircle(thumb, 10, Paint()..color = Colors.teal);
    _drawText(canvas, value.toStringAsFixed(0), Offset(16, 6));
  }

  double _numState(String key, num fallback) {
    final value = state[key];
    return value is num ? value.toDouble() : fallback.toDouble();
  }
}

class RuntimeToggleComponent extends InteractiveObjectComponent
    with TapCallbacks {
  RuntimeToggleComponent(super.objectData, super.runtimeWorld);

  @override
  void onTapDown(TapDownEvent event) {
    if (!enabled) return;
    final nextValue = state['value'] == true ? false : true;
    runtimeWorld.objectVariableAdapter.setToggle(objectId, nextValue);
  }

  @override
  void render(Canvas canvas) {
    final value = state['value'] == true;
    final rect = Rect.fromLTWH(0, 8, size.x, size.y - 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = value ? Colors.green : Colors.grey,
    );
    _drawText(
      canvas,
      value
          ? state['onLabel']?.toString() ?? 'ON'
          : state['offLabel']?.toString() ?? 'OFF',
      Offset(size.x / 2 - 18, size.y / 2 - 8),
      color: Colors.white,
    );
  }
}

class RuntimeButtonComponent extends InteractiveObjectComponent
    with TapCallbacks {
  RuntimeButtonComponent(super.objectData, super.runtimeWorld);

  @override
  void onTapDown(TapDownEvent event) {
    if (!enabled) return;
    runtimeWorld.objectVariableAdapter.pressButton(objectId);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _release();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _release();
  }

  void _release() {
    runtimeWorld.objectVariableAdapter.releaseButton(objectId);
  }

  @override
  void render(Canvas canvas) {
    final pressed = state['pressed'] == true;
    final rect = Rect.fromLTWH(0, 8, size.x, size.y - 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = pressed ? Colors.indigo : Colors.blue,
    );
    _drawText(
      canvas,
      state['label']?.toString() ?? 'START',
      Offset(18, size.y / 2 - 8),
      color: Colors.white,
    );
  }
}

void _drawText(
  Canvas canvas,
  String text,
  Offset offset, {
  Color color = Colors.black,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 14),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 150);
  painter.paint(canvas, offset);
}
