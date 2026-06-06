// ignore_for_file: avoid_print

import '../domain/models/experiment_models.dart';
import '../domain/enums/experiment_enums.dart';
import 'experiment_device_capabilities.dart';

class ExperimentCapabilityReport {
  final List<ExperimentExecutionMode> supportedModes;
  final List<String> unsupportedRequirements;
  final double sensorCoverage;
  final bool simulationPossible;
  final bool fullyExecutable;
  final ExperimentExecutionMode recommendedMode;

  ExperimentCapabilityReport({
    required this.supportedModes,
    required this.unsupportedRequirements,
    required this.sensorCoverage,
    required this.simulationPossible,
    required this.fullyExecutable,
    required this.recommendedMode,
  });
}

class ExperimentCapabilityAnalyzer {
  ExperimentCapabilityReport analyze(
    ExperimentManifest experiment,
    ExperimentDeviceCapabilities capabilities,
  ) {
    print('[EXPERIMENT] CAPABILITY_ANALYSIS_START');

    final unsupportedRequirements = <String>[];
    int supportedSensorCount = 0;

    for (final sensor in experiment.requiredSensors) {
      if (capabilities.hasCapability(sensor)) {
        supportedSensorCount++;
      } else {
        unsupportedRequirements.add(sensor);
      }
    }

    final int totalRequired = experiment.requiredSensors.length;
    final double sensorCoverage =
        totalRequired == 0 ? 100.0 : (supportedSensorCount / totalRequired) * 100.0;

    print('[EXPERIMENT] SENSOR_COVERAGE=${sensorCoverage.toStringAsFixed(1)}');

    final supportedModes = <ExperimentExecutionMode>[];

    // Determine Supported Modes based on metadata and capabilities
    bool supportsSensor = experiment.supportsSensorExecution && sensorCoverage == 100.0;
    bool supportsHybrid = experiment.supportsSensorExecution && sensorCoverage > 0 && sensorCoverage < 100.0 && experiment.supportsSimulation;
    bool supportsSim = experiment.supportsSimulation;
    bool supportsObs = experiment.supportsObservationMode;

    if (supportsSensor) supportedModes.add(ExperimentExecutionMode.sensor);
    if (supportsHybrid) supportedModes.add(ExperimentExecutionMode.hybrid);
    if (supportsSim) supportedModes.add(ExperimentExecutionMode.simulation);
    if (supportsObs) supportedModes.add(ExperimentExecutionMode.observation);

    ExperimentExecutionMode recommendedMode = ExperimentExecutionMode.observation;

    if (supportsSensor) {
      recommendedMode = ExperimentExecutionMode.sensor;
    } else if (supportsHybrid) {
      recommendedMode = ExperimentExecutionMode.hybrid;
    } else if (supportsSim) {
      recommendedMode = ExperimentExecutionMode.simulation;
    }

    print('[EXPERIMENT] RECOMMENDED_MODE=${recommendedMode.name.toUpperCase()}');

    final bool fullyExecutable = supportedModes.isNotEmpty;

    return ExperimentCapabilityReport(
      supportedModes: supportedModes,
      unsupportedRequirements: unsupportedRequirements,
      sensorCoverage: sensorCoverage,
      simulationPossible: supportsSim,
      fullyExecutable: fullyExecutable,
      recommendedMode: recommendedMode,
    );
  }
}
