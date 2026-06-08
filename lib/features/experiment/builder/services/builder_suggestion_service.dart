import '../models/builder_variable.dart';
import '../models/builder_object.dart';
import '../models/builder_rule.dart';

class BuilderSuggestionService {
  static List<String> getSuggestions({
    required List<BuilderVariable> variables,
    required List<BuilderObject> objects,
    required List<BuilderRule> rules,
  }) {
    final suggestions = <String>{};

    if (variables.isEmpty) {
      suggestions.add('Add an Accelerometer or GPS variable');
      return suggestions.toList();
    }

    final hasAccelerometer = variables.any((v) => v.type == 'accelerometer');
    final hasGPS = variables.any((v) => v.type == 'gps');
    final hasMicrophone = variables.any((v) => v.type == 'microphone');

    final hasGraph = objects.any((o) => o.type == 'lineGraph');
    final hasMap = objects.any((o) => o.type == 'scatterPlot' || o.name.toLowerCase().contains('map'));
    final hasOscilloscope = objects.any((o) => o.type == 'oscilloscope' || o.type == 'spectrumAnalyzer');

    if (hasAccelerometer && !hasGraph) {
      suggestions.add('Create a Line Graph to visualize acceleration');
      suggestions.add('Add a Gauge for live sensor values');
      suggestions.add('Create a Vector Visualizer');
    }

    if (hasGPS && !hasMap) {
      suggestions.add('Add a Map Display (Scatter Plot)');
      suggestions.add('Create a Distance Calculator Rule');
    }

    if (hasMicrophone && !hasOscilloscope) {
      suggestions.add('Add a Spectrum Analyzer');
      suggestions.add('Create an Oscilloscope');
    }

    if (objects.isNotEmpty && rules.isEmpty) {
      suggestions.add('Create a Threshold Rule to trigger actions');
      suggestions.add('Add a Timer Rule');
    }

    if (variables.isNotEmpty && objects.isNotEmpty && rules.isNotEmpty) {
      suggestions.add('Preview Experiment');
    }

    return suggestions.toList().take(3).toList();
  }
}
