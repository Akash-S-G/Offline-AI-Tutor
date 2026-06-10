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
import '../scatter/scatter_plot_behavior.dart';
import '../scatter/scatter_plot_renderer.dart';
import '../scientific/bar_chart_behavior.dart';
import '../scientific/bar_chart_renderer.dart';
import '../scientific/oscilloscope_behavior.dart';
import '../scientific/oscilloscope_renderer.dart';
import '../scientific/spectrum_analyzer_behavior.dart';
import '../scientific/spectrum_analyzer_renderer.dart';
import '../scientific/vector_visualizer_behavior.dart';
import '../scientific/vector_visualizer_renderer.dart';

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
    _syncScatterState(state.state);
    _syncTableState(state.state);
    _syncScientificState(state.state);
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
    } else if (renderer is ScatterPlotRenderer) {
      _emitScatterEvent(
        'ScatterPlotRendered',
        renderer.scatterState.pointCount,
      );
    } else if (renderer is TableRenderer) {
      _emitTableEvent('TableRendered', renderer.tableState.rowCount);
    } else if (renderer is VectorVisualizerRenderer) {
      _emitScientificEvent('ScientificObjectRendered', 'vectorVisualizer', {
        'magnitude': renderer.vectorState.magnitude,
      });
    } else if (renderer is OscilloscopeRenderer) {
      _emitScientificEvent('ScientificObjectRendered', 'oscilloscope', {
        'samples': renderer.oscilloscopeState.sampleCount,
      });
    } else if (renderer is SpectrumAnalyzerRenderer) {
      _emitScientificEvent('ScientificObjectRendered', 'spectrumAnalyzer', {
        'bins': renderer.spectrumState.binCount,
      });
    } else if (renderer is BarChartRenderer) {
      _emitScientificEvent('ScientificObjectRendered', 'barChart', {
        'bars': renderer.barChartState.barCount,
      });
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

  void _syncScatterState(Map<String, dynamic> currentState) {
    if (objectData['objectType']?.toString() != 'scatterPlot') return;
    final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
    if (renderer is! ScatterPlotRenderer) return;
    final variables = _scatterVariableIds();
    final scatterState = ScatterPlotBehavior(
      measurementStore: runtimeWorld.measurementStore,
    ).buildState(xVariableId: variables.$1, yVariableId: variables.$2);
    renderer.updateScatterState(scatterState);
    if (currentState['pointCount'] != scatterState.pointCount) {
      runtimeWorld.objects.updateObjectState(
        objectId,
        'pointCount',
        scatterState.pointCount,
      );
      runtimeWorld.objects.updateObjectState(
        objectId,
        'minX',
        scatterState.minX,
      );
      runtimeWorld.objects.updateObjectState(
        objectId,
        'maxX',
        scatterState.maxX,
      );
      runtimeWorld.objects.updateObjectState(
        objectId,
        'minY',
        scatterState.minY,
      );
      runtimeWorld.objects.updateObjectState(
        objectId,
        'maxY',
        scatterState.maxY,
      );
    }
    _emitScatterEvent('ScatterPlotUpdated', scatterState.pointCount);
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

  void _syncScientificState(Map<String, dynamic> currentState) {
    final type = objectData['objectType']?.toString();
    switch (type) {
      case 'vectorVisualizer':
        final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
        if (renderer is! VectorVisualizerRenderer) return;
        final vectorState = VectorVisualizerBehavior(
          variables: runtimeWorld.variables,
          objectJson: objectData,
        ).buildState();
        renderer.updateVectorState(vectorState);
        _updateStateMap(vectorState.toObjectState(), currentState);
        _emitScientificEvent('VectorVisualizerUpdated', type!, {
          'magnitude': vectorState.magnitude,
        });
        break;
      case 'oscilloscope':
        final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
        if (renderer is! OscilloscopeRenderer) return;
        final waveformState = OscilloscopeBehavior(
          measurementStore: runtimeWorld.measurementStore,
          objectJson: objectData,
        ).buildState();
        renderer.updateOscilloscopeState(waveformState);
        _updateStateMap(waveformState.toObjectState(), currentState);
        _emitScientificEvent('OscilloscopeUpdated', type!, {
          'samples': waveformState.sampleCount,
        });
        break;
      case 'spectrumAnalyzer':
        final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
        if (renderer is! SpectrumAnalyzerRenderer) return;
        final spectrumState = SpectrumAnalyzerBehavior(
          measurementStore: runtimeWorld.measurementStore,
          objectJson: objectData,
        ).buildState();
        renderer.updateSpectrumState(spectrumState);
        _updateStateMap(spectrumState.toObjectState(), currentState);
        _emitScientificEvent('SpectrumAnalyzerUpdated', type!, {
          'bins': spectrumState.binCount,
          'peakFrequency': spectrumState.peakFrequency,
        });
        break;
      case 'barChart':
        final renderer = runtimeWorld.objectLifecycle.getRenderer(objectId);
        if (renderer is! BarChartRenderer) return;
        final barState = BarChartBehavior(
          variables: runtimeWorld.variables,
          objectJson: objectData,
        ).buildState();
        renderer.updateBarChartState(barState);
        _updateStateMap(barState.toObjectState(), currentState);
        _emitScientificEvent('BarChartUpdated', type!, {
          'bars': barState.barCount,
        });
        break;
    }
  }

  void _updateStateMap(
    Map<String, dynamic> nextState,
    Map<String, dynamic> currentState,
  ) {
    for (final entry in nextState.entries) {
      if (currentState[entry.key] != entry.value) {
        runtimeWorld.objects.updateObjectState(
          objectId,
          entry.key,
          entry.value,
        );
      }
    }
  }

  String? _linkedVariableId() {
    final properties = Map<String, dynamic>.from(
      objectData['properties'] as Map? ?? const {},
    );
    final value =
        properties['linked_variable'] ??
        properties['linkedVariable'] ??
        properties['variableId'] ??
        properties['valueVariable'] ??
        objectData['linked_variable'] ??
        objectData['linkedVariable'] ??
        objectData['variableId'] ??
        objectData['valueVariable'];
    return value?.toString();
  }

  (String?, String?) _scatterVariableIds() {
    final properties = Map<String, dynamic>.from(
      objectData['properties'] as Map? ?? const {},
    );
    final xValue =
        properties['xVariable'] ??
        properties['x_variable'] ??
        properties['xVariableId'] ??
        objectData['xVariable'] ??
        objectData['x_variable'] ??
        objectData['xVariableId'];
    final yValue =
        properties['yVariable'] ??
        properties['y_variable'] ??
        properties['yVariableId'] ??
        objectData['yVariable'] ??
        objectData['y_variable'] ??
        objectData['yVariableId'];
    return (xValue?.toString(), yValue?.toString());
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

  void _emitScatterEvent(String message, int pointCount) {
    final variables = _scatterVariableIds();
    runtimeWorld.eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'objectId': objectId,
          'objectType': 'scatterPlot',
          'xVariableId': variables.$1,
          'yVariableId': variables.$2,
          'pointCount': pointCount,
        },
      ),
    );
  }

  void _emitScientificEvent(
    String message,
    String objectType,
    Map<String, dynamic> metadata,
  ) {
    runtimeWorld.eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {'objectId': objectId, 'objectType': objectType, ...metadata},
      ),
    );
  }
}
