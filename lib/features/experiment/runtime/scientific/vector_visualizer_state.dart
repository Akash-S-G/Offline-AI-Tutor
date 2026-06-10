class VectorVisualizerState {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final double direction;
  final String unit;
  final DateTime updatedAt;

  const VectorVisualizerState({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.direction,
    required this.unit,
    required this.updatedAt,
  });

  factory VectorVisualizerState.empty({String unit = ''}) {
    return VectorVisualizerState(
      x: 0,
      y: 0,
      z: 0,
      magnitude: 0,
      direction: 0,
      unit: unit,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toObjectState() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'magnitude': magnitude,
      'direction': direction,
      'unit': unit,
    };
  }
}
