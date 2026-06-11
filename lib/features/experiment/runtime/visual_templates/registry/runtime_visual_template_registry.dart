import '../templates/gauge_visual_template.dart';
import '../templates/graph_visual_templates.dart';
import '../templates/numeric_display_visual_template.dart';
import '../templates/progress_bar_visual_template.dart';
import '../templates/runtime_visual_template.dart';
import '../templates/vector_visualizer_visual_template.dart';

class RuntimeVisualTemplateRegistry {
  final Map<String, RuntimeVisualTemplate> _templates = {};

  RuntimeVisualTemplateRegistry() {
    registerDefaults();
  }

  void register(String objectType, RuntimeVisualTemplate template) {
    _templates[objectType] = template;
  }

  RuntimeVisualTemplate? templateFor(String objectType) {
    return _templates[objectType];
  }

  bool supports(String objectType) => _templates.containsKey(objectType);

  void registerDefaults() {
    register('numericDisplay', NumericDisplayVisualTemplate());
    register('counter', NumericDisplayVisualTemplate());
    register('textDisplay', NumericDisplayVisualTemplate());
    register('gauge', GaugeVisualTemplate());
    register('progressBar', ProgressBarVisualTemplate());
    register('lineGraph', LineGraphVisualTemplate());
    register('scatterPlot', ScatterPlotVisualTemplate());
    register('barChart', BarChartVisualTemplate());
    register('vectorVisualizer', VectorVisualizerVisualTemplate());
    register('oscilloscope', OscilloscopeVisualTemplate());
    register('spectrumAnalyzer', SpectrumAnalyzerVisualTemplate());
  }
}
