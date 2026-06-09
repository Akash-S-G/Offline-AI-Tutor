import '../models/runtime_object_state.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import 'behavior/runtime_object_behavior.dart';
import 'behavior/runtime_object_behavior_registry.dart';
import 'renderers/runtime_object_renderer.dart';
import 'renderers/runtime_object_renderer_registry.dart';
import 'schema/runtime_object_schema.dart';
import 'schema/runtime_object_schema_registry.dart';

class RuntimeObjectLifecycleStatus {
  final String objectId;
  final String objectType;
  final bool schemaLoaded;
  final bool behaviorLoaded;
  final bool rendererLoaded;
  final bool isValid;
  final List<String> validationErrors;

  const RuntimeObjectLifecycleStatus({
    required this.objectId,
    required this.objectType,
    required this.schemaLoaded,
    required this.behaviorLoaded,
    required this.rendererLoaded,
    required this.isValid,
    required this.validationErrors,
  });
}

class RuntimeObjectLifecycleManager {
  final RuntimeObjectSchemaRegistry schemaRegistry;
  final RuntimeObjectBehaviorRegistry behaviorRegistry;
  final RuntimeObjectRendererRegistry rendererRegistry;
  final RuntimeEventBus eventBus;

  final Map<String, RuntimeObjectBehavior> _behaviors = {};
  final Map<String, RuntimeObjectRenderer> _renderers = {};
  final Map<String, RuntimeObjectLifecycleStatus> _statuses = {};

  RuntimeObjectLifecycleManager({
    required this.schemaRegistry,
    required this.behaviorRegistry,
    required this.rendererRegistry,
    required this.eventBus,
  });

  RuntimeObjectState initializeObject(RuntimeObjectState state) {
    final schema = schemaRegistry.getSchema(state.objectType);
    final stateWithDefaults = _applySchemaDefaults(state, schema);
    final behavior = behaviorRegistry.createBehavior(state.objectType);
    final renderer = rendererRegistry.createRenderer(state.objectType);

    behavior?.initialize();
    renderer?.initialize();

    if (behavior != null) {
      _behaviors[state.objectId] = behavior;
    }
    if (renderer != null) {
      _renderers[state.objectId] = renderer;
    }

    final validation =
        behavior?.validateState(stateWithDefaults) ??
        const ValidationResult.valid();
    behavior?.onStateUpdated(stateWithDefaults);
    renderer?.update(stateWithDefaults);

    _setStatus(
      RuntimeObjectLifecycleStatus(
        objectId: state.objectId,
        objectType: state.objectType,
        schemaLoaded: schema != null,
        behaviorLoaded: behavior != null,
        rendererLoaded: renderer != null,
        isValid: validation.isValid,
        validationErrors: validation.errors,
      ),
    );

    _emit('ObjectSchemaLoaded', stateWithDefaults, schema != null);
    _emit('ObjectBehaviorCreated', stateWithDefaults, behavior != null);
    _emit('ObjectRendererCreated', stateWithDefaults, renderer != null);
    if (!validation.isValid) {
      _emit('ObjectValidationFailed', stateWithDefaults, false, {
        'errors': validation.errors,
      });
    }

    return stateWithDefaults;
  }

  void onStateUpdated(RuntimeObjectState state) {
    final behavior = _behaviors[state.objectId];
    final renderer = _renderers[state.objectId];
    final validation =
        behavior?.validateState(state) ?? const ValidationResult.valid();

    behavior?.onStateUpdated(state);
    renderer?.update(state);

    final previous = _statuses[state.objectId];
    _setStatus(
      RuntimeObjectLifecycleStatus(
        objectId: state.objectId,
        objectType: state.objectType,
        schemaLoaded: previous?.schemaLoaded ?? false,
        behaviorLoaded: behavior != null,
        rendererLoaded: renderer != null,
        isValid: validation.isValid,
        validationErrors: validation.errors,
      ),
    );

    if (!validation.isValid) {
      _emit('ObjectValidationFailed', state, false, {
        'errors': validation.errors,
      });
    }
  }

  RuntimeObjectLifecycleStatus? getStatus(String objectId) =>
      _statuses[objectId];

  List<RuntimeObjectLifecycleStatus> getAllStatuses() =>
      List.unmodifiable(_statuses.values.toList(growable: false));

  bool hasBehavior(String objectId) => _behaviors.containsKey(objectId);

  bool hasRenderer(String objectId) => _renderers.containsKey(objectId);

  RuntimeObjectRenderer? getRenderer(String objectId) => _renderers[objectId];

  void dispose() {
    for (final behavior in _behaviors.values) {
      behavior.dispose();
    }
    for (final renderer in _renderers.values) {
      renderer.dispose();
    }
    _behaviors.clear();
    _renderers.clear();
    _statuses.clear();
  }

  RuntimeObjectState _applySchemaDefaults(
    RuntimeObjectState state,
    RuntimeObjectSchema? schema,
  ) {
    if (schema == null) return state;
    return state.copyWith(
      state: schema.applyDefaults(state.state),
      updatedAt: DateTime.now(),
    );
  }

  void _setStatus(RuntimeObjectLifecycleStatus status) {
    _statuses[status.objectId] = status;
  }

  void _emit(
    String message,
    RuntimeObjectState state,
    bool loaded, [
    Map<String, dynamic>? metadata,
  ]) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'objectId': state.objectId,
          'objectType': state.objectType,
          'loaded': loaded,
          ...?metadata,
        },
      ),
    );
  }
}
