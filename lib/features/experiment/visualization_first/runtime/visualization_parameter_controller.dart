import 'dart:async';

import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../../runtime/simulation/canvas/runtime_simulation_canvas.dart';
import '../interactions/visual_cause_effect_event.dart';
import '../models/visualization_first_profile.dart';
import '../narration/visual_event_narrator.dart';

class VisualizationParameterController {
  VisualizationParameterController({
    required RuntimeEventBus eventBus,
    required RuntimeSimulationCanvas canvas,
    required VisualizationFirstProfile profile,
  }) : _eventBus = eventBus,
       _canvas = canvas,
       _profile = profile;

  final RuntimeEventBus _eventBus;
  final RuntimeSimulationCanvas _canvas;
  final VisualizationFirstProfile _profile;
  final VisualEventNarrator _narrator = const VisualEventNarrator();
  StreamSubscription<RuntimeEvent>? _subscription;

  void attach() {
    _subscription?.cancel();
    _subscription = _eventBus.stream.listen(_onEvent);
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _onEvent(RuntimeEvent event) {
    if (!_reactiveMessages.contains(event.message)) return;
    final sourceId =
        event.metadata?['variableId']?.toString() ??
        event.metadata?['objectId']?.toString() ??
        event.metadata?['label']?.toString() ??
        '*';
    final response = _profile.parameterResponses.firstWhere(
      (item) =>
          item.variableSemanticId == '*' ||
          _matches(sourceId, item.variableSemanticId),
      orElse: () => _profile.parameterResponses.first,
    );
    final targetId = response.targetId == '*'
        ? _fallbackActorId()
        : response.targetId;
    if (targetId == null) return;
    final actor = _canvas.actor(targetId);
    if (actor != null) {
      final pulseScale = (actor.scale * 1.08).clamp(0.5, 2.4).toDouble();
      _canvas.updateActor(actor.copyWith(scale: pulseScale, opacity: 1));
    }
    final visualEvent = VisualCauseEffectEvent(
      sourceId: sourceId,
      targetId: targetId,
      changedValueLabel: event.metadata?['value']?.toString() ?? 'changed',
      visualResponse: response.responseDescription,
    );
    _eventBus.emit(
      RuntimeEvent(
        id: 'VisualResponseTriggered_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: 'VisualResponseTriggered',
        metadata: {
          'sourceId': sourceId,
          'targetId': targetId,
          'response': response.responseDescription,
        },
      ),
    );
    _eventBus.emit(
      RuntimeEvent(
        id: 'VisualNarrationShown_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: RuntimeEventType.custom,
        message: 'VisualNarrationShown',
        metadata: {'message': _narrator.narrate(visualEvent)},
      ),
    );
  }

  bool _matches(String sourceId, String semanticId) {
    final normalizedSource = _normalize(sourceId);
    final normalizedSemantic = _normalize(semanticId);
    return normalizedSource.contains(normalizedSemantic) ||
        normalizedSemantic.contains(normalizedSource);
  }

  String? _fallbackActorId() {
    for (final actor in _canvas.actors) {
      if (actor.visible && actor.type != 'text') return actor.id;
    }
    return _canvas.actors.isEmpty ? null : _canvas.actors.first.id;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const _reactiveMessages = {
    'VariableUpdated',
    'VariableChanged',
    'MeasurementCaptured',
    'MeasurementCollected',
    'ObservationRecorded',
    'ButtonPressed',
    'SliderChanged',
    'ToggleChanged',
    'ToggleEnabled',
    'ToggleDisabled',
  };
}
