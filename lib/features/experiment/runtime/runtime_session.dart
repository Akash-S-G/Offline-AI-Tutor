import '../domain/enums/experiment_enums.dart';
import 'runtime_event.dart';
import 'runtime_metrics.dart';

class RuntimeSession {
  final String sessionId;
  final String experimentId;
  final ExperimentExecutionMode executionMode;
  
  ExperimentStatus status;
  DateTime? startedAt;
  DateTime? endedAt;
  Duration elapsedTime = Duration.zero;
  
  final List<RuntimeEvent> events = [];
  final RuntimeMetrics metrics;

  RuntimeSession({
    required this.sessionId,
    required this.experimentId,
    required this.executionMode,
    this.status = ExperimentStatus.draft,
    required this.metrics,
  });

  void start() {
    status = ExperimentStatus.running;
    startedAt = DateTime.now();
    metrics.startTime = startedAt;
  }

  void pause() {
    status = ExperimentStatus.paused;
  }

  void resume() {
    status = ExperimentStatus.running;
  }

  void stop() {
    status = ExperimentStatus.completed;
    endedAt = DateTime.now();
    if (startedAt != null) {
      elapsedTime = endedAt!.difference(startedAt!);
    }
  }
}
