import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_event_bus.dart';
import '../analytics/experience_analytics.dart';
import '../models/experiment_step.dart';
import '../models/runtime_experience.dart';
import '../models/runtime_experience_state.dart';
import '../services/experience_progress_calculator.dart';
import 'runtime_experience_events.dart';

class RuntimeExperienceEngine extends ChangeNotifier {
  RuntimeExperienceEngine({
    required RuntimeEventBus eventBus,
    ExperienceProgressCalculator progressCalculator =
        const ExperienceProgressCalculator(),
    ExperienceAnalytics? analytics,
  }) : _eventBus = eventBus,
       _progressCalculator = progressCalculator,
       analytics = analytics ?? ExperienceAnalytics();

  final RuntimeEventBus _eventBus;
  final ExperienceProgressCalculator _progressCalculator;
  final ExperienceAnalytics analytics;
  RuntimeExperience? _experience;
  RuntimeExperienceState _state = const RuntimeExperienceState();
  StreamSubscription? _subscription;

  RuntimeExperience? get experience => _experience;
  RuntimeExperienceState get state => _state;
  ExperimentStep? get currentStep {
    final experience = _experience;
    if (experience == null || experience.steps.isEmpty) return null;
    final index = _state.currentStepIndex.clamp(0, experience.steps.length - 1);
    return experience.steps[index];
  }

  void load(RuntimeExperience experience) {
    _experience = experience;
    _state = RuntimeExperienceState(
      startedAt: DateTime.now(),
      progress: _progressCalculator.calculate(
        completedSteps: 0,
        totalSteps: experience.steps.length,
      ),
    );
    analytics.recordStarted();
    _subscription?.cancel();
    _subscription = _eventBus.stream.listen(_handleRuntimeEvent);
    _emit('ExperienceStarted', metadata: {'experienceId': experience.id});
    if (experience.steps.isNotEmpty) {
      _emitStepStarted(experience.steps.first);
    }
    notifyListeners();
  }

  void completeCurrentStep() {
    final step = currentStep;
    final experience = _experience;
    if (step == null || experience == null) return;
    if (_state.completedSteps.contains(step.id)) return;
    _completeStep(step, experience);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleRuntimeEvent(RuntimeEvent event) {
    if (_experience == null || _state.isCompleted) return;
    if (event.message == 'ExperimentFailed') {
      _emit('ExperienceFailed', metadata: {'experienceId': _experience!.id});
      return;
    }
    var observationCount = _state.observationCount;
    var questionCount = _state.questionCount;
    if (event.message == 'ObservationRecorded') observationCount++;
    if (event.message == 'QuestionAnswered') {
      questionCount++;
      analytics.recordQuestionAnswered();
    }
    if (observationCount != _state.observationCount ||
        questionCount != _state.questionCount) {
      _state = _state.copyWith(
        observationCount: observationCount,
        questionCount: questionCount,
      );
    }
    final step = currentStep;
    final experience = _experience!;
    if (step != null && step.completionCondition.evaluate(event)) {
      _completeStep(step, experience);
    }
  }

  void _completeStep(ExperimentStep step, RuntimeExperience experience) {
    final completed = {..._state.completedSteps, step.id};
    final nextIndex = _nextStepIndex(experience, completed);
    final progress = _progressCalculator.calculate(
      completedSteps: completed.length,
      totalSteps: experience.steps.length,
    );
    analytics.recordStepCompleted();
    _emit(
      'StepCompleted',
      metadata: {
        'experienceId': experience.id,
        'stepId': step.id,
        'progress': progress,
      },
    );
    final allDone = completed.length >= experience.steps.length;
    _state = _state.copyWith(
      completedSteps: completed,
      currentStepIndex: nextIndex,
      progress: progress,
      completedAt: allDone ? DateTime.now() : null,
    );
    if (allDone) {
      final started = _state.startedAt ?? DateTime.now();
      analytics.recordCompleted(
        completionRate: progress,
        duration: DateTime.now().difference(started),
      );
      _emit(
        'ExperienceCompleted',
        metadata: {'experienceId': experience.id, 'progress': progress},
      );
    } else {
      _emitStepStarted(experience.steps[nextIndex]);
    }
    notifyListeners();
  }

  int _nextStepIndex(RuntimeExperience experience, Set<String> completed) {
    for (var i = 0; i < experience.steps.length; i++) {
      if (!completed.contains(experience.steps[i].id)) return i;
    }
    return experience.steps.length - 1;
  }

  void _emitStepStarted(ExperimentStep step) {
    _emit('StepStarted', metadata: {'stepId': step.id, 'title': step.title});
  }

  void _emit(String message, {Map<String, dynamic>? metadata}) {
    _eventBus.emit(experienceEvent(message, metadata: metadata));
  }
}
