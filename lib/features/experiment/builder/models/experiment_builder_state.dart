import 'builder_variable.dart';
import 'builder_object.dart';
import 'builder_rule.dart';
import 'builder_scene.dart';

class ExperimentBuilderState {
  final BuilderScene scene;
  final List<BuilderVariable> variables;
  final List<BuilderObject> objects;
  final List<BuilderRule> rules;

  ExperimentBuilderState({
    required this.scene,
    required this.variables,
    required this.objects,
    required this.rules,
  });

  ExperimentBuilderState copyWith({
    BuilderScene? scene,
    List<BuilderVariable>? variables,
    List<BuilderObject>? objects,
    List<BuilderRule>? rules,
  }) {
    return ExperimentBuilderState(
      scene: scene ?? this.scene,
      variables: variables ?? this.variables,
      objects: objects ?? this.objects,
      rules: rules ?? this.rules,
    );
  }

  factory ExperimentBuilderState.initial() {
    return ExperimentBuilderState(
      scene: BuilderScene(
        id: 'new_scene',
        name: 'Untitled Experiment',
        description: '',
        tags: [],
      ),
      variables: [],
      objects: [],
      rules: [],
    );
  }

  Map<String, dynamic> generateManifestJson() {
    final sceneJson = scene.toJson();
    sceneJson['variables'] = variables.map((v) => v.toJson()).toList();
    sceneJson['objects'] = objects.map((o) => o.toJson()).toList();
    sceneJson['rules'] = rules.map((r) => r.toJson()).toList();

    final Map<String, dynamic> manifest = {
      'scene': sceneJson,
    };
    return manifest;
  }
}
