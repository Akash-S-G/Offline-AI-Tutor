import '../models/visual_motion_spec.dart';
import '../models/visual_parameter_response.dart';
import '../models/visualization_first_profile.dart';

class AnimationFirstPresetRegistry {
  const AnimationFirstPresetRegistry._();

  static const pendulum = VisualizationFirstProfile(
    presetId: 'pendulum',
    environmentId: 'physics_room',
    idleMotions: [
      VisualMotionSpec(
        id: 'pendulum_idle_swing',
        targetId: 'preset_pendulum_rod',
        motionType: 'oscillate',
        durationSeconds: 2,
        parameters: {'property': 'rotation', 'amplitude': 0.35},
      ),
      VisualMotionSpec(
        id: 'pendulum_trail_fade',
        targetId: 'preset_pendulum_trail',
        motionType: 'fade',
        durationSeconds: 1.4,
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: 'pendulum.length',
        targetId: 'preset_pendulum_rod',
        affectedProperty: 'period',
        responseDescription: 'Length changes swing period and rod length.',
      ),
      VisualParameterResponse(
        variableSemanticId: 'pendulum.angle',
        targetId: 'preset_pendulum_bob',
        affectedProperty: 'amplitude',
        responseDescription: 'Angle changes swing amplitude.',
      ),
    ],
    particleSystems: ['motion_trails'],
    graphAnimations: ['lineGraph'],
    narratedEvents: ['Pendulum speed increased', 'Pendulum length changed'],
    focusTargets: ['preset_pendulum_bob', 'preset_pendulum_rod'],
  );

  static const heartRate = VisualizationFirstProfile(
    presetId: 'heartRate',
    environmentId: 'laboratory',
    idleMotions: [
      VisualMotionSpec(
        id: 'heart_idle_pulse',
        targetId: 'preset_heart_core',
        motionType: 'pulse',
        durationSeconds: 0.8,
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: 'heartRate.bpm',
        targetId: 'preset_heart_core',
        affectedProperty: 'pulseSpeed',
        responseDescription: 'Heart rate changes pulse speed.',
      ),
    ],
    graphAnimations: ['lineGraph', 'oscilloscope'],
    narratedEvents: ['Heart rate increased', 'Pulse speed changed'],
    focusTargets: ['preset_heart_core'],
  );

  static const plantGrowth = VisualizationFirstProfile(
    presetId: 'plantGrowth',
    environmentId: 'nature',
    idleMotions: [
      VisualMotionSpec(
        id: 'plant_idle_breathe',
        targetId: 'preset_plant_stem',
        motionType: 'pulse',
        durationSeconds: 2.4,
        parameters: {'amplitude': 0.04},
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: 'plant.water',
        targetId: 'preset_plant_stem',
        affectedProperty: 'growthRate',
        responseDescription: 'Water changes plant growth response.',
      ),
      VisualParameterResponse(
        variableSemanticId: 'plant.sunlight',
        targetId: 'preset_sun',
        affectedProperty: 'brightness',
        responseDescription: 'Sunlight changes growth and brightness.',
      ),
    ],
    particleSystems: ['flow_particles'],
    graphAnimations: ['lineGraph', 'barChart'],
    narratedEvents: ['Plant growth accelerated'],
    focusTargets: ['preset_plant_stem', 'preset_sun'],
  );

  static const waterCycle = VisualizationFirstProfile(
    presetId: 'waterCycle',
    environmentId: 'nature',
    idleMotions: [
      VisualMotionSpec(
        id: 'water_cycle_particle_flow',
        targetId: 'preset_water_rain',
        motionType: 'flow',
        durationSeconds: 2,
      ),
      VisualMotionSpec(
        id: 'cloud_idle_drift',
        targetId: 'preset_water_cloud',
        motionType: 'move',
        durationSeconds: 3,
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: 'waterCycle.temperature',
        targetId: 'preset_water_rain',
        affectedProperty: 'particleSpeed',
        responseDescription: 'Temperature changes particle movement speed.',
      ),
    ],
    particleSystems: ['water_particles', 'heat_particles', 'flow_particles'],
    graphAnimations: ['lineGraph'],
    narratedEvents: ['Temperature changed', 'Water particles accelerated'],
    focusTargets: ['preset_water_rain', 'preset_water_cloud'],
  );

  static const freeFall = VisualizationFirstProfile(
    presetId: 'freeFall',
    environmentId: 'physics_room',
    idleMotions: [
      VisualMotionSpec(
        id: 'free_fall_loop_preview',
        targetId: 'preset_free_fall_object',
        motionType: 'move',
        durationSeconds: 2.2,
        parameters: {'fromY': 80, 'toY': 320},
      ),
      VisualMotionSpec(
        id: 'free_fall_motion_trail',
        targetId: 'preset_free_fall_velocity',
        motionType: 'trail',
        durationSeconds: 1,
      ),
    ],
    parameterResponses: [
      VisualParameterResponse(
        variableSemanticId: 'freeFall.height',
        targetId: 'preset_free_fall_object',
        affectedProperty: 'startHeight',
        responseDescription: 'Height changes the fall path.',
      ),
      VisualParameterResponse(
        variableSemanticId: 'freeFall.velocity',
        targetId: 'preset_free_fall_velocity',
        affectedProperty: 'trailLength',
        responseDescription: 'Velocity changes the motion trail.',
      ),
    ],
    particleSystems: ['motion_trails'],
    graphAnimations: ['lineGraph', 'scatterPlot'],
    narratedEvents: ['Ball speed increased', 'Drop height changed'],
    focusTargets: ['preset_free_fall_object', 'preset_free_fall_velocity'],
  );

  static const all = {pendulum, heartRate, plantGrowth, waterCycle, freeFall};

  static VisualizationFirstProfile? byPresetId(String presetId) {
    for (final profile in all) {
      if (profile.presetId == presetId) return profile;
    }
    return null;
  }
}
