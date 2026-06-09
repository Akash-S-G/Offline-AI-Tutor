class RuntimeGraphPoint {
  final double x;
  final double y;

  const RuntimeGraphPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}
