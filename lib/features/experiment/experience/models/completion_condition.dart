import '../../runtime/runtime_event.dart';

abstract class CompletionCondition {
  const CompletionCondition();

  String get type;

  bool evaluate(RuntimeEvent event);

  Map<String, dynamic> toJson();

  factory CompletionCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const CustomCondition();
    switch (json['type']?.toString()) {
      case 'variable':
      case 'variableUpdated':
        return VariableCondition(variableId: json['variableId']?.toString());
      case 'observation':
        return const ObservationCondition();
      case 'graphViewed':
      case 'graph':
        return const GraphViewedCondition();
      case 'controlUsed':
      case 'interaction':
        return ControlUsedCondition(controlId: json['controlId']?.toString());
      case 'sensor':
        return SensorCondition(sensorType: json['sensorType']?.toString());
      case 'questionAnswered':
      case 'question':
        return QuestionAnsweredCondition(
          questionId: json['questionId']?.toString(),
        );
      case 'custom':
      default:
        return CustomCondition(eventName: json['eventName']?.toString());
    }
  }
}

class VariableCondition extends CompletionCondition {
  final String? variableId;

  const VariableCondition({this.variableId});

  @override
  String get type => 'variable';

  @override
  bool evaluate(RuntimeEvent event) {
    if (event.message != 'VariableUpdated') return false;
    return variableId == null ||
        event.metadata?['variableId']?.toString() == variableId;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (variableId != null) 'variableId': variableId,
  };
}

class ObservationCondition extends CompletionCondition {
  const ObservationCondition();

  @override
  String get type => 'observation';

  @override
  bool evaluate(RuntimeEvent event) => event.message == 'ObservationRecorded';

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

class GraphViewedCondition extends CompletionCondition {
  const GraphViewedCondition();

  @override
  String get type => 'graphViewed';

  @override
  bool evaluate(RuntimeEvent event) {
    return event.message == 'GraphUpdated' ||
        event.message == 'ScatterPlotUpdated' ||
        event.message == 'BarChartUpdated';
  }

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

class ControlUsedCondition extends CompletionCondition {
  final String? controlId;

  const ControlUsedCondition({this.controlId});

  @override
  String get type => 'controlUsed';

  @override
  bool evaluate(RuntimeEvent event) {
    final matchesEvent =
        event.message == 'ButtonPressed' ||
        event.message == 'SliderChanged' ||
        event.message == 'ToggleChanged' ||
        event.message == 'ToggleEnabled' ||
        event.message == 'ToggleDisabled';
    if (!matchesEvent) return false;
    return controlId == null ||
        event.metadata?['objectId']?.toString() == controlId;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (controlId != null) 'controlId': controlId,
  };
}

class SensorCondition extends CompletionCondition {
  final String? sensorType;

  const SensorCondition({this.sensorType});

  @override
  String get type => 'sensor';

  @override
  bool evaluate(RuntimeEvent event) {
    if (event.message != 'SensorMeasurementReceived') return false;
    return sensorType == null ||
        event.metadata?['sensorType']?.toString() == sensorType;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (sensorType != null) 'sensorType': sensorType,
  };
}

class QuestionAnsweredCondition extends CompletionCondition {
  final String? questionId;

  const QuestionAnsweredCondition({this.questionId});

  @override
  String get type => 'questionAnswered';

  @override
  bool evaluate(RuntimeEvent event) {
    if (event.message != 'QuestionAnswered') return false;
    return questionId == null ||
        event.metadata?['questionId']?.toString() == questionId;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (questionId != null) 'questionId': questionId,
  };
}

class CustomCondition extends CompletionCondition {
  final String? eventName;

  const CustomCondition({this.eventName});

  @override
  String get type => 'custom';

  @override
  bool evaluate(RuntimeEvent event) {
    return eventName == null || event.message == eventName;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (eventName != null) 'eventName': eventName,
  };
}
