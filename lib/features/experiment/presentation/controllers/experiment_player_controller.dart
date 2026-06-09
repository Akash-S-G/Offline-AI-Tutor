import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/experiment_models.dart';
import '../../application/orchestrator/experiment_execution_state.dart';
import '../../runtime/runtime_world.dart';
import '../../runtime/runtime_loader.dart';
import '../../builder/templates/experiment_templates.dart';
import '../../runtime/runtime_event.dart';

class ExperimentPlayerController extends ChangeNotifier {
  RuntimeWorld? _world;
  RuntimeWorld? get world => _world;
  
  Map<String, dynamic> _rawManifestData = {};
  Map<String, dynamic> get rawManifestData => _rawManifestData;

  ExperimentExecutionState _state = ExperimentExecutionState.idle;
  ExperimentExecutionState get state => _state;

  final List<RuntimeEvent> _events = [];
  List<RuntimeEvent> get events => List.unmodifiable(_events);

  StreamSubscription<RuntimeEvent>? _eventSubscription;
  bool _disposed = false;

  Future<void> prepare(ExperimentManifest manifest, {Map<String, dynamic>? payload}) async {
    try {
      _state = ExperimentExecutionState.preparing;
      notifyListeners();
      
      print('[EXPERIMENT] LOADING_LOCAL_MANIFEST');
      Map<String, dynamic> templateData = {};

      if (payload != null && payload.isNotEmpty) {
        if (!payload.containsKey('scene')) {
          templateData = { 'scene': payload };
        } else {
          templateData = payload;
        }
      } else {
        // Look up template data to load scene details
        final match = ExperimentTemplates.allTemplates.firstWhere(
          (t) => (t['scene']?['sceneId'] == manifest.id) || 
                 (t['metadata']?['title'] == manifest.title) ||
                 (manifest.id.contains(t['scene']?['sceneId']?.split('_')[0] ?? '')),
          orElse: () => <String, dynamic>{},
        );
        
        if (match.isNotEmpty) {
          templateData = match;
        }
      }

      _rawManifestData = templateData;
      _world = RuntimeLoader.loadFromManifest(templateData);
      
      if (_disposed) return;
      _state = ExperimentExecutionState.starting;
      
      _eventSubscription = _world!.eventBus.stream.listen((event) {
        _events.insert(0, event);
        if (_events.length > 100) _events.removeLast();
        if (!_disposed) notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      print('[EXPERIMENT_UI] PREPARE_ERROR error=$e');
      _state = ExperimentExecutionState.failed;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> start() async {
    print('[EXPERIMENT_UI] PLAYER_STARTED');
    _world?.clock.start();
    _state = ExperimentExecutionState.running;
    if (!_disposed) notifyListeners();
  }

  Future<void> pause() async {
    print('[EXPERIMENT_UI] PLAYER_PAUSED');
    _world?.clock.pause();
    _state = ExperimentExecutionState.paused;
    if (!_disposed) notifyListeners();
  }

  Future<void> resume() async {
    print('[EXPERIMENT_UI] PLAYER_RESUMED');
    _world?.clock.start();
    _state = ExperimentExecutionState.running;
    if (!_disposed) notifyListeners();
  }

  Future<void> stop() async {
    print('[EXPERIMENT_UI] PLAYER_STOPPED');
    _world?.clock.reset();
    _state = ExperimentExecutionState.completed;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSubscription?.cancel();
    _world?.dispose();
    super.dispose();
  }
}
