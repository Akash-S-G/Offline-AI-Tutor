import 'package:flutter/foundation.dart';
import 'models/runtime_object_state.dart';
import 'objects/runtime_object_lifecycle_manager.dart';

class ObjectRegistry extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _objects = {};
  final Map<String, RuntimeObjectState> _objectStates = {};
  RuntimeObjectLifecycleManager? _lifecycleManager;

  void attachLifecycleManager(RuntimeObjectLifecycleManager lifecycleManager) {
    _lifecycleManager = lifecycleManager;
  }

  void initialize(List<Map<String, dynamic>> objectsJson) {
    _objects.clear();
    _objectStates.clear();
    for (var obj in objectsJson) {
      final objectId = obj['objectId']?.toString() ?? obj['id']?.toString();
      if (objectId == null || objectId.isEmpty) continue;
      _objects[objectId] = Map<String, dynamic>.from(obj);
      registerObjectState(RuntimeObjectState.fromObjectJson(obj));
    }
    notifyListeners();
  }

  Map<String, dynamic>? get(String id) => _objects[id];

  RuntimeObjectState? getObjectState(String objectId) =>
      _objectStates[objectId];

  void registerObjectState(RuntimeObjectState state) {
    if (state.objectId.isEmpty) return;
    final initialized = _lifecycleManager?.initializeObject(state) ?? state;
    _objectStates[state.objectId] = initialized;
    notifyListeners();
  }

  void updateObjectState(String objectId, String property, dynamic value) {
    final current = _objectStates[objectId];
    if (current == null) return;
    final updated = current.withProperty(property, value);
    _objectStates[objectId] = updated;
    _lifecycleManager?.onStateUpdated(updated);
    notifyListeners();
  }

  void setObjectVisible(String objectId, bool visible) {
    final current = _objectStates[objectId];
    if (current == null) return;
    final updated = current.copyWith(
      visible: visible,
      updatedAt: DateTime.now(),
    );
    _objectStates[objectId] = updated;
    _lifecycleManager?.onStateUpdated(updated);
    notifyListeners();
  }

  void updateProperty(String objectId, String property, dynamic value) {
    if (_objects.containsKey(objectId)) {
      _objects[objectId]![property] = value;
      updateObjectState(objectId, property, value);
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get allObjects => _objects.values.toList();

  List<RuntimeObjectState> get allObjectStates =>
      _objectStates.values.toList(growable: false);
}
