import 'runtime_binding.dart';

class RuntimeBindingRegistry {
  final Map<String, RuntimeBinding> _bindings = {};

  void registerBinding(RuntimeBinding binding) {
    _bindings[binding.bindingId] = binding;
  }

  void removeBinding(String bindingId) {
    _bindings.remove(bindingId);
  }

  List<RuntimeBinding> getBindingsForVariable(String variableId) {
    return _bindings.values
        .where((binding) => binding.variableId == variableId)
        .toList(growable: false);
  }

  List<RuntimeBinding> getBindingsForObject(String objectId) {
    return _bindings.values
        .where((binding) => binding.objectId == objectId)
        .toList(growable: false);
  }

  List<RuntimeBinding> allBindings() {
    return List.unmodifiable(_bindings.values.toList(growable: false));
  }

  int get length => _bindings.length;

  void clear() {
    _bindings.clear();
  }
}
