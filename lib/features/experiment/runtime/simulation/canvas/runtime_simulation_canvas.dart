import 'package:flutter/foundation.dart';

import '../../runtime_event.dart';
import '../../runtime_event_bus.dart';
import '../actors/runtime_actor_registry.dart';
import '../models/runtime_actor.dart';

class RuntimeSimulationCanvas extends ChangeNotifier {
  RuntimeSimulationCanvas({
    RuntimeEventBus? eventBus,
    RuntimeActorRegistry? registry,
  }) : _eventBus = eventBus,
       _registry = registry ?? RuntimeActorRegistry();

  final RuntimeEventBus? _eventBus;
  final RuntimeActorRegistry _registry;
  final Map<String, RuntimeActor> _actors = {};
  int _refreshCount = 0;
  int _renderCount = 0;

  List<RuntimeActor> get actors => _actors.values.toList(growable: false);
  int get actorCount => _actors.length;
  int get visibleActorCount =>
      _actors.values.where((actor) => actor.visible).length;
  int get refreshCount => _refreshCount;
  int get renderCount => _renderCount;

  RuntimeActor? actor(String actorId) => _actors[actorId];

  void initialize(List<Map<String, dynamic>> actorsJson) {
    _actors.clear();
    _refreshCount = 0;
    _renderCount = 0;
    for (final json in actorsJson) {
      addActor(_registry.create(json), notify: false);
    }
    _refresh();
  }

  void addActor(RuntimeActor actor, {bool notify = true}) {
    if (actor.id.isEmpty) return;
    _actors[actor.id] = actor;
    _emit(
      'ActorCreated',
      metadata: {
        'actorId': actor.id,
        'actorType': actor.type,
        'visible': actor.visible,
      },
    );
    if (notify) _refresh();
  }

  bool updateActor(RuntimeActor actor) {
    if (!_actors.containsKey(actor.id)) return false;
    final previous = _actors[actor.id];
    _actors[actor.id] = actor;
    if (previous?.visible != actor.visible) {
      _emit(
        actor.visible ? 'ActorShown' : 'ActorHidden',
        metadata: {'actorId': actor.id},
      );
    }
    _refresh();
    return true;
  }

  bool updateActorProperty(String actorId, String property, dynamic value) {
    final current = _actors[actorId];
    if (current == null) return false;
    return updateActor(current.withProperty(property, value));
  }

  void markRendered() {
    _renderCount++;
    _emit('CanvasRendered', metadata: {'renderCount': _renderCount});
  }

  void clear() {
    _actors.clear();
    _refresh();
  }

  void _refresh() {
    _refreshCount++;
    notifyListeners();
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    _eventBus?.emit(
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
