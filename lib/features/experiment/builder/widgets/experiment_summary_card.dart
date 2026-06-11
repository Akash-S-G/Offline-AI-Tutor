import 'package:flutter/material.dart';

import '../models/experiment_builder_state.dart';

class ExperimentSummary {
  final int variables;
  final int objects;
  final int rules;
  final int sensors;
  final int displays;
  final int graphs;
  final int interactive;

  const ExperimentSummary({
    required this.variables,
    required this.objects,
    required this.rules,
    required this.sensors,
    required this.displays,
    required this.graphs,
    required this.interactive,
  });
}

class ExperimentSummaryCard extends StatelessWidget {
  final ExperimentBuilderState state;

  const ExperimentSummaryCard({super.key, required this.state});

  static ExperimentSummary summarize(ExperimentBuilderState state) {
    const sensorTypes = {
      'accelerometer',
      'gyroscope',
      'magnetometer',
      'gps',
      'lightSensor',
      'proximity',
      'microphone',
      'barometer',
    };
    const displayTypes = {
      'numericDisplay',
      'textDisplay',
      'gauge',
      'progressBar',
    };
    const graphTypes = {
      'lineGraph',
      'scatterPlot',
      'barChart',
      'oscilloscope',
      'spectrumAnalyzer',
      'vectorVisualizer',
      'table',
    };
    const interactiveTypes = {'button', 'slider', 'toggle'};
    return ExperimentSummary(
      variables: state.variables.length,
      objects: state.objects.length,
      rules: state.rules.length,
      sensors: state.variables
          .where((variable) => sensorTypes.contains(variable.type))
          .length,
      displays: state.objects
          .where((object) => displayTypes.contains(object.type))
          .length,
      graphs: state.objects
          .where((object) => graphTypes.contains(object.type))
          .length,
      interactive: state.objects
          .where((object) => interactiveTypes.contains(object.type))
          .length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarize(state);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Experiment Summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Readings', summary.variables),
                _chip('Instruments', summary.objects),
                _chip('Interactions', summary.rules),
                _chip('Sensors', summary.sensors),
                _chip('Displays', summary.displays),
                _chip('Graphs', summary.graphs),
                _chip('Interactive', summary.interactive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}
