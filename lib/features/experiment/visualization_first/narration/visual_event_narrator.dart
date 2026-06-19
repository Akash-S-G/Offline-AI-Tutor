import '../interactions/visual_cause_effect_event.dart';

class VisualEventNarrator {
  const VisualEventNarrator();

  String narrate(VisualCauseEffectEvent event) {
    final source = _humanize(event.sourceId);
    final target = _humanize(event.targetId);
    final value = event.changedValueLabel;

    if (event.sourceId.toLowerCase().contains('length')) {
      return 'Pendulum length changed. Watch how the swing responds.';
    }
    if (event.sourceId.toLowerCase().contains('heart') ||
        event.sourceId.toLowerCase().contains('bpm')) {
      return 'Heart rate changed. The pulse animation responds.';
    }
    if (event.sourceId.toLowerCase().contains('temperature')) {
      return 'Temperature changed. Particle motion responds.';
    }
    if (event.sourceId.toLowerCase().contains('growth')) {
      return 'Growth factor changed. The plant animation responds.';
    }
    return '$source changed to $value. $target is responding.';
  }

  String _humanize(String value) {
    return value
        .replaceAll(RegExp(r'[_\-.]+'), ' ')
        .replaceAll(RegExp(r'\bvar\b'), '')
        .trim();
  }
}
