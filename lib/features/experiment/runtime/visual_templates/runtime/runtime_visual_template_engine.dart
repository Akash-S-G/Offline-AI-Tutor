import 'package:flutter/foundation.dart';

import '../../runtime_event.dart';
import '../../runtime_event_bus.dart';
import '../../runtime_world.dart';
import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/generated_actor_group.dart';
import '../models/runtime_visual_template_context.dart';
import '../registry/runtime_visual_template_registry.dart';

class RuntimeVisualTemplateEngine extends ChangeNotifier {
  RuntimeVisualTemplateEngine({
    required RuntimeWorld world,
    required RuntimeVisualTemplateRegistry registry,
    required RuntimeEventBus eventBus,
  }) : _world = world,
       _registry = registry,
       _eventBus = eventBus;

  final RuntimeWorld _world;
  final RuntimeVisualTemplateRegistry _registry;
  final RuntimeEventBus _eventBus;
  final Map<String, GeneratedActorGroup> _groups = {};
  bool _initialized = false;
  int _refreshDepth = 0;

  List<GeneratedActorGroup> get groups =>
      _groups.values.toList(growable: false);
  int get groupCount => _groups.length;

  void initialize() {
    if (!_initialized) {
      _world.objects.addListener(_refreshFromObjectStates);
      _initialized = true;
    }
    _emit('VisualTemplatesLoaded');
    _refreshFromObjectStates();
  }

  @override
  void dispose() {
    if (_initialized) {
      _world.objects.removeListener(_refreshFromObjectStates);
    }
    super.dispose();
  }

  void _refreshFromObjectStates() {
    if (_refreshDepth > 0) return;
    _refreshDepth++;
    try {
      var index = 0;
      for (final objectState in _world.objects.allObjectStates) {
        final template = _registry.templateFor(objectState.objectType);
        if (template == null) continue;
        final builderObject = _world.objects.get(objectState.objectId);
        final config = _runtimeConfig(objectState.state, builderObject);
        final context = RuntimeVisualTemplateContext(
          objectState: objectState,
          builderObject: builderObject,
          world: _world,
          runtimeConfig: config,
          originX: 110 + (index % 3) * 210,
          originY: 105 + (index ~/ 3) * 160,
        );
        try {
          _generate(
            context,
            template.name,
            template.buildActors(context),
            template.buildBindings(context),
            template.buildAnimations(context),
          );
        } catch (error) {
          _emit(
            'VisualTemplateFailed',
            metadata: {
              'objectId': objectState.objectId,
              'objectType': objectState.objectType,
              'error': error.toString(),
            },
          );
        }
        index++;
      }
    } finally {
      _refreshDepth--;
    }
  }

  void _generate(
    RuntimeVisualTemplateContext context,
    String templateName,
    List<RuntimeActor> actors,
    List<RuntimeVisualBinding> bindings,
    List<RuntimeAnimation> animations,
  ) {
    for (final actor in actors) {
      _world.simulationCanvas.addActor(actor);
    }
    _world.visualBindings.addBindings(
      bindings
          .where((binding) {
            final existing = _groups.values.expand((group) => group.bindingIds);
            return !existing.contains(binding.id);
          })
          .toList(growable: false),
    );
    _world.animationEngine.addAnimations(
      animations
          .where((animation) {
            final existing = _groups.values.expand(
              (group) => group.animationIds,
            );
            return !existing.contains(animation.id);
          })
          .toList(growable: false),
    );
    final group = GeneratedActorGroup(
      objectId: context.objectId,
      templateName: templateName,
      actorIds: actors.map((actor) => actor.id).toList(growable: false),
      bindingIds: bindings.map((binding) => binding.id).toList(growable: false),
      animationIds: animations
          .map((animation) => animation.id)
          .toList(growable: false),
    );
    _groups[context.objectId] = group;
    _emit(
      'VisualTemplateGenerated',
      metadata: {
        ...group.toJson(),
        'actorCount': actors.length,
        'bindingCount': bindings.length,
        'animationCount': animations.length,
      },
    );
    notifyListeners();
  }

  Map<String, dynamic> _runtimeConfig(
    Map<String, dynamic> state,
    Map<String, dynamic>? objectJson,
  ) {
    return {
      if (objectJson?['runtimeConfig'] is Map)
        ...Map<String, dynamic>.from(objectJson!['runtimeConfig'] as Map),
      if (objectJson?['properties'] is Map &&
          (objectJson!['properties'] as Map)['runtimeConfig'] is Map)
        ...Map<String, dynamic>.from(
          (objectJson['properties'] as Map)['runtimeConfig'] as Map,
        ),
      ...state,
    };
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
