import '../models/runtime_actor.dart';
import 'arrow_actor.dart';
import 'circle_actor.dart';
import 'image_actor.dart';
import 'line_actor.dart';
import 'particle_actor.dart';
import 'rectangle_actor.dart';
import 'text_actor.dart';

typedef RuntimeActorBuilder = RuntimeActor Function(Map<String, dynamic> json);

class RuntimeActorRegistry {
  final Map<String, RuntimeActorBuilder> _builders = {};

  RuntimeActorRegistry() {
    registerDefaults();
  }

  void register(String type, RuntimeActorBuilder builder) {
    _builders[type] = builder;
  }

  void registerDefaults() {
    register('circle', CircleActor.fromJson);
    register('rectangle', RectangleActor.fromJson);
    register('line', LineActor.fromJson);
    register('arrow', ArrowActor.fromJson);
    register('text', TextActor.fromJson);
    register('image', ImageActor.fromJson);
    register('particle', ParticleActor.fromJson);
  }

  RuntimeActor create(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'rectangle';
    final builder = _builders[type];
    if (builder != null) return builder(json);
    return RuntimeActor.fromJson({...json, 'type': type});
  }

  bool supports(String type) => _builders.containsKey(type);
}
