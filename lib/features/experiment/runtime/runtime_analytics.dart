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
  int _vectorUpdates = 0;
  int _waveformUpdates = 0;
  int _fftComputations = 0;
  int _barChartUpdates = 0;
  int _scientificRenderCount = 0;
  int _builderRulesLoaded = 0;
  int _builderRulesValidated = 0;
  int _builderRuleValidationFailures = 0;
  int _builderActionsConfigured = 0;
  int _observationsRecorded = 0;
  int _observationRows = 0;
  int _observationExports = 0;
  int _experimentsStarted = 0;
  int _experimentsCompleted = 0;
  int _experimentsFailed = 0;
  int _sessionsSaved = 0;
  int _sessionsLoaded = 0;
  int _autosavesPerformed = 0;
  int _recoveriesPerformed = 0;
  int _sessionsDeleted = 0;
  int _actorsCreated = 0;
  int _actorsVisible = 0;
  int _visualBindingsResolved = 0;
  int _visualBindingFailures = 0;
  int _animationsRunning = 0;
  int _animationUpdates = 0;
  int _canvasRenders = 0;
  int _visualTemplatesLoaded = 0;
  int _visualTemplatesGenerated = 0;
  int _generatedActors = 0;
  int _generatedBindings = 0;
  int _generatedAnimations = 0;
  int _visualTemplateFailures = 0;
  int _presetsLoaded = 0;
  int _presetSceneBuilds = 0;
  int _presetActorsGenerated = 0;
  int _presetAnimationsGenerated = 0;
  int _presetFailures = 0;
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
  int get vectorUpdates => _vectorUpdates;
  int get waveformUpdates => _waveformUpdates;
  int get fftComputations => _fftComputations;
  int get barChartUpdates => _barChartUpdates;
  int get scientificRenderCount => _scientificRenderCount;
  int get builderRulesLoaded => _builderRulesLoaded;
  int get builderRulesValidated => _builderRulesValidated;
  int get builderRuleValidationFailures => _builderRuleValidationFailures;
  int get builderActionsConfigured => _builderActionsConfigured;
  int get observationsRecorded => _observationsRecorded;
  int get observationRows => _observationRows;
  int get observationExports => _observationExports;
  int get experimentsStarted => _experimentsStarted;
  int get experimentsCompleted => _experimentsCompleted;
  int get experimentsFailed => _experimentsFailed;
  int get sessionsSaved => _sessionsSaved;
  int get sessionsLoaded => _sessionsLoaded;
  int get autosavesPerformed => _autosavesPerformed;
  int get recoveriesPerformed => _recoveriesPerformed;
  int get sessionsDeleted => _sessionsDeleted;
  int get actorsCreated => _actorsCreated;
  int get actorsVisible => _actorsVisible;
  int get visualBindingsResolved => _visualBindingsResolved;
  int get visualBindingFailures => _visualBindingFailures;
  int get animationsRunning => _animationsRunning;
  int get animationUpdates => _animationUpdates;
  int get canvasRenders => _canvasRenders;
  int get visualTemplatesLoaded => _visualTemplatesLoaded;
  int get visualTemplatesGenerated => _visualTemplatesGenerated;
  int get generatedActors => _generatedActors;
  int get generatedBindings => _generatedBindings;
  int get generatedAnimations => _generatedAnimations;
  int get visualTemplateFailures => _visualTemplateFailures;
  int get presetsLoaded => _presetsLoaded;
  int get presetSceneBuilds => _presetSceneBuilds;
  int get presetActorsGenerated => _presetActorsGenerated;
  int get presetAnimationsGenerated => _presetAnimationsGenerated;
  int get presetFailures => _presetFailures;
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
      } else if (event.message == 'VectorVisualizerUpdated') {
        _vectorUpdates++;
      } else if (event.message == 'OscilloscopeUpdated') {
        _waveformUpdates++;
      } else if (event.message == 'SpectrumAnalyzerUpdated') {
        _fftComputations++;
      } else if (event.message == 'BarChartUpdated') {
        _barChartUpdates++;
      } else if (event.message == 'ScientificObjectRendered') {
        _scientificRenderCount++;
      } else if (event.message == 'RuleRegistered') {
        _builderRulesLoaded++;
        final actionCount = event.metadata?['actionCount'];
        if (actionCount is num) {
          _builderActionsConfigured += actionCount.toInt();
        }
      } else if (event.message == 'RuleActivated') {
        _builderRulesValidated++;
      } else if (event.message == 'ActionUnsupported') {
        _builderRuleValidationFailures++;
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
      } else if (event.message == 'SessionSaved') {
        _sessionsSaved++;
      } else if (event.message == 'SessionLoaded') {
        _sessionsLoaded++;
        _recoveriesPerformed++;
      } else if (event.message == 'AutosaveCompleted') {
        _autosavesPerformed++;
      } else if (event.message == 'SessionDeleted') {
        _sessionsDeleted++;
      } else if (event.message == 'ActorCreated') {
        _actorsCreated++;
        if (event.metadata?['visible'] == true) _actorsVisible++;
      } else if (event.message == 'ActorShown') {
        _actorsVisible++;
      } else if (event.message == 'ActorHidden') {
        if (_actorsVisible > 0) _actorsVisible--;
      } else if (event.message == 'VisualBindingResolved') {
        _visualBindingsResolved++;
      } else if (event.message == 'VisualBindingFailed') {
        _visualBindingFailures++;
      } else if (event.message == 'AnimationStarted') {
        _animationsRunning++;
      } else if (event.message == 'AnimationUpdated') {
        _animationUpdates++;
      } else if (event.message == 'CanvasRendered') {
        _canvasRenders++;
      } else if (event.message == 'VisualTemplatesLoaded') {
        _visualTemplatesLoaded++;
      } else if (event.message == 'VisualTemplateGenerated') {
        _visualTemplatesGenerated++;
        final actorCount = event.metadata?['actorCount'];
        final bindingCount = event.metadata?['bindingCount'];
        final animationCount = event.metadata?['animationCount'];
        if (actorCount is num) _generatedActors += actorCount.toInt();
        if (bindingCount is num) _generatedBindings += bindingCount.toInt();
        if (animationCount is num) {
          _generatedAnimations += animationCount.toInt();
        }
      } else if (event.message == 'VisualTemplateFailed') {
        _visualTemplateFailures++;
      } else if (event.message == 'PresetsLoaded') {
        _presetsLoaded++;
      } else if (event.message == 'PresetSceneBuilt') {
        _presetSceneBuilds++;
        final actorCount = event.metadata?['actorCount'];
        final animationCount = event.metadata?['animationCount'];
        if (actorCount is num) {
          _presetActorsGenerated += actorCount.toInt();
        }
        if (animationCount is num) {
          _presetAnimationsGenerated += animationCount.toInt();
        }
      } else if (event.message == 'PresetFailed') {
        _presetFailures++;
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
      'vectorUpdates': _vectorUpdates,
      'waveformUpdates': _waveformUpdates,
      'fftComputations': _fftComputations,
      'barChartUpdates': _barChartUpdates,
      'scientificRenderCount': _scientificRenderCount,
      'builderRulesLoaded': _builderRulesLoaded,
      'builderRulesValidated': _builderRulesValidated,
      'builderRuleValidationFailures': _builderRuleValidationFailures,
      'builderActionsConfigured': _builderActionsConfigured,
      'observationsRecorded': _observationsRecorded,
      'observationRows': _observationRows,
      'observationExports': _observationExports,
      'experimentsStarted': _experimentsStarted,
      'experimentsCompleted': _experimentsCompleted,
      'experimentsFailed': _experimentsFailed,
      'sessionsSaved': _sessionsSaved,
      'sessionsLoaded': _sessionsLoaded,
      'autosavesPerformed': _autosavesPerformed,
      'recoveriesPerformed': _recoveriesPerformed,
      'sessionsDeleted': _sessionsDeleted,
      'actorsCreated': _actorsCreated,
      'actorsVisible': _actorsVisible,
      'visualBindingsResolved': _visualBindingsResolved,
      'visualBindingFailures': _visualBindingFailures,
      'animationsRunning': _animationsRunning,
      'animationUpdates': _animationUpdates,
      'canvasRenders': _canvasRenders,
      'visualTemplatesLoaded': _visualTemplatesLoaded,
      'visualTemplatesGenerated': _visualTemplatesGenerated,
      'generatedActors': _generatedActors,
      'generatedBindings': _generatedBindings,
      'generatedAnimations': _generatedAnimations,
      'visualTemplateFailures': _visualTemplateFailures,
      'presetsLoaded': _presetsLoaded,
      'presetSceneBuilds': _presetSceneBuilds,
      'presetActorsGenerated': _presetActorsGenerated,
      'presetAnimationsGenerated': _presetAnimationsGenerated,
      'presetFailures': _presetFailures,
      'averageRuntime': averageRuntime,
      'lastInteractionTime': _lastInteractionTime?.toIso8601String(),
      'lastInteractionSource': _lastInteractionSource,
    };
  }

  void dispose() {
    _subscription?.cancel();
  }
}
