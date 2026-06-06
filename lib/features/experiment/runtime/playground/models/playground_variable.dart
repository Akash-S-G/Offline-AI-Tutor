class PlaygroundVariable {
  final String name;
  final String type;
  dynamic value;
  final dynamic minValue;
  final dynamic maxValue;
  final String? unit;

  PlaygroundVariable({
    required this.name,
    required this.type,
    required this.value,
    this.minValue,
    this.maxValue,
    this.unit,
  });
}
