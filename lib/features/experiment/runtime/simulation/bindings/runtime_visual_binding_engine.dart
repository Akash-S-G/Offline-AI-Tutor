import 'dart:async';

import '../../runtime_event.dart';
import '../../runtime_event_bus.dart';
import '../canvas/runtime_simulation_canvas.dart';
import 'runtime_visual_binding.dart';

class RuntimeVisualBindingEngine {
  RuntimeVisualBindingEngine({
    required RuntimeEventBus eventBus,
    required RuntimeSimulationCanvas canvas,
  }) : _eventBus = eventBus,
       _canvas = canvas;

  final RuntimeEventBus _eventBus;
  final RuntimeSimulationCanvas _canvas;
  final List<RuntimeVisualBinding> _bindings = [];
  StreamSubscription? _subscription;

  List<RuntimeVisualBinding> get bindings => List.unmodifiable(_bindings);
  int get bindingCount => _bindings.length;

  void addBindings(List<RuntimeVisualBinding> bindings) {
    _bindings.addAll(bindings);
    for (final binding in bindings) {
      _emit('VisualBindingRegistered', metadata: binding.toJson());
    }
  }

  void initialize(List<Map<String, dynamic>> bindingsJson) {
    _bindings
      ..clear()
      ..addAll(bindingsJson.map(RuntimeVisualBinding.fromJson));
    _subscription?.cancel();
    _subscription = _eventBus.stream.listen(_handleEvent);
    for (final binding in _bindings) {
      _emit('VisualBindingRegistered', metadata: binding.toJson());
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleEvent(RuntimeEvent event) {
    if (event.message != 'VariableUpdated' &&
        event.message != 'VariableChanged') {
      return;
    }
    final variableId = event.metadata?['variableId']?.toString();
    if (variableId == null || variableId.isEmpty) return;
    final value = event.metadata?['newValue'] ?? event.metadata?['value'];
    for (final binding in _bindings.where((item) {
      return item.active && item.variableId == variableId;
    })) {
      if (!binding.supported) {
        _emitFailure(
          binding,
          'Unsupported visual property: ${binding.property}',
        );
        continue;
      }
      final resolved = _canvas.updateActorProperty(
        binding.actorId,
        binding.property,
        _applyTransform(value, binding.transform),
      );
      if (resolved) {
        _emit(
          'VisualBindingResolved',
          metadata: {...binding.toJson(), 'newValue': value},
        );
      } else {
        _emitFailure(binding, 'Missing actor: ${binding.actorId}');
      }
    }
  }

  dynamic _applyTransform(dynamic value, Map<String, dynamic> transform) {
    if (transform.isEmpty) return value;
    if (value is Map && transform['field'] != null) {
      value = value[transform['field']];
    }
    final numeric = _double(value);
    if (numeric == null) return value;
    final min = _double(transform['min']) ?? 0;
    final max = _double(transform['max']) ?? 100;
    final outMin = _double(transform['outputMin']) ?? 0;
    final outMax = _double(transform['outputMax']) ?? 1;
    final normalized = max <= min
        ? 0
        : ((numeric - min) / (max - min)).clamp(0, 1);
    return outMin + (outMax - outMin) * normalized;
  }

  double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _emitFailure(RuntimeVisualBinding binding, String reason) {
    _emit(
      'VisualBindingFailed',
      metadata: {...binding.toJson(), 'reason': reason},
    );
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    _eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: metadata,
      ),
    );
  }
}
