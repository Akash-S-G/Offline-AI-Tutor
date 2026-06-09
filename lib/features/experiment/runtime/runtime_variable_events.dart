import 'models/runtime_variable.dart';
import 'runtime_event.dart';

enum RuntimeVariableEventType {
  variableRegistered,
  variableUpdated,
  variableRemoved,
  variableInitialized,
}

class RuntimeVariableEvent {
  final RuntimeVariableEventType type;
  final String variableId;
  final String variableName;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  const RuntimeVariableEvent({
    required this.type,
    required this.variableId,
    required this.variableName,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });

  RuntimeEvent toRuntimeEvent({Map<String, dynamic>? extraMetadata}) {
    return RuntimeEvent(
      id: '${type.name}_${timestamp.microsecondsSinceEpoch}',
      timestamp: timestamp,
      type: RuntimeEventType.custom,
      message: message,
      metadata: {
        'variableEventType': type.name,
        'variableId': variableId,
        'variableName': variableName,
        'oldValue': oldValue,
        'newValue': newValue,
        ...?extraMetadata,
      },
    );
  }

  String get message {
    switch (type) {
      case RuntimeVariableEventType.variableRegistered:
        return 'VariableRegistered';
      case RuntimeVariableEventType.variableUpdated:
        return 'VariableUpdated';
      case RuntimeVariableEventType.variableRemoved:
        return 'VariableRemoved';
      case RuntimeVariableEventType.variableInitialized:
        return 'VariableInitialized';
    }
  }
}

RuntimeVariableEvent variableRegisteredEvent(RuntimeVariable variable) {
  return RuntimeVariableEvent(
    type: RuntimeVariableEventType.variableRegistered,
    variableId: variable.id,
    variableName: variable.name,
    oldValue: null,
    newValue: variable.value,
    timestamp: DateTime.now(),
  );
}

RuntimeVariableEvent variableInitializedEvent(RuntimeVariable variable) {
  return RuntimeVariableEvent(
    type: RuntimeVariableEventType.variableInitialized,
    variableId: variable.id,
    variableName: variable.name,
    oldValue: null,
    newValue: variable.value,
    timestamp: DateTime.now(),
  );
}

RuntimeVariableEvent variableUpdatedEvent({
  required RuntimeVariable variable,
  required dynamic oldValue,
  required dynamic newValue,
}) {
  return RuntimeVariableEvent(
    type: RuntimeVariableEventType.variableUpdated,
    variableId: variable.id,
    variableName: variable.name,
    oldValue: oldValue,
    newValue: newValue,
    timestamp: DateTime.now(),
  );
}

RuntimeVariableEvent variableRemovedEvent(RuntimeVariable variable) {
  return RuntimeVariableEvent(
    type: RuntimeVariableEventType.variableRemoved,
    variableId: variable.id,
    variableName: variable.name,
    oldValue: variable.value,
    newValue: null,
    timestamp: DateTime.now(),
  );
}
