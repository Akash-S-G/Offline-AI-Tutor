import 'runtime_graph_point.dart';

class LineGraphState {
  final List<RuntimeGraphPoint> points;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final int sampleCount;
  final String? linkedVariableId;

  const LineGraphState({
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.sampleCount,
    this.linkedVariableId,
  });

  const LineGraphState.empty({this.linkedVariableId})
    : points = const [],
      minX = 0,
      maxX = 0,
      minY = 0,
      maxY = 0,
      sampleCount = 0;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(growable: false),
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
      'sampleCount': sampleCount,
      'linkedVariableId': linkedVariableId,
    };
  }
}
