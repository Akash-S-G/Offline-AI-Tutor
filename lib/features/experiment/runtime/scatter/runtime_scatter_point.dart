class RuntimeScatterPoint {
  final double x;
  final double y;

  const RuntimeScatterPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }
}
