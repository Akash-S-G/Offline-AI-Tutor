import 'models/runtime_variable.dart';

typedef RuntimeVariableCallback = void Function(RuntimeVariable variable);

class RuntimeVariableSubscriptionManager {
  final Map<String, List<RuntimeVariableCallback>> _subscriptions = {};

  void subscribe(String variableId, RuntimeVariableCallback callback) {
    _subscriptions.putIfAbsent(variableId, () => []).add(callback);
  }

  void unsubscribe(String variableId) {
    _subscriptions.remove(variableId);
  }

  void notifySubscribers(RuntimeVariable variable) {
    final callbacks = _subscriptions[variable.id];
    if (callbacks == null) return;
    for (final callback in List<RuntimeVariableCallback>.from(callbacks)) {
      callback(variable);
    }
  }

  void clear() {
    _subscriptions.clear();
  }
}
