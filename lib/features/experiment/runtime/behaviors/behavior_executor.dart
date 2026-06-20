import 'behavior.dart';
import 'behavior_registry.dart';

/// Blueprint descriptor for a single behavior entry from the JSON.
class BehaviorDescriptor {
  final String type;
  final String target;
  final Map<String, dynamic> params;

  const BehaviorDescriptor({
    required this.type,
    required this.target,
    this.params = const {},
  });

  factory BehaviorDescriptor.fromJson(Map<String, dynamic> json) {
    return BehaviorDescriptor(
      type: json['type'] as String,
      target: json['target'] as String? ?? '',
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
    );
  }
}

/// Executes all behaviors declared in a scene blueprint every frame.
class BehaviorExecutor {
  final List<BehaviorDescriptor> _descriptors;

  BehaviorExecutor(List<Map<String, dynamic>> rawBehaviors)
      : _descriptors = rawBehaviors
            .map(BehaviorDescriptor.fromJson)
            .toList();

  /// Called every animation frame. Ticks each registered behavior.
  void tick({
    required double time,
    required Map<String, double> variables,
    required void Function(String key, double value) setOutput,
  }) {
    for (final descriptor in _descriptors) {
      final behavior = BehaviorRegistry.resolve(descriptor.type);
      if (behavior == null) continue;

      final context = BehaviorContext(
        variables: variables,
        params: descriptor.params,
        setOutput: setOutput,
      );

      behavior.tick(time, context);
    }
  }
}
