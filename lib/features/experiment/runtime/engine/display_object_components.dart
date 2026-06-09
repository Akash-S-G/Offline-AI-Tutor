import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../graphs/line_graph_behavior.dart';
import '../graphs/line_graph_renderer.dart';
import '../models/runtime_object_layout.dart';
import '../observations/table_behavior.dart';
import '../observations/table_renderer.dart';
import '../runtime_event.dart';
import '../runtime_world.dart';

class RuntimeDisplayObjectComponent extends PositionComponent {
  final Map<String, dynamic> objectData;
  final RuntimeWorld runtimeWorld;

  String get objectId =>
      objectData['objectId']?.toString() ?? objectData['id']?.toString() ?? '';

  RuntimeDisplayObjectComponent(this.objectData, this.runtimeWorld)
    : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _syncLayout(fallbackIndex: 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final state = runtimeWorld.objects.getObjectState(objectId);
    if (state == null) return;
    _applyLayout(state.layout);
    _syncGraphState();
    _syncTableState(state.state);
    runtimeWorld.objectLifecycle.getRenderer(objectId)?.update(state);
  }

  @override
  void render(Canvas canvas) {
    final state = runtimeWorld.objects.getObjectState(objectId);
    if (state == null || !state.visible) return;
    final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
    renderer?.render(canvas, ui.Size(size.x, size.y));
    if (renderer is LineGraphRenderer) {
      _emitGraphEvent('GraphRendered', renderer.graphState.sampleCount);
    } else if (renderer is TableRenderer) {
      _emitTableEvent('TableRendered', renderer.tableState.rowCount);
    }
  }

  void _syncLayout({required int fallbackIndex}) {
    final state = runtimeWorld.objects.getObjectState(objectId);
    if (state != null) {
      _applyLayout(state.layout);
      return;
    }
    position = Vector2(120, 90 + fallbackIndex * 110);
    size = Vector2(180, 96);
  }

  void _applyLayout(RuntimeObjectLayout layout) {
    final hasExplicitPosition = layout.x != 0 || layout.y != 0;
    final fallbackIndex = runtimeWorld.objects.allObjects.indexWhere((object) {
      return object['objectId']?.toString() == objectId ||
          object['id']?.toString() == objectId;
    });
    final stackedIndex = fallbackIndex < 0 ? 0 : fallbackIndex;
    position = hasExplicitPosition
        ? Vector2(layout.x, layout.y)
        : Vector2(120, 90 + stackedIndex * 110);
    size = Vector2(layout.width, layout.height);
  }

  void _syncGraphState() {
    if (objectData['objectType']?.toString() != 'lineGraph') return;
    final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
    if (renderer is! LineGraphRenderer) return;
    final linkedVariableId = _linkedVariableId();
    final graphState = LineGraphBehavior(
      measurementStore: runtimeWorld.measurementStore,
    ).buildStateForVariable(linkedVariableId);
    renderer.updateGraphState(graphState);
    _emitGraphEvent('GraphUpdated', graphState.sampleCount);
  }

  void _syncTableState(Map<String, dynamic> currentState) {
    if (objectData['objectType']?.toString() != 'table') return;
    final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
    if (renderer is! TableRenderer) return;
    final tableState = TableBehavior(
      observationStore: runtimeWorld.observationStore,
    ).buildState();
    renderer.updateTableState(tableState);
    if (currentState['rowCount'] != tableState.rowCount) {
      final stateMap = tableState.toObjectState();
      for (final entry in stateMap.entries) {
        runtimeWorld.objects.updateObjectState(
          objectId,
          entry.key,
          entry.value,
        );
      }
    }
    _emitTableEvent('TableUpdated', tableState.rowCount);
  }

  String? _linkedVariableId() {
    final properties = Map<String, dynamic>.from(
      objectData['properties'] as Map? ?? const {},
    );
    final value =
        properties['linked_variable'] ??
        properties['linkedVariable'] ??
        properties['valueVariable'] ??
        objectData['linked_variable'] ??
        objectData['linkedVariable'] ??
        objectData['valueVariable'];
    return value?.toString();
  }

  void _emitGraphEvent(String message, int sampleCount) {
    runtimeWorld.eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'objectId': objectId,
          'objectType': 'lineGraph',
          'linkedVariableId': _linkedVariableId(),
          'sampleCount': sampleCount,
        },
      ),
    );
  }

  void _emitTableEvent(String message, int rowCount) {
    runtimeWorld.eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'objectId': objectId,
          'objectType': 'table',
          'rowCount': rowCount,
        },
      ),
    );
  }
}
