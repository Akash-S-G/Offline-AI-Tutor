import 'package:flutter/material.dart';
import 'variable_registry.dart';

enum ExperimentObjectType {
  lineGraph,
  barChart,
  scatterPlot,

  textDisplay,
  numericDisplay,
  table,

  button,
  slider,
  toggle,

  gauge,
  counter,
  progressBar,

  oscilloscope,
  spectrumAnalyzer,
  vectorVisualizer,
}

class ObjectDefinition {
  final ExperimentObjectType type;
  final String title;
  final String description;
  final IconData icon;
  final String exampleUsage;
  final List<VariableCategory> supportedVariableCategories;

  const ObjectDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.exampleUsage,
    required this.supportedVariableCategories,
  });
}

class ObjectRegistry {
  static const List<ObjectDefinition> definitions = [
    // Visualizations
    ObjectDefinition(
      type: ExperimentObjectType.lineGraph,
      title: 'Line Graph',
      description: 'Visualize changing values over time',
      icon: Icons.show_chart,
      exampleUsage: 'Track temperature changes during a reaction.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed, VariableCategory.timer],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.barChart,
      title: 'Bar Chart',
      description: 'Compare categorical quantities',
      icon: Icons.bar_chart,
      exampleUsage: 'Compare the mass of different samples.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.scatterPlot,
      title: 'Scatter Plot',
      description: 'Visualize relationships between two variables',
      icon: Icons.scatter_plot,
      exampleUsage: 'Plot distance vs time to find speed.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed],
    ),

    // Displays
    ObjectDefinition(
      type: ExperimentObjectType.textDisplay,
      title: 'Text Display',
      description: 'Show text content',
      icon: Icons.text_snippet,
      exampleUsage: 'Show instructions or status messages.',
      supportedVariableCategories: [VariableCategory.userInput, VariableCategory.constant],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.numericDisplay,
      title: 'Numeric Display',
      description: 'Display a large numeric value',
      icon: Icons.pin,
      exampleUsage: 'Show the exact current speed.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed, VariableCategory.timer],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.table,
      title: 'Data Table',
      description: 'Show values in a tabular format',
      icon: Icons.table_chart,
      exampleUsage: 'Log measurements side-by-side.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed],
    ),

    // Interactive
    ObjectDefinition(
      type: ExperimentObjectType.button,
      title: 'Button',
      description: 'Trigger an action or rule',
      icon: Icons.smart_button,
      exampleUsage: 'Click to start the countdown.',
      supportedVariableCategories: [VariableCategory.userInput],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.slider,
      title: 'Slider UI',
      description: 'Interactive control for numeric values',
      icon: Icons.linear_scale,
      exampleUsage: 'Drag to adjust the applied force.',
      supportedVariableCategories: [VariableCategory.userInput],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.toggle,
      title: 'Toggle Switch',
      description: 'Interactive boolean switch',
      icon: Icons.toggle_on,
      exampleUsage: 'Flip to turn the heat on or off.',
      supportedVariableCategories: [VariableCategory.userInput],
    ),

    // Gauges
    ObjectDefinition(
      type: ExperimentObjectType.gauge,
      title: 'Gauge',
      description: 'Display live sensor values on a dial',
      icon: Icons.speed,
      exampleUsage: 'Monitor pressure with a needle dial.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.counter,
      title: 'Counter',
      description: 'Incremental value tracker',
      icon: Icons.plus_one,
      exampleUsage: 'Count the number of collisions.',
      supportedVariableCategories: [VariableCategory.userInput, VariableCategory.timer],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.progressBar,
      title: 'Progress Bar',
      description: 'Visualize completion percentage',
      icon: Icons.hourglass_full,
      exampleUsage: 'Show remaining battery life.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.timer],
    ),

    // Scientific
    ObjectDefinition(
      type: ExperimentObjectType.oscilloscope,
      title: 'Oscilloscope',
      description: 'Visualize signal waveforms',
      icon: Icons.waves,
      exampleUsage: 'Observe sound wave frequencies.',
      supportedVariableCategories: [VariableCategory.sensor],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.spectrumAnalyzer,
      title: 'Spectrum Analyzer',
      description: 'Frequency domain visualizer',
      icon: Icons.graphic_eq,
      exampleUsage: 'Analyze light emission spectrum.',
      supportedVariableCategories: [VariableCategory.sensor],
    ),
    ObjectDefinition(
      type: ExperimentObjectType.vectorVisualizer,
      title: 'Vector Visualizer',
      description: 'Display 3D motion/force vectors',
      icon: Icons.open_with,
      exampleUsage: 'Show direction and magnitude of gravity.',
      supportedVariableCategories: [VariableCategory.sensor, VariableCategory.computed],
    ),
  ];
}
