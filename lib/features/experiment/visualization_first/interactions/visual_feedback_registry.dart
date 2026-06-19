import 'visual_feedback_profile.dart';

class VisualFeedbackRegistry {
  const VisualFeedbackRegistry._();

  static const controlChange = VisualFeedbackProfile(
    trigger: 'control_changed',
    targetCategory: 'affected_actor',
    effects: ['flash', 'pulse', 'reading_highlight'],
  );

  static const graphUpdate = VisualFeedbackProfile(
    trigger: 'measurement_added',
    targetCategory: 'graph',
    effects: ['pulse_latest_point', 'soft_glow'],
  );

  static const observationSaved = VisualFeedbackProfile(
    trigger: 'observation_saved',
    targetCategory: 'observation',
    effects: ['capture_flash', 'card_motion'],
  );

  static const all = {controlChange, graphUpdate, observationSaved};
}
