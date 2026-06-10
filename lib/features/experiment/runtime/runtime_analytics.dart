import 'dart:async';
import 'runtime_event_bus.dart';

class RuntimeAnalytics {
  int _launches = 0;
  double _timeSpent = 0;
  int _ruleExecutions = 0;
  int _variableUpdates = 0;
  int _variablesRegistered = 0;
  int _variablesRemoved = 0;
  int _bindingsRegistered = 0;
  int _bindingsResolved = 0;
  int _bindingsFailed = 0;
  int _objectsUpdated = 0;
  int _schemasLoaded = 0;
  int _behaviorsCreated = 0;
  int _renderersCreated = 0;
  int _objectValidationFailures = 0;
  int _sliderInteractions = 0;
  int _toggleInteractions = 0;
  int _buttonInteractions = 0;
  int _rulesEvaluated = 0;
  int _rulesPassed = 0;
  int _rulesFailed = 0;
  int _rulesFired = 0;
  int _actionsExecuted = 0;
  int _warningsGenerated = 0;
  int _timerTicks = 0;
  int _countdownsFinished = 0;
  int _intervalEvents = 0;
  int _computedEvaluations = 0;
  int _dependencyResolutions = 0;
  int _measurementsCollected = 0;
  int _measurementsDiscarded = 0;
  int _graphsRendered = 0;
  int _graphUpdates = 0;
  int _graphSamplesProcessed = 0;
  int _scatterPlotsRendered = 0;
  int _scatterPlotUpdates = 0;
  int _scatterPointsProcessed = 0;
  int _sensorVariables = 0;
  int _activeSensors = 0;
  int _sensorMeasurements = 0;
  int _sensorErrors = 0;
  int _permissionDenials = 0;
  int _observationsRecorded = 0;
  int _observationRows = 0;
  int _observationExports = 0;
  int _experimentsStarted = 0;
  int _experimentsCompleted = 0;
  int _experimentsFailed = 0;
  double _completedRuntimeTotal = 0;
  final Set<String> _measurementVariablesTracked = {};
  DateTime? _lastInteractionTime;
  String? _lastInteractionSource;
  StreamSubscription? _subscription;

  int get launches => _launches;
  double get timeSpent => _timeSpent;
  int get ruleExecutions => _ruleExecutions;
  int get variableUpdates => _variableUpdates;
  int get variablesRegistered => _variablesRegistered;
  int get variablesRemoved => _variablesRemoved;
  int get bindingsRegistered => _bindingsRegistered;
  int get bindingsResolved => _bindingsResolved;
  int get bindingsFailed => _bindingsFailed;
  int get objectsUpdated => _objectsUpdated;
  int get schemasLoaded => _schemasLoaded;
  int get behaviorsCreated => _behaviorsCreated;
  int get renderersCreated => _renderersCreated;
  int get objectValidationFailures => _objectValidationFailures;
  int get sliderInteractions => _sliderInteractions;
  int get toggleInteractions => _toggleInteractions;
  int get buttonInteractions => _buttonInteractions;
  int get rulesEvaluated => _rulesEvaluated;
  int get rulesPassed => _rulesPassed;
  int get rulesFailed => _rulesFailed;
  int get rulesFired => _rulesFired;
  int get actionsExecuted => _actionsExecuted;
  int get warningsGenerated => _warningsGenerated;
  int get timerTicks => _timerTicks;
  int get countdownsFinished => _countdownsFinished;
  int get intervalEvents => _intervalEvents;
  int get computedEvaluations => _computedEvaluations;
  int get dependencyResolutions => _dependencyResolutions;
  int get measurementsCollected => _measurementsCollected;
  int get measurementsDiscarded => _measurementsDiscarded;
  int get measurementVariablesTracked => _measurementVariablesTracked.length;
  int get graphsRendered => _graphsRendered;
  int get graphUpdates => _graphUpdates;
  int get graphSamplesProcessed => _graphSamplesProcessed;
  int get scatterPlotsRendered => _scatterPlotsRendered;
  int get scatterPlotUpdates => _scatterPlotUpdates;
  int get scatterPointsProcessed => _scatterPointsProcessed;
  int get sensorVariables => _sensorVariables;
  int get activeSensors => _activeSensors;
  int get sensorMeasurements => _sensorMeasurements;
  int get sensorErrors => _sensorErrors;
  int get permissionDenials => _permissionDenials;
  int get observationsRecorded => _observationsRecorded;
  int get observationRows => _observationRows;
  int get observationExports => _observationExports;
  int get experimentsStarted => _experimentsStarted;
  int get experimentsCompleted => _experimentsCompleted;
  int get experimentsFailed => _experimentsFailed;
  double get averageRuntime => _experimentsCompleted == 0
      ? 0
      : _completedRuntimeTotal / _experimentsCompleted;
  DateTime? get lastInteractionTime => _lastInteractionTime;
  String? get lastInteractionSource => _lastInteractionSource;

  void attach(RuntimeEventBus eventBus) {
    _subscription = eventBus.stream.listen((event) {
      if (event.message == 'RuleTriggered') {
        _ruleExecutions++;
      } else if (event.message == 'VariableUpdated' ||
          (event.message == 'VariableChanged' &&
              event.metadata?['variableEventType'] == null)) {
        _variableUpdates++;
      } else if (event.message == 'VariableRegistered') {
        _variablesRegistered++;
      } else if (event.message == 'VariableRemoved') {
        _variablesRemoved++;
      } else if (event.message == 'BindingRegistered') {
        _bindingsRegistered++;
      } else if (event.message == 'BindingResolved') {
        _bindingsResolved++;
      } else if (event.message == 'BindingFailed') {
        _bindingsFailed++;
      } else if (event.message == 'ObjectUpdatedFromBinding') {
        _objectsUpdated++;
      } else if (event.message == 'ObjectSchemaLoaded' &&
          event.metadata?['loaded'] == true) {
        _schemasLoaded++;
      } else if (event.message == 'ObjectBehaviorCreated' &&
          event.metadata?['loaded'] == true) {
        _behaviorsCreated++;
      } else if (event.message == 'ObjectRendererCreated' &&
          event.metadata?['loaded'] == true) {
        _renderersCreated++;
      } else if (event.message == 'ObjectValidationFailed') {
        _objectValidationFailures++;
      } else if (event.message == 'SliderChanged') {
        _sliderInteractions++;
        _recordInteraction(event.metadata?['objectId']?.toString());
      } else if (event.message == 'ToggleEnabled' ||
          event.message == 'ToggleDisabled') {
        _toggleInteractions++;
        _recordInteraction(event.metadata?['objectId']?.toString());
      } else if (event.message == 'ButtonPressed' ||
          event.message == 'ButtonReleased') {
        _buttonInteractions++;
        _recordInteraction(event.metadata?['objectId']?.toString());
      } else if (event.message == 'RuleEvaluated') {
        _rulesEvaluated++;
      } else if (event.message == 'RulePassed') {
        _rulesPassed++;
      } else if (event.message == 'RuleFailed') {
        _rulesFailed++;
      } else if (event.message == 'RuleFired') {
        _rulesFired++;
        _ruleExecutions++;
      } else if (event.message == 'ActionExecuted') {
        _actionsExecuted++;
      } else if (event.type.name == 'warning') {
        _warningsGenerated++;
      } else if (event.message == 'TimerVariableTicked') {
        _timerTicks++;
      } else if (event.message == 'CountdownFinished') {
        _countdownsFinished++;
      } else if (event.message == 'IntervalTriggered') {
        _intervalEvents++;
      } else if (event.message == 'ComputedVariableEvaluated') {
        _computedEvaluations++;
      } else if (event.message == 'DependencyResolved') {
        _dependencyResolutions++;
      } else if (event.message == 'MeasurementCollected') {
        _measurementsCollected++;
        final variableId = event.metadata?['variableId']?.toString();
        if (variableId != null && variableId.isNotEmpty) {
          _measurementVariablesTracked.add(variableId);
        }
      } else if (event.message == 'MeasurementDiscarded') {
        _measurementsDiscarded++;
      } else if (event.message == 'GraphRendered') {
        _graphsRendered++;
      } else if (event.message == 'GraphUpdated') {
        _graphUpdates++;
        final sampleCount = event.metadata?['sampleCount'];
        if (sampleCount is num) {
          _graphSamplesProcessed += sampleCount.toInt();
        }
      } else if (event.message == 'ScatterPlotRendered') {
        _scatterPlotsRendered++;
      } else if (event.message == 'ScatterPlotUpdated') {
        _scatterPlotUpdates++;
        final pointCount = event.metadata?['pointCount'];
        if (pointCount is num) {
          _scatterPointsProcessed += pointCount.toInt();
        }
      } else if (event.message == 'SensorVariableRegistered') {
        _sensorVariables++;
      } else if (event.message == 'SensorStarted') {
        _activeSensors++;
      } else if (event.message == 'SensorStopped') {
        if (_activeSensors > 0) _activeSensors--;
      } else if (event.message == 'SensorMeasurementReceived') {
        _sensorMeasurements++;
      } else if (event.message == 'SensorError') {
        _sensorErrors++;
      } else if (event.message == 'SensorPermissionDenied') {
        _permissionDenials++;
      } else if (event.message == 'ObservationRecorded') {
        _observationsRecorded++;
        _observationRows++;
      } else if (event.message == 'ObservationRemoved') {
        if (_observationRows > 0) _observationRows--;
      } else if (event.message == 'ObservationsCleared') {
        _observationRows = 0;
      } else if (event.message == 'ObservationExported') {
        _observationExports++;
      } else if (event.message == 'ExperimentStarted') {
        _experimentsStarted++;
      } else if (event.message == 'ExperimentCompleted') {
        _experimentsCompleted++;
        final runtimeSeconds = event.metadata?['runtimeSeconds'];
        if (runtimeSeconds is num) {
          _completedRuntimeTotal += runtimeSeconds.toDouble();
        }
      } else if (event.message == 'ExperimentFailed') {
        _experimentsFailed++;
      }
    });
  }

  void _recordInteraction(String? source) {
    _lastInteractionTime = DateTime.now();
    _lastInteractionSource = source;
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
      'variablesRegistered': _variablesRegistered,
      'variablesRemoved': _variablesRemoved,
      'bindingsRegistered': _bindingsRegistered,
      'bindingsResolved': _bindingsResolved,
      'bindingsFailed': _bindingsFailed,
      'objectsUpdated': _objectsUpdated,
      'schemasLoaded': _schemasLoaded,
      'behaviorsCreated': _behaviorsCreated,
      'renderersCreated': _renderersCreated,
      'objectValidationFailures': _objectValidationFailures,
      'sliderInteractions': _sliderInteractions,
      'toggleInteractions': _toggleInteractions,
      'buttonInteractions': _buttonInteractions,
      'rulesEvaluated': _rulesEvaluated,
      'rulesPassed': _rulesPassed,
      'rulesFailed': _rulesFailed,
      'rulesFired': _rulesFired,
      'actionsExecuted': _actionsExecuted,
      'warningsGenerated': _warningsGenerated,
      'timerTicks': _timerTicks,
      'countdownsFinished': _countdownsFinished,
      'intervalEvents': _intervalEvents,
      'computedEvaluations': _computedEvaluations,
      'dependencyResolutions': _dependencyResolutions,
      'measurementsCollected': _measurementsCollected,
      'measurementsDiscarded': _measurementsDiscarded,
      'measurementVariablesTracked': _measurementVariablesTracked.length,
      'graphsRendered': _graphsRendered,
      'graphUpdates': _graphUpdates,
      'graphSamplesProcessed': _graphSamplesProcessed,
      'scatterPlotsRendered': _scatterPlotsRendered,
      'scatterPlotUpdates': _scatterPlotUpdates,
      'scatterPointsProcessed': _scatterPointsProcessed,
      'sensorVariables': _sensorVariables,
      'activeSensors': _activeSensors,
      'sensorMeasurements': _sensorMeasurements,
      'sensorErrors': _sensorErrors,
      'permissionDenials': _permissionDenials,
      'observationsRecorded': _observationsRecorded,
      'observationRows': _observationRows,
      'observationExports': _observationExports,
      'experimentsStarted': _experimentsStarted,
      'experimentsCompleted': _experimentsCompleted,
      'experimentsFailed': _experimentsFailed,
      'averageRuntime': averageRuntime,
      'lastInteractionTime': _lastInteractionTime?.toIso8601String(),
      'lastInteractionSource': _lastInteractionSource,
    };
  }

  void dispose() {
    _subscription?.cancel();
  }
}
