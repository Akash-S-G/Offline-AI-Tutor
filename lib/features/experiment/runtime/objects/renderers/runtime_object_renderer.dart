import 'package:flutter/material.dart';

import '../../models/runtime_object_state.dart';

abstract class RuntimeObjectRenderer {
  void initialize();

  void update(RuntimeObjectState state);

  void render(Canvas canvas, Size size);

  DateTime? get lastRenderTime;

  String get rendererType;

  void dispose();
}

abstract class PlaceholderRuntimeObjectRenderer
    implements RuntimeObjectRenderer {
  RuntimeObjectState? latestState;
  int updateCount = 0;
  bool initialized = false;
  DateTime? _lastRenderTime;
  bool lastRenderSkipped = false;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  void update(RuntimeObjectState state) {
    latestState = state;
    updateCount++;
  }

  @override
  DateTime? get lastRenderTime => _lastRenderTime;

  @override
  String get rendererType => runtimeType.toString();

  @override
  void render(Canvas canvas, Size size) {
    if (latestState?.visible == false) {
      lastRenderSkipped = true;
      return;
    }
    lastRenderSkipped = false;
    _lastRenderTime = DateTime.now();
  }

  @protected
  void markRendered() {
    lastRenderSkipped = false;
    _lastRenderTime = DateTime.now();
  }

  @protected
  bool shouldSkipRender() {
    if (latestState?.visible == false) {
      lastRenderSkipped = true;
      return true;
    }
    return latestState == null;
  }

  @override
  void dispose() {
    initialized = false;
    latestState = null;
    _lastRenderTime = null;
    lastRenderSkipped = false;
  }
}
