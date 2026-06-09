import '../runtime_event.dart';
import 'runtime_interaction_types.dart';

class RuntimeInteractionEvent {
  final RuntimeInteractionType type;
  final String objectId;
  final String? variableId;
  final dynamic value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const RuntimeInteractionEvent({
    required this.type,
    required this.objectId,
    required this.timestamp,
    this.variableId,
    this.value,
    this.metadata = const {},
  });

  RuntimeEvent toRuntimeEvent() {
    return RuntimeEvent(
      id: '${type.name}_${timestamp.microsecondsSinceEpoch}',
      timestamp: timestamp,
      type: RuntimeEventType.custom,
      message: _message,
      metadata: {
        'interactionType': type.name,
        'objectId': objectId,
        if (variableId != null) 'variableId': variableId,
        'value': value,
        ...metadata,
      },
    );
  }

  String get _message {
    switch (type) {
      case RuntimeInteractionType.buttonPressed:
        return 'ButtonPressed';
      case RuntimeInteractionType.buttonReleased:
        return 'ButtonReleased';
      case RuntimeInteractionType.sliderChanged:
        return 'SliderChanged';
      case RuntimeInteractionType.toggleEnabled:
        return 'ToggleEnabled';
      case RuntimeInteractionType.toggleDisabled:
        return 'ToggleDisabled';
    }
  }
}
