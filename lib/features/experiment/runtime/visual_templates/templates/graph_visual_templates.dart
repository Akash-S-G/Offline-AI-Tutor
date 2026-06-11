import '../../simulation/animations/runtime_animation.dart';
import '../../simulation/bindings/runtime_visual_binding.dart';
import '../../simulation/models/runtime_actor.dart';
import '../models/runtime_visual_template_context.dart';
import 'runtime_visual_template.dart';
import 'template_utils.dart';

class LineGraphVisualTemplate extends _GraphShellTemplate {
  LineGraphVisualTemplate() : super('LineGraphVisualTemplate', 'Line Graph');
}

class ScatterPlotVisualTemplate extends _GraphShellTemplate {
  ScatterPlotVisualTemplate()
    : super('ScatterPlotVisualTemplate', 'Scatter Plot');
}

class BarChartVisualTemplate extends _GraphShellTemplate {
  BarChartVisualTemplate() : super('BarChartVisualTemplate', 'Bar Chart');
}

class OscilloscopeVisualTemplate extends _GraphShellTemplate {
  OscilloscopeVisualTemplate()
    : super('OscilloscopeVisualTemplate', 'Waveform');
}

class SpectrumAnalyzerVisualTemplate extends _GraphShellTemplate {
  SpectrumAnalyzerVisualTemplate()
    : super('SpectrumAnalyzerVisualTemplate', 'Spectrum');
}

class _GraphShellTemplate extends RuntimeVisualTemplate {
  final String _name;
  final String fallbackLabel;

  _GraphShellTemplate(this._name, this.fallbackLabel);

  @override
  String get name => _name;

  @override
  List<RuntimeActor> buildActors(RuntimeVisualTemplateContext context) {
    final label = readLabel(context);
    final x = context.originX;
    final y = context.originY;
    return [
      actor(
        id: '${context.objectId}_axis_x',
        type: 'line',
        x: x - 80,
        y: y + 40,
        state: {'width': 160, 'strokeWidth': 2, 'color': '#64748b'},
      ),
      actor(
        id: '${context.objectId}_axis_y',
        type: 'line',
        x: x - 80,
        y: y + 40,
        rotation: -1.5708,
        state: {'width': 90, 'strokeWidth': 2, 'color': '#64748b'},
      ),
      actor(
        id: '${context.objectId}_layer',
        type: 'rectangle',
        x: x,
        y: y,
        state: {
          'width': 150,
          'height': 80,
          'color': '#dbeafe',
          'text': fallbackLabel,
        },
        opacity: 0.46,
      ),
      actor(
        id: '${context.objectId}_label',
        type: 'text',
        x: x,
        y: y - 56,
        state: {'text': label, 'fontSize': 13, 'color': '#334155'},
      ),
    ];
  }

  @override
  List<RuntimeVisualBinding> buildBindings(
    RuntimeVisualTemplateContext context,
  ) {
    return const [];
  }

  @override
  List<RuntimeAnimation> buildAnimations(RuntimeVisualTemplateContext context) {
    return const [];
  }
}
