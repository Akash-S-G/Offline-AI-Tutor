import 'playground_object.dart';
import 'playground_variable.dart';
import 'playground_rule.dart';

class PlaygroundScene {
  final String sceneId;
  final String name;
  final String description;
  final List<PlaygroundObject> objects;
  final List<PlaygroundVariable> variables;
  final List<PlaygroundRule> rules;
  final Map<String, dynamic>? metadata;

  PlaygroundScene({
    required this.sceneId,
    required this.name,
    required this.description,
    required this.objects,
    required this.variables,
    required this.rules,
    this.metadata,
  });
}
