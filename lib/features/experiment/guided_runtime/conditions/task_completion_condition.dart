abstract class TaskCompletionCondition {
  final String type;

  const TaskCompletionCondition(this.type);

  Map<String, dynamic> toJson();

  factory TaskCompletionCondition.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'custom';
    switch (type) {
      case 'variableReachedValue':
      case 'variable':
        return VariableReachedValueCondition.fromJson(json);
      case 'controlUsed':
      case 'control':
        return ControlUsedCondition.fromJson(json);
      case 'observationCreated':
      case 'observation':
        return ObservationCreatedCondition.fromJson(json);
      case 'measurementCaptured':
      case 'measurement':
        return MeasurementCapturedCondition.fromJson(json);
      case 'graphViewed':
      case 'graph':
        return GraphViewedCondition.fromJson(json);
      case 'questionAnswered':
      case 'question':
        return QuestionAnsweredCondition.fromJson(json);
      case 'timerElapsed':
      case 'timer':
        return TimerElapsedCondition.fromJson(json);
      case 'trialCompleted':
      case 'trial':
        return TrialCompletedCondition.fromJson(json);
      case 'comparisonCompleted':
      case 'comparison':
        return ComparisonCompletedCondition.fromJson(json);
      case 'conclusionGenerated':
      case 'conclusion':
        return ConclusionGeneratedCondition.fromJson(json);
      default:
        return const AlwaysIncompleteCondition();
    }
  }
}

class AlwaysIncompleteCondition extends TaskCompletionCondition {
  const AlwaysIncompleteCondition() : super('custom');

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

class VariableReachedValueCondition extends TaskCompletionCondition {
  final String variableId;
  final double targetValue;
  final String operator;

  const VariableReachedValueCondition({
    required this.variableId,
    required this.targetValue,
    this.operator = '>=',
  }) : super('variableReachedValue');

  factory VariableReachedValueCondition.fromJson(Map<String, dynamic> json) {
    return VariableReachedValueCondition(
      variableId: json['variableId']?.toString() ?? '',
      targetValue: _doubleFromJson(json['targetValue'] ?? json['value']),
      operator: json['operator']?.toString() ?? '>=',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'variableId': variableId,
    'targetValue': targetValue,
    'operator': operator,
  };
}

class ControlUsedCondition extends TaskCompletionCondition {
  final String? controlId;
  final String? controlType;

  const ControlUsedCondition({this.controlId, this.controlType})
    : super('controlUsed');

  factory ControlUsedCondition.fromJson(Map<String, dynamic> json) {
    return ControlUsedCondition(
      controlId: json['controlId']?.toString() ?? json['objectId']?.toString(),
      controlType: json['controlType']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (controlId != null) 'controlId': controlId,
    if (controlType != null) 'controlType': controlType,
  };
}

class ObservationCreatedCondition extends TaskCompletionCondition {
  final int requiredCount;

  const ObservationCreatedCondition({this.requiredCount = 1})
    : super('observationCreated');

  factory ObservationCreatedCondition.fromJson(Map<String, dynamic> json) {
    return ObservationCreatedCondition(
      requiredCount: _intFromJson(json['requiredCount'] ?? json['count'], 1),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'requiredCount': requiredCount,
  };
}

class MeasurementCapturedCondition extends TaskCompletionCondition {
  final String? variableId;
  final int requiredCount;

  const MeasurementCapturedCondition({this.variableId, this.requiredCount = 1})
    : super('measurementCaptured');

  factory MeasurementCapturedCondition.fromJson(Map<String, dynamic> json) {
    return MeasurementCapturedCondition(
      variableId: json['variableId']?.toString(),
      requiredCount: _intFromJson(json['requiredCount'] ?? json['count'], 1),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (variableId != null) 'variableId': variableId,
    'requiredCount': requiredCount,
  };
}

class GraphViewedCondition extends TaskCompletionCondition {
  final String? graphId;

  const GraphViewedCondition({this.graphId}) : super('graphViewed');

  factory GraphViewedCondition.fromJson(Map<String, dynamic> json) {
    return GraphViewedCondition(
      graphId: json['graphId']?.toString() ?? json['objectId']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (graphId != null) 'graphId': graphId,
  };
}

class QuestionAnsweredCondition extends TaskCompletionCondition {
  final String? questionId;
  final bool requireCorrect;

  const QuestionAnsweredCondition({
    this.questionId,
    this.requireCorrect = false,
  }) : super('questionAnswered');

  factory QuestionAnsweredCondition.fromJson(Map<String, dynamic> json) {
    return QuestionAnsweredCondition(
      questionId: json['questionId']?.toString(),
      requireCorrect: json['requireCorrect'] == true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (questionId != null) 'questionId': questionId,
    'requireCorrect': requireCorrect,
  };
}

class TimerElapsedCondition extends TaskCompletionCondition {
  final Duration duration;

  const TimerElapsedCondition({required this.duration}) : super('timerElapsed');

  factory TimerElapsedCondition.fromJson(Map<String, dynamic> json) {
    return TimerElapsedCondition(
      duration: Duration(
        seconds: _intFromJson(json['seconds'] ?? json['durationSeconds'], 0),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'seconds': duration.inSeconds,
  };
}

class TrialCompletedCondition extends TaskCompletionCondition {
  final int minimumTrials;

  const TrialCompletedCondition({this.minimumTrials = 1})
    : super('trialCompleted');

  factory TrialCompletedCondition.fromJson(Map<String, dynamic> json) {
    return TrialCompletedCondition(
      minimumTrials: _intFromJson(
        json['minimumTrials'] ?? json['requiredCount'] ?? json['count'],
        1,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'minimumTrials': minimumTrials,
  };
}

class ComparisonCompletedCondition extends TaskCompletionCondition {
  const ComparisonCompletedCondition() : super('comparisonCompleted');

  factory ComparisonCompletedCondition.fromJson(Map<String, dynamic> json) {
    return const ComparisonCompletedCondition();
  }

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

class ConclusionGeneratedCondition extends TaskCompletionCondition {
  const ConclusionGeneratedCondition() : super('conclusionGenerated');

  factory ConclusionGeneratedCondition.fromJson(Map<String, dynamic> json) {
    return const ConclusionGeneratedCondition();
  }

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

double _doubleFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _intFromJson(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
