import 'runtime_scatter_point.dart';

class ScatterPlotState {
  final List<RuntimeScatterPoint> points;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final DateTime updatedAt;
  final String? xVariableId;
  final String? yVariableId;

  const ScatterPlotState({
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.updatedAt,
    this.xVariableId,
    this.yVariableId,
  });

  ScatterPlotState.empty({this.xVariableId, this.yVariableId})
    : points = const [],
      minX = 0,
      maxX = 0,
      minY = 0,
      maxY = 0,
      updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  int get pointCount => points.length;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(growable: false),
      'pointCount': pointCount,
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
      'updatedAt': updatedAt.toIso8601String(),
      'xVariableId': xVariableId,
      'yVariableId': yVariableId,
    };
  }
}
