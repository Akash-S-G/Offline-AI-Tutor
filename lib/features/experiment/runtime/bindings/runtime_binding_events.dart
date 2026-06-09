import '../runtime_event.dart';
import 'runtime_binding.dart';

enum RuntimeBindingEventType {
  bindingRegistered,
  bindingResolved,
  bindingFailed,
  objectUpdatedFromBinding,
}

class RuntimeBindingEvent {
  final RuntimeBindingEventType type;
  final String bindingId;
  final String variableId;
  final String objectId;
  final String property;
  final dynamic oldValue;
  final dynamic newValue;
  final String? reason;
  final DateTime timestamp;

  const RuntimeBindingEvent({
    required this.type,
    required this.bindingId,
    required this.variableId,
    required this.objectId,
    required this.property,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    this.reason,
  });

  factory RuntimeBindingEvent.fromBinding({
    required RuntimeBindingEventType type,
    required RuntimeBinding binding,
    dynamic oldValue,
    dynamic newValue,
    String? reason,
  }) {
    return RuntimeBindingEvent(
      type: type,
      bindingId: binding.bindingId,
      variableId: binding.variableId,
      objectId: binding.objectId,
      property: binding.objectProperty,
      oldValue: oldValue,
      newValue: newValue,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  RuntimeEvent toRuntimeEvent() {
    return RuntimeEvent(
      id: '${type.name}_${timestamp.microsecondsSinceEpoch}',
      timestamp: timestamp,
      type: RuntimeEventType.custom,
      message: message,
      metadata: {
        'bindingEventType': type.name,
        'bindingId': bindingId,
        'variableId': variableId,
        'objectId': objectId,
        'property': property,
        'oldValue': oldValue,
        'newValue': newValue,
        if (reason != null) 'reason': reason,
      },
    );
  }

  String get message {
    switch (type) {
      case RuntimeBindingEventType.bindingRegistered:
        return 'BindingRegistered';
      case RuntimeBindingEventType.bindingResolved:
        return 'BindingResolved';
      case RuntimeBindingEventType.bindingFailed:
        return 'BindingFailed';
      case RuntimeBindingEventType.objectUpdatedFromBinding:
        return 'ObjectUpdatedFromBinding';
    }
  }
}
