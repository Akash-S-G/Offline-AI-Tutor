import '../../models/runtime_object_state.dart';
import '../../runtime_world.dart';

class RuntimeVisualTemplateContext {
  final RuntimeObjectState objectState;
  final Map<String, dynamic>? builderObject;
  final RuntimeWorld world;
  final Map<String, dynamic> runtimeConfig;
  final double originX;
  final double originY;

  const RuntimeVisualTemplateContext({
    required this.objectState,
    required this.world,
    required this.runtimeConfig,
    this.builderObject,
    this.originX = 0,
    this.originY = 0,
  });

  String get objectId => objectState.objectId;
}
