import '../bindings/runtime_binding.dart';
import '../bindings/runtime_binding_registry.dart';
import '../object_registry.dart';
import '../variable_store.dart';
import 'runtime_interaction_bus.dart';
import 'runtime_interaction_event.dart';
import 'runtime_interaction_types.dart';

class RuntimeObjectVariableAdapter {
  final VariableStore variables;
  final ObjectRegistry objects;
  final RuntimeBindingRegistry bindings;
  final RuntimeInteractionBus interactionBus;

  RuntimeObjectVariableAdapter({
    required this.variables,
    required this.objects,
    required this.bindings,
    required this.interactionBus,
  });

  void changeSlider(String objectId, num value) {
    updateFromObject(
      objectId: objectId,
      objectProperty: 'value',
      value: value,
      interactionType: RuntimeInteractionType.sliderChanged,
    );
  }

  void setToggle(String objectId, bool value) {
    updateFromObject(
      objectId: objectId,
      objectProperty: 'value',
      value: value,
      interactionType: value
          ? RuntimeInteractionType.toggleEnabled
          : RuntimeInteractionType.toggleDisabled,
    );
  }

  void pressButton(String objectId) {
    final state = objects.getObjectState(objectId)?.state ?? const {};
    final pressCount = state['pressCount'];
    objects.updateObjectState(
      objectId,
      'pressCount',
      pressCount is num ? pressCount + 1 : 1,
    );
    objects.updateObjectState(objectId, 'pressed', true);
    updateFromObject(
      objectId: objectId,
      objectProperty: 'value',
      value: true,
      interactionType: RuntimeInteractionType.buttonPressed,
    );
  }

  void releaseButton(String objectId) {
    objects.updateObjectState(objectId, 'pressed', false);
    updateFromObject(
      objectId: objectId,
      objectProperty: 'value',
      value: false,
      interactionType: RuntimeInteractionType.buttonReleased,
    );
  }

  void updateFromObject({
    required String objectId,
    required String objectProperty,
    required dynamic value,
    required RuntimeInteractionType interactionType,
  }) {
    objects.updateObjectState(objectId, objectProperty, value);
    RuntimeBinding? binding;
    for (final candidate in bindings.getBindingsForObject(objectId)) {
      if (candidate.active &&
          candidate.objectProperty == objectProperty &&
          candidate.allowsObjectToVariable) {
        binding = candidate;
        break;
      }
    }

    if (binding != null) {
      variables.updateVariable(
        binding.variableId,
        value,
        source: 'interactive_object:$objectId',
      );
    }

    interactionBus.emit(
      RuntimeInteractionEvent(
        type: interactionType,
        objectId: objectId,
        variableId: binding?.variableId,
        value: value,
        timestamp: DateTime.now(),
        metadata: {'objectProperty': objectProperty},
      ),
    );
  }
}
