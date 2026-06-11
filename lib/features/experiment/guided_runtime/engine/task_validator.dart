import '../../runtime/runtime_event.dart';
import '../../runtime/runtime_world.dart';
import '../conditions/task_completion_condition.dart';

class TaskValidator {
  bool validate(
    TaskCompletionCondition condition,
    RuntimeWorld runtime, {
    RuntimeEvent? event,
    Set<String> answeredQuestions = const {},
    Set<String> correctlyAnsweredQuestions = const {},
  }) {
    switch (condition) {
      case VariableReachedValueCondition():
        return _validateVariable(condition, runtime);
      case ControlUsedCondition():
        return _validateControl(condition, event);
      case ObservationCreatedCondition():
        return runtime.observationStore.rowCount >= condition.requiredCount;
      case MeasurementCapturedCondition():
        return _validateMeasurement(condition, runtime);
      case GraphViewedCondition():
        return _validateGraph(condition, event);
      case QuestionAnsweredCondition():
        return _validateQuestion(
          condition,
          answeredQuestions,
          correctlyAnsweredQuestions,
        );
      case TimerElapsedCondition():
        return runtime.clock.elapsedTime >= condition.duration.inSeconds;
      case TrialCompletedCondition():
        return _validateTrial(condition, event);
      case ComparisonCompletedCondition():
        return event?.message == 'ComparisonCompleted';
      case ConclusionGeneratedCondition():
        return event?.message == 'ConclusionGenerated';
      default:
        return false;
    }
  }

  bool _validateVariable(
    VariableReachedValueCondition condition,
    RuntimeWorld runtime,
  ) {
    final value = runtime.variables.getValue(condition.variableId);
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null) return false;
    switch (condition.operator) {
      case '>':
        return number > condition.targetValue;
      case '<':
        return number < condition.targetValue;
      case '<=':
        return number <= condition.targetValue;
      case '==':
      case '=':
        return number == condition.targetValue;
      case '!=':
        return number != condition.targetValue;
      case '>=':
      default:
        return number >= condition.targetValue;
    }
  }

  bool _validateControl(ControlUsedCondition condition, RuntimeEvent? event) {
    if (event == null) return false;
    if (event.message != 'SliderChanged' &&
        event.message != 'ButtonPressed' &&
        event.message != 'ToggleChanged' &&
        event.message != 'ToggleEnabled' &&
        event.message != 'ToggleDisabled') {
      return false;
    }
    final objectId = event.metadata?['objectId']?.toString();
    if (condition.controlId != null && condition.controlId != objectId) {
      return false;
    }
    final message = event.message.toLowerCase();
    if (condition.controlType != null &&
        !message.contains(condition.controlType!.toLowerCase())) {
      return false;
    }
    return true;
  }

  bool _validateMeasurement(
    MeasurementCapturedCondition condition,
    RuntimeWorld runtime,
  ) {
    if (condition.variableId != null && condition.variableId!.isNotEmpty) {
      return runtime.measurementStore.sampleCount(condition.variableId!) >=
          condition.requiredCount;
    }
    final total = runtime.measurementStore.trackedVariableIds.fold<int>(
      0,
      (sum, id) => sum + runtime.measurementStore.sampleCount(id),
    );
    return total >= condition.requiredCount;
  }

  bool _validateGraph(GraphViewedCondition condition, RuntimeEvent? event) {
    if (event == null) return false;
    if (event.message != 'GraphUpdated' && event.message != 'GraphViewed') {
      return false;
    }
    final graphId =
        event.metadata?['graphId']?.toString() ??
        event.metadata?['objectId']?.toString();
    return condition.graphId == null || condition.graphId == graphId;
  }

  bool _validateQuestion(
    QuestionAnsweredCondition condition,
    Set<String> answeredQuestions,
    Set<String> correctlyAnsweredQuestions,
  ) {
    final questionId = condition.questionId;
    if (questionId == null || questionId.isEmpty) {
      return condition.requireCorrect
          ? correctlyAnsweredQuestions.isNotEmpty
          : answeredQuestions.isNotEmpty;
    }
    return condition.requireCorrect
        ? correctlyAnsweredQuestions.contains(questionId)
        : answeredQuestions.contains(questionId);
  }

  bool _validateTrial(TrialCompletedCondition condition, RuntimeEvent? event) {
    if (event?.message != 'TrialCompleted') return false;
    final count = event?.metadata?['trialNumber'];
    if (count is num) return count >= condition.minimumTrials;
    return condition.minimumTrials <= 1;
  }
}
