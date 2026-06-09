import 'button_behavior.dart';
import 'gauge_behavior.dart';
import 'numeric_display_behavior.dart';
import 'progress_bar_behavior.dart';
import 'runtime_object_behavior.dart';
import 'slider_behavior.dart';
import 'text_display_behavior.dart';
import 'toggle_behavior.dart';

typedef RuntimeObjectBehaviorFactory = RuntimeObjectBehavior Function();

class RuntimeObjectBehaviorRegistry {
  final Map<String, RuntimeObjectBehaviorFactory> _factories = {};

  RuntimeObjectBehaviorRegistry() {
    registerDefaults();
  }

  void registerBehavior(
    String objectType,
    RuntimeObjectBehaviorFactory factory,
  ) {
    _factories[objectType] = factory;
  }

  RuntimeObjectBehavior? createBehavior(String objectType) {
    return _factories[objectType]?.call();
  }

  bool containsBehavior(String objectType) =>
      _factories.containsKey(objectType);

  void registerDefaults() {
    registerBehavior('numericDisplay', NumericDisplayBehavior.new);
    registerBehavior('textDisplay', TextDisplayBehavior.new);
    registerBehavior('gauge', GaugeBehavior.new);
    registerBehavior('progressBar', ProgressBarBehavior.new);
    registerBehavior('button', ButtonBehavior.new);
    registerBehavior('slider', SliderBehavior.new);
    registerBehavior('toggle', ToggleBehavior.new);
  }
}
