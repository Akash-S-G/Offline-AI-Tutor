import 'dart:async';
import 'dart:math' as math;

import '../models/runtime_variable.dart';
import '../runtime_event.dart';
import '../runtime_event_bus.dart';
import '../runtime_variable_events.dart';
import '../variable_store.dart';
import 'runtime_variable_dependencies.dart';
import 'runtime_variable_scheduler.dart';

class RuntimeVariableExecutor {
  final VariableStore variables;
  final RuntimeEventBus eventBus;
  late final RuntimeVariableScheduler scheduler;
  final RuntimeVariableDependencyGraph dependencyGraph =
      RuntimeVariableDependencyGraph();
  final Set<String> _dirtyComputedVariables = {};
  StreamSubscription<RuntimeEvent>? _subscription;

  RuntimeVariableExecutor({required this.variables, required this.eventBus}) {
    scheduler = RuntimeVariableScheduler(
      variables: variables,
      eventBus: eventBus,
    );
  }

  void initialize() {
    scheduler.reset();
    dependencyGraph.rebuild(variables.getAllVariables());
    _dirtyComputedVariables
      ..clear()
      ..addAll(
        dependencyGraph.allDefinitions.map(
          (definition) => definition.outputVariableId,
        ),
      );
    _subscription?.cancel();
    _subscription = eventBus.stream.listen(_handleRuntimeEvent);
    evaluateDirtyComputedVariables();
  }

  void tick(double dt) {
    final timerChangedIds = scheduler.tick(dt);
    if (timerChangedIds.isNotEmpty) {
      _dirtyComputedVariables.addAll(
        dependencyGraph.affectedBy(timerChangedIds),
      );
    }
    evaluateDirtyComputedVariables();
  }

  List<RuntimeVariable> get timerVariables => variables
      .getAllVariables()
      .where((variable) => _timerTypes.contains(variable.type))
      .toList(growable: false);

  List<RuntimeVariable> get computedVariables => variables
      .getAllVariables()
      .where((variable) => _computedTypes.contains(variable.type))
      .toList(growable: false);

  List<String> dependenciesFor(String variableId) =>
      dependencyGraph.dependenciesFor(variableId);

  void evaluateDirtyComputedVariables() {
    if (_dirtyComputedVariables.isEmpty) return;
    final nextDirty = <String>{..._dirtyComputedVariables};
    _dirtyComputedVariables.clear();
    final evaluated = <String>{};

    while (nextDirty.isNotEmpty) {
      final variableId = nextDirty.first;
      nextDirty.remove(variableId);
      if (!evaluated.add(variableId)) continue;
      final definition = dependencyGraph.definitionFor(variableId);
      final variable = variables.getVariable(variableId);
      if (definition == null || variable == null) continue;
      final value = _evaluate(definition);
      if (value == null) continue;

      variables.updateVariable(variableId, value, source: 'computed');
      _emit('ComputedVariableEvaluated', variable, {
        'value': value,
        'dependencies': definition.dependencies,
      });
      _emit('DependencyResolved', variable, {
        'dependencies': definition.dependencies,
      });

      nextDirty.addAll(dependencyGraph.affectedBy([variableId]));
    }
  }

  dynamic _evaluate(ComputedVariableDefinition definition) {
    final values = definition.dependencies
        .map((id) => _numeric(variables.getValue(id)))
        .toList(growable: false);
    if (definition.formula != null && definition.formula!.trim().isNotEmpty) {
      return _FormulaEvaluator(
        definition.formula!,
        _formulaScope(definition),
      ).evaluate();
    }

    switch (definition.type) {
      case 'average':
        if (values.isEmpty) return 0;
        return values.reduce((a, b) => a + b) / values.length;
      case 'minimum':
        if (values.isEmpty) return 0;
        return values.reduce(math.min);
      case 'maximum':
        if (values.isEmpty) return 0;
        return values.reduce(math.max);
      case 'velocity':
        return _divide(_at(values, 0), _at(values, 1));
      case 'acceleration':
        if (values.length >= 3) {
          return _divide(values[1] - values[0], values[2]);
        }
        return _divide(_at(values, 0), _at(values, 1));
      case 'distance':
        return _at(values, 0) * _at(values, 1);
      case 'force':
        return _at(values, 0) * _at(values, 1);
      case 'power':
        return _at(values, 0) * _at(values, 1);
      case 'energy':
        return _at(values, 0) * _at(values, 1);
      default:
        return null;
    }
  }

  Map<String, double> _formulaScope(ComputedVariableDefinition definition) {
    final scope = <String, double>{};
    for (final dependencyId in definition.dependencies) {
      final variable = variables.getVariable(dependencyId);
      final value = _numeric(variable?.value);
      scope[dependencyId] = value;
      if (variable != null) {
        scope[variable.name] = value;
      }
    }
    return scope;
  }

  void _handleRuntimeEvent(RuntimeEvent event) {
    if (event.message != 'VariableUpdated') return;
    if (event.metadata?['variableEventType'] !=
        RuntimeVariableEventType.variableUpdated.name) {
      return;
    }
    final source = event.metadata?['source']?.toString();
    final variableId = event.metadata?['variableId']?.toString();
    if (variableId == null || variableId.isEmpty) return;
    if (source == 'computed') return;

    final affected = dependencyGraph.affectedBy([variableId]);
    if (affected.isEmpty) return;
    _dirtyComputedVariables.addAll(affected);
    scheduleMicrotask(evaluateDirtyComputedVariables);
  }

  double _at(List<double> values, int index) =>
      index < values.length ? values[index] : 0;

  double _divide(double numerator, double denominator) =>
      denominator == 0 ? 0 : numerator / denominator;

  double _numeric(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _emit(
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

  void dispose() {
    _subscription?.cancel();
    scheduler.reset();
    _dirtyComputedVariables.clear();
  }

  static const Set<String> _timerTypes = {
    'elapsedTime',
    'countdown',
    'interval',
  };

  static const Set<String> _computedTypes = {
    'average',
    'minimum',
    'maximum',
    'velocity',
    'acceleration',
    'distance',
    'force',
    'power',
    'energy',
  };
}

class _FormulaEvaluator {
  final String expression;
  final Map<String, double> scope;
  int _index = 0;

  _FormulaEvaluator(this.expression, this.scope);

  double evaluate() {
    _index = 0;
    return _parseExpression();
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_consume('+')) {
        value += _parseTerm();
      } else if (_consume('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWhitespace();
      if (_consume('*')) {
        value *= _parseFactor();
      } else if (_consume('/')) {
        final denominator = _parseFactor();
        value = denominator == 0 ? 0 : value / denominator;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipWhitespace();
    if (_consume('(')) {
      final value = _parseExpression();
      _consume(')');
      return value;
    }
    if (_consume('-')) return -_parseFactor();
    if (_peekIsNumber()) return _parseNumber();
    return _parseIdentifier();
  }

  double _parseNumber() {
    final start = _index;
    while (_index < expression.length &&
        (RegExp(r'[0-9.]').hasMatch(expression[_index]))) {
      _index++;
    }
    return double.tryParse(expression.substring(start, _index)) ?? 0;
  }

  double _parseIdentifier() {
    final start = _index;
    while (_index < expression.length &&
        RegExp(r'[A-Za-z0-9_]').hasMatch(expression[_index])) {
      _index++;
    }
    if (start == _index) return 0;
    final key = expression.substring(start, _index);
    return scope[key] ?? 0;
  }

  bool _consume(String char) {
    _skipWhitespace();
    if (_index < expression.length && expression[_index] == char) {
      _index++;
      return true;
    }
    return false;
  }

  bool _peekIsNumber() {
    return _index < expression.length &&
        RegExp(r'[0-9.]').hasMatch(expression[_index]);
  }

  void _skipWhitespace() {
    while (_index < expression.length && expression[_index].trim().isEmpty) {
      _index++;
    }
  }
}
