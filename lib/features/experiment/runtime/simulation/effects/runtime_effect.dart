class RuntimeEffect {
  final String id;
  final String actorId;
  final String type;
  final bool enabled;
  final Map<String, dynamic> state;

  const RuntimeEffect({
    required this.id,
    required this.actorId,
    required this.type,
    this.enabled = true,
    this.state = const {},
  });
}

class ParticleEffect extends RuntimeEffect {
  const ParticleEffect({
    required super.id,
    required super.actorId,
    super.enabled,
    super.state,
  }) : super(type: 'particle');
}

class GlowEffect extends RuntimeEffect {
  const GlowEffect({
    required super.id,
    required super.actorId,
    super.enabled,
    super.state,
  }) : super(type: 'glow');
}

class TrailEffect extends RuntimeEffect {
  const TrailEffect({
    required super.id,
    required super.actorId,
    super.enabled,
    super.state,
  }) : super(type: 'trail');
}

class RippleEffect extends RuntimeEffect {
  const RippleEffect({
    required super.id,
    required super.actorId,
    super.enabled,
    super.state,
  }) : super(type: 'ripple');
}
