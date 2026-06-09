import 'package:flutter/foundation.dart';

class VariableStore extends ChangeNotifier {
  final Map<String, dynamic> _variables = {};

  void initialize(List<Map<String, dynamic>> variablesJson) {
    _variables.clear();
    for (var v in variablesJson) {
      _variables[v['id']] = v['value'];
    }
    notifyListeners();
  }

  dynamic get(String id) => _variables[id];

  void set(String id, dynamic value) {
    if (_variables[id] != value) {
      _variables[id] = value;
      notifyListeners();
    }
  }

  Map<String, dynamic> get allVariables => Map.unmodifiable(_variables);
}
