import 'button_renderer.dart';
import '../../graphs/line_graph_renderer.dart';
import '../../observations/table_renderer.dart';
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
    registerRenderer('table', TableRenderer.new);
    registerRenderer('button', ButtonRenderer.new);
    registerRenderer('slider', SliderRenderer.new);
    registerRenderer('toggle', ToggleRenderer.new);
  }
}
