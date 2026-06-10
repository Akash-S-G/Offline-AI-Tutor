import 'button_renderer.dart';
import '../../graphs/line_graph_renderer.dart';
import '../../observations/table_renderer.dart';
import '../../scatter/scatter_plot_renderer.dart';
import '../../scientific/bar_chart_renderer.dart';
import '../../scientific/oscilloscope_renderer.dart';
import '../../scientific/spectrum_analyzer_renderer.dart';
import '../../scientific/vector_visualizer_renderer.dart';
import 'gauge_renderer.dart';
import 'numeric_display_renderer.dart';
import 'progress_bar_renderer.dart';
import 'runtime_object_renderer.dart';
import 'slider_renderer.dart';
import 'text_display_renderer.dart';
import 'toggle_renderer.dart';

typedef RuntimeObjectRendererFactory = RuntimeObjectRenderer Function();

class RuntimeObjectRendererRegistry {
  final Map<String, RuntimeObjectRendererFactory> _factories = {};

  RuntimeObjectRendererRegistry() {
    registerDefaults();
  }

  void registerRenderer(
    String objectType,
    RuntimeObjectRendererFactory factory,
  ) {
    _factories[objectType] = factory;
  }

  RuntimeObjectRenderer? createRenderer(String objectType) {
    return _factories[objectType]?.call();
  }

  bool containsRenderer(String objectType) =>
      _factories.containsKey(objectType);

  void registerDefaults() {
    registerRenderer('numericDisplay', NumericDisplayRenderer.new);
    registerRenderer('textDisplay', TextDisplayRenderer.new);
    registerRenderer('gauge', GaugeRenderer.new);
    registerRenderer('progressBar', ProgressBarRenderer.new);
    registerRenderer('lineGraph', LineGraphRenderer.new);
    registerRenderer('scatterPlot', ScatterPlotRenderer.new);
    registerRenderer('table', TableRenderer.new);
    registerRenderer('vectorVisualizer', VectorVisualizerRenderer.new);
    registerRenderer('oscilloscope', OscilloscopeRenderer.new);
    registerRenderer('spectrumAnalyzer', SpectrumAnalyzerRenderer.new);
    registerRenderer('barChart', BarChartRenderer.new);
    registerRenderer('button', ButtonRenderer.new);
    registerRenderer('slider', SliderRenderer.new);
    registerRenderer('toggle', ToggleRenderer.new);
  }
}
