import '../models/experiment_mission.dart';
import '../models/experiment_task.dart';

class GuidedRuntimeState {
  final ExperimentMission? mission;
  final ExperimentTask? currentTask;
  final Set<String> completedTasks;
  final double progress;
  final bool missionCompleted;

  const GuidedRuntimeState({
    this.mission,
    this.currentTask,
    this.completedTasks = const {},
    this.progress = 0,
    this.missionCompleted = false,
  });

  const GuidedRuntimeState.empty() : this();

  GuidedRuntimeState copyWith({
    ExperimentMission? mission,
    ExperimentTask? currentTask,
    Set<String>? completedTasks,
    double? progress,
    bool? missionCompleted,
  }) {
    return GuidedRuntimeState(
      mission: mission ?? this.mission,
      currentTask: currentTask ?? this.currentTask,
      completedTasks: completedTasks ?? this.completedTasks,
      progress: progress ?? this.progress,
      missionCompleted: missionCompleted ?? this.missionCompleted,
    );
  }
}
