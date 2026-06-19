class ParticleSystemProfile {
  final String id;
  final String name;
  final String particleType;
  final int maxParticles;
  final double spawnRatePerSecond;
  final double averageLifetimeSeconds;
  final Map<String, dynamic> parameters;

  const ParticleSystemProfile({
    required this.id,
    required this.name,
    required this.particleType,
    this.maxParticles = 80,
    this.spawnRatePerSecond = 12,
    this.averageLifetimeSeconds = 2,
    this.parameters = const {},
  });

  bool get isMobileSafe {
    return maxParticles <= 160 &&
        spawnRatePerSecond <= 40 &&
        averageLifetimeSeconds <= 6;
  }
}
