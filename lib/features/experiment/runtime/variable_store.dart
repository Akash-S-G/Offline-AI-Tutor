import 'package:flutter/foundation.dart';
import 'models/runtime_variable.dart';
import 'runtime_event.dart';
import 'runtime_event_bus.dart';
import 'runtime_variable_events.dart';
import 'runtime_variable_subscription_manager.dart';

class VariableStore extends ChangeNotifier {
  final RuntimeEventBus? _eventBus;
  final RuntimeVariableSubscriptionManager _subscriptions;
  final Map<String, RuntimeVariable> _variables = {};

  VariableStore({
    RuntimeEventBus? eventBus,
    RuntimeVariableSubscriptionManager? subscriptionManager,
  }) : _eventBus = eventBus,
       _subscriptions =
           subscriptionManager ?? RuntimeVariableSubscriptionManager();

  void initialize(List<Map<String, dynamic>> variablesJson) {
    _variables.clear();
    for (var v in variablesJson) {
      final variable = RuntimeVariable.fromJson(v);
      if (variable.id.isNotEmpty) {
        registerVariable(variable, emitInitialized: true);
      }
    }
    notifyListeners();
  }

  RuntimeVariable? getVariable(String id) => _variables[id];

  dynamic getValue(String id) => _variables[id]?.value;

  dynamic get(String id) => getValue(id);

  bool containsVariable(String id) => _variables.containsKey(id);

  List<RuntimeVariable> getAllVariables() =>
      List.unmodifiable(_variables.values.toList(growable: false));

  void registerVariable(
    RuntimeVariable variable, {
    bool emitInitialized = false,
  }) {
    final initialized = variable.isInitialized
        ? variable
        : variable.copyWith(isInitialized: true, lastUpdated: DateTime.now());
    _variables[initialized.id] = initialized;
    _emitVariableEvent(variableRegisteredEvent(initialized));
    if (emitInitialized) {
      _emitVariableEvent(variableInitializedEvent(initialized));
    }
    _subscriptions.notifySubscribers(initialized);
    notifyListeners();
  }

  void setVariable(String id, dynamic value) => updateVariable(id, value);

  void set(String id, dynamic value) => updateVariable(id, value);

  void updateVariable(
    String id,
    dynamic value, {
    String source = 'runtime',
    Map<String, dynamic>? metadata,
  }) {
    final current = _variables[id];
    if (current == null) return;
    if (current.value != value) {
      final updated = current.copyWith(
        value: value,
        metadata: metadata == null
            ? current.metadata
            : {...current.metadata, ...metadata},
        lastUpdated: DateTime.now(),
        isInitialized: true,
      );
      _variables[id] = updated;
      notifyListeners();
      _emitVariableEvent(
        variableUpdatedEvent(
          variable: updated,
          oldValue: current.value,
          newValue: value,
        ),
        extraMetadata: {'source': source},
      );
      _emitLegacyVariableChanged(updated, current.value, value, source);
      _subscriptions.notifySubscribers(updated);
    }
  }

  void removeVariable(String id) {
    final removed = _variables.remove(id);
    if (removed == null) return;
    _emitVariableEvent(variableRemovedEvent(removed));
    _subscriptions.notifySubscribers(removed);
    notifyListeners();
  }

  void subscribe(String variableId, RuntimeVariableCallback callback) {
    _subscriptions.subscribe(variableId, callback);
  }

  void unsubscribe(String variableId) {
    _subscriptions.unsubscribe(variableId);
  }

  void _emitVariableEvent(
    RuntimeVariableEvent event, {
    Map<String, dynamic>? extraMetadata,
  }) {
    _eventBus?.emit(event.toRuntimeEvent(extraMetadata: extraMetadata));
  }

  void _emitLegacyVariableChanged(
    RuntimeVariable variable,
    dynamic oldValue,
    dynamic newValue,
    String source,
  ) {
    _eventBus?.emit(
      RuntimeEvent(
        id: 'variable_changed_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: 'VariableChanged',
        metadata: {
          'variableEventType': RuntimeVariableEventType.variableUpdated.name,
          'variableId': variable.id,
          'name': variable.name,
          'oldValue': oldValue,
          'newValue': newValue,
          'source': source,
        },
      ),
    );
  }

  Map<String, dynamic> get allVariables => Map.unmodifiable(
    _variables.map((key, variable) => MapEntry(key, variable.value)),
  );

  Map<String, RuntimeVariable> get allRuntimeVariables =>
      Map.unmodifiable(_variables);

  @override
  void dispose() {
    _subscriptions.clear();
    super.dispose();
  }
}
