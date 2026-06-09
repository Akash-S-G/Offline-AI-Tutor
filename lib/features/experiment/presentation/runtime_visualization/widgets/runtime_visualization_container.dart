import 'package:flutter/material.dart';

import '../controllers/runtime_visualization_controller.dart';
import 'measurement_dashboard.dart';
import 'variable_panel.dart';
import 'object_state_panel.dart';
import 'runtime_timeline.dart';
import 'runtime_statistics_panel.dart';

class RuntimeVisualizationContainer extends StatelessWidget {
  final RuntimeVisualizationController controller;

  const RuntimeVisualizationContainer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RuntimeStatisticsPanel(
                measurementsReceived: state.measurementsReceived,
                warnings: state.warnings,
                errors: state.errors,
                eventsProcessed: state.eventsProcessed,
                runtimeDuration: state.runtimeDuration,
              ),

              MeasurementDashboard(measurements: state.measurements),
              VariablePanel(variables: state.variables),
              ObjectStatePanel(objectStates: state.objectStates),

              const Divider(),
              RuntimeTimeline(timeline: state.timeline),
            ],
          ),
        );
      },
    );
  }
}
