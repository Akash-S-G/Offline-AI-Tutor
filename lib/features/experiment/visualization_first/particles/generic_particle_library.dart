import 'particle_system_profile.dart';

class GenericParticleLibrary {
  const GenericParticleLibrary._();

  static const flow = ParticleSystemProfile(
    id: 'flow_particles',
    name: 'Flow Particles',
    particleType: 'flow',
    maxParticles: 120,
    spawnRatePerSecond: 22,
    parameters: {'motion': 'stream', 'trail': true},
  );

  static const heat = ParticleSystemProfile(
    id: 'heat_particles',
    name: 'Heat Particles',
    particleType: 'heat',
    maxParticles: 90,
    spawnRatePerSecond: 18,
    parameters: {'motion': 'rise', 'jitter': 0.18},
  );

  static const water = ParticleSystemProfile(
    id: 'water_particles',
    name: 'Water Particles',
    particleType: 'water',
    maxParticles: 140,
    spawnRatePerSecond: 26,
    parameters: {'motion': 'fall_and_cycle', 'gravity': 0.35},
  );

  static const spark = ParticleSystemProfile(
    id: 'spark_particles',
    name: 'Spark Particles',
    particleType: 'spark',
    maxParticles: 70,
    spawnRatePerSecond: 14,
    averageLifetimeSeconds: 1.2,
    parameters: {'motion': 'burst', 'fade': true},
  );

  static const motionTrail = ParticleSystemProfile(
    id: 'motion_trails',
    name: 'Motion Trails',
    particleType: 'trail',
    maxParticles: 110,
    spawnRatePerSecond: 28,
    averageLifetimeSeconds: 1.5,
    parameters: {'motion': 'follow_actor', 'fade': true},
  );

  static const all = {flow, heat, water, spark, motionTrail};
}
