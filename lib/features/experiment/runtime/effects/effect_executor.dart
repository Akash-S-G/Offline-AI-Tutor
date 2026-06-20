import 'effect.dart';
import 'effect_registry.dart';

/// Descriptor parsed from a blueprint JSON effects array entry.
class EffectDescriptor {
  final String type;
  final Map<String, dynamic> params;

  const EffectDescriptor({required this.type, this.params = const {}});

  factory EffectDescriptor.fromJson(Map<String, dynamic> json) {
    return EffectDescriptor(
      type: json['type'] as String,
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
    );
  }
}

/// Executes all effects declared in the scene blueprint JSON each frame.
/// Called from the CustomPainter with the current [EffectContext].
class EffectExecutor {
  final List<EffectDescriptor> _descriptors;

  EffectExecutor(List<dynamic> rawEffects)
      : _descriptors = rawEffects
            .map((e) => EffectDescriptor.fromJson(e as Map<String, dynamic>))
            .toList();

  /// Draw all active effects onto the canvas.
  void tick(EffectContext context) {
    for (final descriptor in _descriptors) {
      final effect = EffectRegistry.resolve(descriptor.type);
      if (effect == null) continue;
      effect.tick(context, descriptor.params);
    }
  }
}
