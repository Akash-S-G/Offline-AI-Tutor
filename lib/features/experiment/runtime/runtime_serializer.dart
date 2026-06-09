import 'runtime_world.dart';

class RuntimeSerializer {
  static Map<String, dynamic> serialize(RuntimeWorld world) {
    return {
      'variables': world.variables.allVariables,
      'objects': world.objects.allObjects,
      'elapsedTime': world.clock.elapsedTime,
      'profile': world.profile.name,
    };
  }

  static void restore(RuntimeWorld world, Map<String, dynamic> state) {
    if (state.containsKey('variables')) {
      final vars = state['variables'] as Map<String, dynamic>;
      vars.forEach((key, value) {
        world.variables.set(key, value);
      });
    }

    if (state.containsKey('objects')) {
      final objs = state['objects'] as List<dynamic>;
      for (var obj in objs) {
        final id = obj['objectId'] ?? obj['id'];
        if (id != null) {
          final props = obj['properties'] as Map<String, dynamic>? ?? {};
          props.forEach((propKey, propVal) {
            world.objects.updateProperty(id, propKey, propVal);
          });
        }
      }
    }
    
    // Elapsed time can be restored if the clock supports it.
  }
}
