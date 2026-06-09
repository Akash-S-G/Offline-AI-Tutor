import '../models/runtime_variable.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../variable_store.dart';

class RuntimeVariableScheduler {
  final VariableStore variables;
  final RuntimeEventBus eventBus;
  final Map<String, double> _intervalElapsed = {};
  final Set<String> _finishedCountdowns = {};

  RuntimeVariableScheduler({required this.variables, required this.eventBus});

  List<String> tick(double dt) {
    final changed = <String>[];
    for (final variable in variables.getAllVariables()) {
      switch (variable.type) {
        case 'elapsedTime':
          if (!_isRunning(variable)) continue;
          final nextValue = _numeric(variable.value) + dt;
          _update(variable, nextValue, changed);
          _emitTimerEvent('TimerVariableTicked', variable, {
            'dt': dt,
            'value': nextValue,
          });
          break;
        case 'countdown':
          if (!_isRunning(variable)) continue;
          if (_finishedCountdowns.contains(variable.id)) continue;
          final nextValue = (_numeric(variable.value) - dt).clamp(
            0,
            double.infinity,
          );
          _update(variable, nextValue, changed);
          _emitTimerEvent('TimerVariableTicked', variable, {
            'dt': dt,
            'value': nextValue,
          });
          if (nextValue <= 0) {
            _finishedCountdowns.add(variable.id);
            _emitTimerEvent('CountdownFinished', variable, {'value': 0});
          }
          break;
        case 'interval':
          if (!_isRunning(variable)) continue;
          final interval = _intervalSeconds(variable);
          if (interval <= 0) continue;
          final elapsed = (_intervalElapsed[variable.id] ?? 0) + dt;
          if (elapsed >= interval) {
            final triggerCount = elapsed ~/ interval;
            _intervalElapsed[variable.id] = elapsed - triggerCount * interval;
            _update(variable, _numeric(variable.value) + triggerCount, changed);
            for (var i = 0; i < triggerCount; i++) {
              _emitTimerEvent('IntervalTriggered', variable, {
                'interval': interval,
                'triggerCount': triggerCount,
              });
            }
          } else {
            _intervalElapsed[variable.id] = elapsed;
          }
          break;
      }
    }
    return changed;
  }

  void reset() {
    _intervalElapsed.clear();
    _finishedCountdowns.clear();
  }

  void _update(RuntimeVariable variable, dynamic value, List<String> changed) {
    variables.updateVariable(variable.id, value, source: 'timer');
    changed.add(variable.id);
  }

  bool _isRunning(RuntimeVariable variable) {
    final metadataRunning = variable.metadata['running'];
    if (metadataRunning is bool) return metadataRunning;
    if (metadataRunning is String) return metadataRunning != 'false';
    return true;
  }

  double _intervalSeconds(RuntimeVariable variable) {
    final metadataInterval =
        variable.metadata['interval'] ?? variable.metadata['intervalSeconds'];
    if (metadataInterval is num) return metadataInterval.toDouble();
    final parsed = double.tryParse(metadataInterval?.toString() ?? '');
    if (parsed != null) return parsed;
    return _numeric(variable.value);
  }

  double _numeric(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _emitTimerEvent(
    String message,
    RuntimeVariable variable,
    Map<String, dynamic> metadata,
  ) {
    eventBus.emit(
      RuntimeEvent(
        id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: message,
        metadata: {
          'variableId': variable.id,
          'variableName': variable.name,
          'variableType': variable.type,
          ...metadata,
        },
      ),
    );
  }
}
