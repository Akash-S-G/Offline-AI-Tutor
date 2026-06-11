import 'package:flutter/foundation.dart';

import '../models/experiment_blueprint.dart';
import 'guided_progress_tracker.dart';
import 'guided_question_engine.dart';

class GuidedExperimentEngine extends ChangeNotifier {
  final ExperimentBlueprint blueprint;
  late GuidedProgressTracker _progress;
  late GuidedQuestionEngine _questions;
  int _currentStepIndex = 0;
  DateTime? _startedAt;
  DateTime? _completedAt;

  GuidedExperimentEngine({required this.blueprint}) {
    _progress = GuidedProgressTracker(
      objectiveCount: blueprint.objectives
          .where((item) => item.required)
          .length,
      questionCount: blueprint.questions.where((item) => item.required).length,
      requiredObservationRows: blueprint.observationTemplate.requiredRows,
      stepCount: _stepCount,
    );
    _questions = GuidedQuestionEngine(questions: blueprint.questions);
  }

  GuidedProgressTracker get progress => _progress;
  GuidedQuestionEngine get questions => _questions;
  int get currentStepIndex => _currentStepIndex;
  String get currentObjective => blueprint.objectives.isEmpty
      ? blueprint.description
      : blueprint
            .objectives[_currentStepIndex.clamp(
              0,
              blueprint.objectives.length - 1,
            )]
            .title;
  bool get complete => _completedAt != null || _progress.complete;
  Duration get elapsed =>
      (_completedAt ?? DateTime.now()).difference(_startedAt ?? DateTime.now());

  void start() {
    _startedAt ??= DateTime.now();
    notifyListeners();
  }

  void completeObjective(String title) {
    _progress = _progress.copyWith(
      completedObjectives: {..._progress.completedObjectives, title},
    );
    _advance();
  }

  void recordObservationRow() {
    _progress = _progress.copyWith(
      observationRows: _progress.observationRows + 1,
    );
    _advance();
  }

  void submitAnswer(String questionId, dynamic answer) {
    _questions.submitAnswer(questionId, answer);
    _progress = _progress.copyWith(
      answeredQuestions: {..._progress.answeredQuestions, questionId},
    );
    _advance();
  }

  void completeStep(String stepId) {
    _progress = _progress.copyWith(
      completedSteps: {..._progress.completedSteps, stepId},
    );
    _advance();
  }

  void _advance() {
    if (_progress.complete) {
      _completedAt ??= DateTime.now();
    } else {
      _currentStepIndex++;
    }
    notifyListeners();
  }

  int get _stepCount {
    var count = 2; // read objective + finish
    if (blueprint.parameters.isNotEmpty) count++;
    if (blueprint.questions.isNotEmpty) count++;
    if (blueprint.observationTemplate.requiredRows > 0) count++;
    return count;
  }
}
