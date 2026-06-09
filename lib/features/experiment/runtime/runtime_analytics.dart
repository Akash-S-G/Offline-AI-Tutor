import 'dart:async';
import 'runtime_event.dart';
import 'runtime_event_bus.dart';

class RuntimeAnalytics {
  int _launches = 0;
  double _timeSpent = 0;
  int _ruleExecutions = 0;
  int _variableUpdates = 0;
  StreamSubscription? _subscription;

  int get launches => _launches;
  double get timeSpent => _timeSpent;
  int get ruleExecutions => _ruleExecutions;
  int get variableUpdates => _variableUpdates;

  void attach(RuntimeEventBus eventBus) {
    _subscription = eventBus.stream.listen((event) {
      if (event.message == 'RuleTriggered') {
        _ruleExecutions++;
      } else if (event.message == 'VariableChanged') {
        _variableUpdates++;
      }
    });
  }

  void recordLaunch() {
    _launches++;
  }

  void addTimeSpent(double dt) {
    _timeSpent += dt;
  }

  Map<String, dynamic> exportReport() {
    return {
      'launches': _launches,
      'timeSpentSeconds': _timeSpent,
      'ruleExecutions': _ruleExecutions,
      'variableUpdates': _variableUpdates,
    };
  }

  void dispose() {
    _subscription?.cancel();
  }
}

