// ignore_for_file: avoid_print

import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/playground_scene.dart';
import '../models/playground_object.dart';

import '../models/playground_event.dart';
import 'playground_event_bus.dart';
import 'scene_loader.dart';

enum PlaygroundState {
  idle,
  initialized,
  loaded,
  running,
  paused,
  stopped,
  disposed,
}

class SimulationPlaygroundEngine {
  final PlaygroundEventBus _eventBus = PlaygroundEventBus();
  final SceneLoader _sceneLoader = SceneLoader();
  final Uuid _uuid = const Uuid();

  PlaygroundState _state = PlaygroundState.idle;
  PlaygroundState get state => _state;

  PlaygroundScene? _currentScene;
  PlaygroundScene? get currentScene => _currentScene;

  Stream<PlaygroundEvent> get eventStream => _eventBus.stream;

  Future<void> initialize() async {
    _state = PlaygroundState.initialized;
    print('[PLAYGROUND] ENGINE_INITIALIZED');
  }

  Future<void> loadScene(Map<String, dynamic> sceneJson) async {
    try {
      _currentScene = _sceneLoader.loadSceneFromJson(sceneJson);
      _state = PlaygroundState.loaded;
      print('[PLAYGROUND] SCENE_LOADED sceneId=${_currentScene?.sceneId}');
      
      _eventBus.publish(PlaygroundEvent(
        eventId: _uuid.v4(),
        eventType: PlaygroundEventType.sceneLoaded,
        timestamp: DateTime.now(),
        payload: {'sceneId': _currentScene?.sceneId},
      ));

      // Emit object creation events
      for (final obj in _currentScene?.objects ?? <PlaygroundObject>[]) {
        print('[PLAYGROUND] OBJECT_CREATED objectId=${obj.objectId}');
        _eventBus.publish(PlaygroundEvent(
          eventId: _uuid.v4(),
          eventType: PlaygroundEventType.objectCreated,
          timestamp: DateTime.now(),
          payload: {'objectId': obj.objectId, 'objectType': obj.objectType},
        ));
      }
    } catch (e) {
      print('[PLAYGROUND] LOAD_ERROR error=$e');
    }
  }

  void updateVariable(String name, dynamic value) {
    if (_currentScene == null) return;
    
    for (final variable in _currentScene!.variables) {
      if (variable.name == name) {
        variable.value = value;
        print('[PLAYGROUND] VARIABLE_CHANGED name=$name value=$value');
        
        _eventBus.publish(PlaygroundEvent(
          eventId: _uuid.v4(),
          eventType: PlaygroundEventType.variableChanged,
          timestamp: DateTime.now(),
          payload: {'name': name, 'value': value},
        ));
        
        // Example check for rule triggers would go here
        _evaluateRules(PlaygroundEventType.variableChanged, {'name': name});
        break;
      }
    }
  }

  void updateObjectState(String objectId, Map<String, dynamic> newState) {
    if (_currentScene == null) return;

    for (final obj in _currentScene!.objects) {
      if (obj.objectId == objectId) {
        obj.state.addAll(newState);
        
        _eventBus.publish(PlaygroundEvent(
          eventId: _uuid.v4(),
          eventType: PlaygroundEventType.objectUpdated,
          timestamp: DateTime.now(),
          payload: {'objectId': objectId, 'state': obj.state},
        ));
        break;
      }
    }
  }

  void _evaluateRules(PlaygroundEventType eventType, Map<String, dynamic> payload) {
    if (_currentScene == null) return;
    
    // Abstract rule engine simulation
    for (final rule in _currentScene!.rules) {
      if (!rule.enabled) continue;
      
      // We don't execute physics, but we record the rule execution as metadata
      if (rule.trigger == eventType.name || rule.trigger == 'any') {
        print('[PLAYGROUND] RULE_EXECUTED ruleId=${rule.ruleId}');
        _eventBus.publish(PlaygroundEvent(
          eventId: _uuid.v4(),
          eventType: PlaygroundEventType.ruleExecuted,
          timestamp: DateTime.now(),
          payload: {'ruleId': rule.ruleId},
        ));
      }
    }
  }

  Future<void> start() async {
    _state = PlaygroundState.running;
    print('[PLAYGROUND] ENGINE_STARTED');
  }

  Future<void> pause() async {
    _state = PlaygroundState.paused;
    print('[PLAYGROUND] ENGINE_PAUSED');
  }

  Future<void> resume() async {
    _state = PlaygroundState.running;
    print('[PLAYGROUND] ENGINE_RESUMED');
  }

  Future<void> stop() async {
    _state = PlaygroundState.stopped;
    print('[PLAYGROUND] ENGINE_STOPPED');
  }

  Future<void> dispose() async {
    _state = PlaygroundState.disposed;
    _eventBus.dispose();
    print('[PLAYGROUND] ENGINE_DISPOSED');
  }
}
