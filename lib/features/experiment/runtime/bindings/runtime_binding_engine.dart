import 'dart:async';

import '../object_registry.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../runtime_variable_events.dart';
import '../variable_store.dart';
import 'runtime_binding.dart';
import 'runtime_binding_events.dart';
import 'runtime_binding_registry.dart';

class RuntimeBindingEngine {
  final VariableStore variables;
  final ObjectRegistry objects;
  final RuntimeBindingRegistry registry;
  final RuntimeEventBus eventBus;

  StreamSubscription<RuntimeEvent>? _subscription;
  int _bindingSequence = 0;

  RuntimeBindingEngine({
    required this.variables,
    required this.objects,
    required this.registry,
    required this.eventBus,
  });

  void initialize(List<Map<String, dynamic>> objectsJson) {
    discoverBindings(objectsJson);
    _subscription?.cancel();
    _subscription = eventBus.stream.listen(_handleRuntimeEvent);
  }

  void discoverBindings(List<Map<String, dynamic>> objectsJson) {
    registry.clear();
    for (final objectJson in objectsJson) {
      final objectId =
          objectJson['objectId']?.toString() ?? objectJson['id']?.toString();
      if (objectId == null || objectId.isEmpty) continue;
      final objectType =
          objectJson['objectType']?.toString() ??
          objectJson['type']?.toString() ??
          '';
      final properties = Map<String, dynamic>.from(
        objectJson['properties'] as Map? ?? const {},
      );

      for (final entry in properties.entries) {
        final variableId = entry.value?.toString();
        if (variableId == null || variableId.isEmpty) continue;
        final objectProperty = _objectPropertyForBindingKey(entry.key);
        if (objectProperty == null) continue;

        final binding = RuntimeBinding(
          bindingId: 'binding_${++_bindingSequence}',
          variableId: variableId,
          objectId: objectId,
          objectProperty: objectProperty,
          direction: _bindingDirectionForObjectType(objectType),
          active: variables.containsVariable(variableId),
          createdAt: DateTime.now(),
        );
        registry.registerBinding(binding);
        _emitBindingEvent(
          RuntimeBindingEvent.fromBinding(
            type: RuntimeBindingEventType.bindingRegistered,
            binding: binding,
          ),
        );

        if (!variables.containsVariable(variableId)) {
          _emitBindingEvent(
            RuntimeBindingEvent.fromBinding(
              type: RuntimeBindingEventType.bindingFailed,
              binding: binding,
              reason: 'Variable not found for $objectType object.',
            ),
          );
        } else if (objects.getObjectState(objectId) == null) {
          _emitBindingEvent(
            RuntimeBindingEvent.fromBinding(
              type: RuntimeBindingEventType.bindingFailed,
              binding: binding,
              reason: 'Object state not found.',
            ),
          );
        } else {
          _resolveBinding(binding, variables.getValue(variableId));
        }
      }
    }
  }

  void _handleRuntimeEvent(RuntimeEvent event) {
    if (event.message != 'VariableUpdated') return;
    if (event.metadata?['variableEventType'] !=
        RuntimeVariableEventType.variableUpdated.name) {
      return;
    }
    final variableId = event.metadata?['variableId']?.toString();
    if (variableId == null || variableId.isEmpty) return;
    final newValue = event.metadata?['newValue'];
    for (final binding in registry.getBindingsForVariable(variableId)) {
      if (!binding.active) {
        _emitBindingEvent(
          RuntimeBindingEvent.fromBinding(
            type: RuntimeBindingEventType.bindingFailed,
            binding: binding,
            newValue: newValue,
            reason: 'Binding is inactive.',
          ),
        );
        continue;
      }
      if (!binding.allowsVariableToObject) continue;
      _resolveBinding(binding, newValue);
    }
  }

  void _resolveBinding(RuntimeBinding binding, dynamic newValue) {
    final objectState = objects.getObjectState(binding.objectId);
    if (objectState == null) {
      _emitBindingEvent(
        RuntimeBindingEvent.fromBinding(
          type: RuntimeBindingEventType.bindingFailed,
          binding: binding,
          newValue: newValue,
          reason: 'Object state not found.',
        ),
      );
      return;
    }

    final oldValue = objectState.state[binding.objectProperty];
    objects.updateObjectState(
      binding.objectId,
      binding.objectProperty,
      newValue,
    );

    _emitBindingEvent(
      RuntimeBindingEvent.fromBinding(
        type: RuntimeBindingEventType.bindingResolved,
        binding: binding,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
    _emitBindingEvent(
      RuntimeBindingEvent.fromBinding(
        type: RuntimeBindingEventType.objectUpdatedFromBinding,
        binding: binding,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
  }

  void _emitBindingEvent(RuntimeBindingEvent event) {
    eventBus.emit(event.toRuntimeEvent());
  }

  String? _objectPropertyForBindingKey(String key) {
    const propertyMap = {
      'variableId': 'value',
      'valueVariable': 'value',
      'sourceVariable': 'source',
      'boundVariable': 'value',
      'linkedVariable': 'value',
      'linked_variable': 'value',
    };
    final mapped = propertyMap[key];
    if (mapped != null) return mapped;
    if (key.endsWith('_var') && key.length > 4) {
      return key.substring(0, key.length - 4);
    }
    return null;
  }

  BindingDirection _bindingDirectionForObjectType(String objectType) {
    switch (objectType) {
      case 'slider':
      case 'toggle':
        return BindingDirection.bidirectional;
      case 'button':
        return BindingDirection.objectToVariable;
      default:
        return BindingDirection.variableToObject;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
