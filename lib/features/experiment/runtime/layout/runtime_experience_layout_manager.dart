import '../models/runtime_object_state.dart';

class RuntimeExperienceLayout {
  final List<RuntimeObjectState> simulationObjects;
  final List<RuntimeObjectState> displayObjects;
  final List<RuntimeObjectState> controlObjects;
  final List<RuntimeObjectState> analysisObjects;
  final List<RuntimeObjectState> dataObjects;

  const RuntimeExperienceLayout({
    required this.simulationObjects,
    required this.displayObjects,
    required this.controlObjects,
    required this.analysisObjects,
    required this.dataObjects,
  });

  List<RuntimeObjectState> get displays => displayObjects;
  List<RuntimeObjectState> get controls => controlObjects;
  List<RuntimeObjectState> get visualizations => analysisObjects;
  List<RuntimeObjectState> get data => dataObjects;
}

class RuntimeWorkspaceLayout extends RuntimeExperienceLayout {
  const RuntimeWorkspaceLayout({
    required super.simulationObjects,
    required super.displayObjects,
    required super.controlObjects,
    required super.analysisObjects,
    required super.dataObjects,
  });
}

class RuntimeExperienceLayoutManager {
  static const Set<String> displayTypes = {
    'numericDisplay',
    'textDisplay',
    'gauge',
    'progressBar',
    'counter',
  };

  static const Set<String> controlTypes = {'button', 'slider', 'toggle'};

  static const Set<String> analysisTypes = {
    'lineGraph',
    'scatterPlot',
    'barChart',
    'oscilloscope',
    'spectrumAnalyzer',
    'vectorVisualizer',
  };

  static const Set<String> dataTypes = {'table'};

  RuntimeExperienceLayout build(List<RuntimeObjectState> states) {
    final visible = states.where((state) => state.visible).toList();
    return RuntimeExperienceLayout(
      simulationObjects: visible
          .where((state) => _isSimulationObject(state.objectType))
          .toList(growable: false),
      displayObjects: visible
          .where((state) => displayTypes.contains(state.objectType))
          .toList(growable: false),
      controlObjects: visible
          .where((state) => controlTypes.contains(state.objectType))
          .toList(growable: false),
      analysisObjects: visible
          .where((state) => analysisTypes.contains(state.objectType))
          .toList(growable: false),
      dataObjects: visible
          .where((state) => dataTypes.contains(state.objectType))
          .toList(growable: false),
    );
  }

  bool _isSimulationObject(String type) {
    return !displayTypes.contains(type) &&
        !controlTypes.contains(type) &&
        !analysisTypes.contains(type) &&
        !dataTypes.contains(type);
  }
}

class RuntimeWorkspaceLayoutManager extends RuntimeExperienceLayoutManager {}
