import 'package:flutter/foundation.dart';

class ObjectRegistry extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _objects = {};

  void initialize(List<Map<String, dynamic>> objectsJson) {
    _objects.clear();
    for (var obj in objectsJson) {
      _objects[obj['objectId'] ?? obj['id']] = Map<String, dynamic>.from(obj);
    }
    notifyListeners();
  }

  Map<String, dynamic>? get(String id) => _objects[id];

  void updateProperty(String objectId, String property, dynamic value) {
    if (_objects.containsKey(objectId)) {
      _objects[objectId]![property] = value;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get allObjects => _objects.values.toList();
}
