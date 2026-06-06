import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../runtime/runtime_event.dart';
import '../models/visualization_state.dart';

class RuntimeVisualizationController extends ChangeNotifier {
  VisualizationState _state = VisualizationState.initial();
  VisualizationState get state => _state;

  StreamSubscription<RuntimeEvent>? _subscription;
  DateTime? _startTime;
  Timer? _durationTimer;

  // Debouncing UI updates for performance (max 60fps)
  Timer? _updateTimer;
  bool _needsUpdate = false;

  void attachStream(Stream<RuntimeEvent> eventStream) {
    _subscription?.cancel();
    
    // Process incoming events synchronously for logic, but batch UI updates
    _subscription = eventStream.listen((event) {
      _processEvent(event);
      _scheduleUpdate();
    });

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        _state = _state.copyWith(
          runtimeDuration: DateTime.now().difference(_startTime!),
        );
        notifyListeners();
      }
    });
  }

  void _processEvent(RuntimeEvent event) {
    // We modify mutable maps locally before creating a copy to save allocations
    final newVariables = Map<String, dynamic>.from(_state.variables);
    final newObjectStates = Map<String, Map<String, dynamic>>.from(_state.objectStates);
    final newMeasurements = Map<String, Map<String, dynamic>>.from(_state.measurements);
    final newTimeline = List<RuntimeEvent>.from(_state.timeline);
    
    int newMeasurementsReceived = _state.measurementsReceived;
    int newWarnings = _state.warnings;
    int newErrors = _state.errors;
    int newEventsProcessed = _state.eventsProcessed + 1;

    // 1. Process Payload Specifics
    if (event.type == RuntimeEventType.measurementReceived) {
      newMeasurementsReceived++;
      if (event.metadata != null) {
        final sensorType = event.metadata!['sensorType'] as String? ?? 'unknown';
        final data = event.metadata!['data'] as Map<String, dynamic>? ?? {};
        newMeasurements[sensorType] = data;
      }
    } else if (event.type == RuntimeEventType.custom && event.message.contains('Playground event')) {
      final pType = event.metadata?['playgroundEventType'];
      final payload = event.metadata?['payload'] as Map<String, dynamic>?;

      if (pType == 'variableChanged' && payload != null) {
        final name = payload['name'] as String?;
        final value = payload['value'];
        if (name != null) newVariables[name] = value;
      } else if (pType == 'objectUpdated' && payload != null) {
        final objectId = payload['objectId'] as String?;
        final stateMap = payload['state'] as Map<String, dynamic>?;
        if (objectId != null && stateMap != null) {
          newObjectStates[objectId] = stateMap;
        }
      }
    } else if (event.type == RuntimeEventType.warning) {
      newWarnings++;
    } else if (event.type == RuntimeEventType.error) {
      newErrors++;
    } else if (event.type == RuntimeEventType.sessionStarted) {
      _startTime = DateTime.now();
    } else if (event.type == RuntimeEventType.sessionCompleted || event.type == RuntimeEventType.sessionStopped) {
      _startTime = null; // Pause duration calculation
    }

    // 2. Add to timeline (cap at 100)
    newTimeline.insert(0, event);
    if (newTimeline.length > 100) {
      newTimeline.removeLast();
    }

    // 3. Update internal state pointer (listeners not yet notified)
    _state = _state.copyWith(
      variables: newVariables,
      objectStates: newObjectStates,
      measurements: newMeasurements,
      timeline: newTimeline,
      measurementsReceived: newMeasurementsReceived,
      warnings: newWarnings,
      errors: newErrors,
      eventsProcessed: newEventsProcessed,
    );
  }

  void _scheduleUpdate() {
    if (_needsUpdate) return;
    _needsUpdate = true;
    
    // Batch UI updates to roughly 60fps (16ms)
    _updateTimer ??= Timer(const Duration(milliseconds: 16), () {
      if (_needsUpdate) {
        notifyListeners();
        _needsUpdate = false;
        _updateTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _durationTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}
