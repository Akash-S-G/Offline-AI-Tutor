import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../../runtime/runtime_world.dart';
import '../analytics/guided_runtime_analytics.dart';
import '../events/guided_runtime_events.dart';
import '../models/experiment_mission.dart';
import '../models/experiment_question.dart';
import '../models/experiment_task.dart';
import 'guided_runtime_state.dart';
import 'task_progress_tracker.dart';
import 'task_validator.dart';

class GuidedExperimentEngine extends ChangeNotifier {
  final RuntimeWorld runtime;
  final RuntimeEventBus eventBus;
  final TaskValidator validator;
  final TaskProgressTracker progressTracker;
  final GuidedRuntimeAnalytics analytics;

  StreamSubscription<RuntimeEvent>? _subscription;
  ExperimentMission? _mission;
  int _currentTaskIndex = 0;
  final Set<String> _completedTaskIds = {};
  final Set<String> _answeredQuestionIds = {};
  final Set<String> _correctQuestionIds = {};
  final Map<String, String> _answers = {};
  GuidedRuntimeState _state = const GuidedRuntimeState.empty();

  GuidedExperimentEngine({
    required this.runtime,
    required this.eventBus,
    TaskValidator? validator,
    TaskProgressTracker? progressTracker,
    GuidedRuntimeAnalytics? analytics,
  }) : validator = validator ?? TaskValidator(),
       progressTracker = progressTracker ?? TaskProgressTracker(),
       analytics = analytics ?? GuidedRuntimeAnalytics();

  GuidedRuntimeState get state => _state;
  ExperimentMission? get mission => _mission;
  ExperimentTask? get currentTask => _state.currentTask;
  Map<String, String> get answers => Map.unmodifiable(_answers);

  void loadMission(ExperimentMission mission) {
    _subscription?.cancel();
    _mission = mission;
    _currentTaskIndex = _firstIncompleteTaskIndex(mission.tasks);
    _completedTaskIds
      ..clear()
      ..addAll(
        mission.tasks.where((task) => task.completed).map((task) => task.id),
      );
    _answeredQuestionIds.clear();
    _correctQuestionIds.clear();
    _answers.clear();
    _subscription = eventBus.stream.listen(_handleRuntimeEvent);
    _setState(_buildState());
  }

  void startMission() {
    if (_mission == null) return;
    analytics.missionsStarted++;
    final task = currentTask;
    if (task != null) analytics.tasksStarted++;
    eventBus.emit(
      guidedRuntimeEvent(
        'MissionStarted',
        metadata: {'missionId': _mission!.id, 'taskId': task?.id},
      ),
    );
  }

  void completeTask([String? taskId]) {
    final mission = _mission;
    if (mission == null || mission.tasks.isEmpty) return;
    final task = taskId == null
        ? currentTask
        : _taskById(mission.tasks, taskId);
    if (task == null || _completedTaskIds.contains(task.id)) return;
    _completedTaskIds.add(task.id);
    analytics.tasksCompleted++;
    eventBus.emit(
      guidedRuntimeEvent(
        'TaskCompleted',
        metadata: {'missionId': mission.id, 'taskId': task.id},
      ),
    );
    advanceTask();
  }

  void advanceTask() {
    final mission = _mission;
    if (mission == null) return;
    final next = mission.tasks.indexWhere(
      (task) => !_completedTaskIds.contains(task.id),
    );
    if (next < 0) {
      completeMission();
      return;
    }
    _currentTaskIndex = next;
    analytics.tasksStarted++;
    eventBus.emit(
      guidedRuntimeEvent(
        'TaskStarted',
        metadata: {'missionId': mission.id, 'taskId': mission.tasks[next].id},
      ),
    );
    _setState(_buildState());
  }

  void completeMission() {
    final mission = _mission;
    if (mission == null) return;
    if (!_state.missionCompleted) analytics.missionsCompleted++;
    eventBus.emit(
      guidedRuntimeEvent(
        'MissionCompleted',
        metadata: {'missionId': mission.id},
      ),
    );
    _setState(_buildState(missionCompleted: true));
  }

  bool answerQuestion(String questionId, String answer) {
    final question = _questionById(_mission?.questions ?? const [], questionId);
    final correct = question?.isCorrect(answer) ?? answer.trim().isNotEmpty;
    _answers[questionId] = answer;
    _answeredQuestionIds.add(questionId);
    analytics.questionsAnswered++;
    if (correct) {
      _correctQuestionIds.add(questionId);
      analytics.questionsCorrect++;
    } else {
      analytics.questionsIncorrect++;
    }
    eventBus.emit(
      guidedRuntimeEvent(
        'QuestionAnswered',
        metadata: {
          'questionId': questionId,
          'answer': answer,
          'correct': correct,
        },
      ),
    );
    _validateCurrentTask();
    notifyListeners();
    return correct;
  }

  void _handleRuntimeEvent(RuntimeEvent event) {
    if (_state.missionCompleted) return;
    _validateCurrentTask(event: event);
  }

  void _validateCurrentTask({RuntimeEvent? event}) {
    final task = currentTask;
    if (task == null) return;
    final complete = validator.validate(
      task.condition,
      runtime,
      event: event,
      answeredQuestions: _answeredQuestionIds,
      correctlyAnsweredQuestions: _correctQuestionIds,
    );
    if (complete) completeTask(task.id);
  }

  GuidedRuntimeState _buildState({bool? missionCompleted}) {
    final mission = _mission;
    if (mission == null) return const GuidedRuntimeState.empty();
    final currentTask =
        mission.tasks.isEmpty || _currentTaskIndex >= mission.tasks.length
        ? null
        : mission.tasks[_currentTaskIndex];
    final completed = Set<String>.unmodifiable(_completedTaskIds);
    final completedMission =
        missionCompleted ??
        (mission.tasks.isNotEmpty && completed.length == mission.tasks.length);
    return GuidedRuntimeState(
      mission: mission,
      currentTask: completedMission ? null : currentTask,
      completedTasks: completed,
      progress: progressTracker.progress(
        completedTasks: completed.length,
        totalTasks: mission.tasks.length,
      ),
      missionCompleted: completedMission,
    );
  }

  void _setState(GuidedRuntimeState next) {
    _state = next;
    notifyListeners();
  }

  int _firstIncompleteTaskIndex(List<ExperimentTask> tasks) {
    final index = tasks.indexWhere((task) => !task.completed);
    return index < 0 ? 0 : index;
  }

  ExperimentTask? _taskById(List<ExperimentTask> tasks, String id) {
    final index = tasks.indexWhere((task) => task.id == id);
    return index < 0 ? null : tasks[index];
  }

  ExperimentQuestion? _questionById(
    List<ExperimentQuestion> questions,
    String id,
  ) {
    final index = questions.indexWhere((question) => question.id == id);
    return index < 0 ? null : questions[index];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
