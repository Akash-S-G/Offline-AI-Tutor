class RuntimeObjectLayout {
  final double x;
  final double y;
  final double width;
  final double height;
  final String alignment;

  const RuntimeObjectLayout({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.alignment,
  });

  factory RuntimeObjectLayout.fromJson(Map<String, dynamic> json) {
    final layout = Map<String, dynamic>.from(
      json['layout'] as Map? ?? const {},
    );
    final properties = Map<String, dynamic>.from(
      json['properties'] as Map? ?? const {},
    );
    return RuntimeObjectLayout(
      x: _readDouble(layout, properties, 'x', 0),
      y: _readDouble(layout, properties, 'y', 0),
      width: _readDouble(layout, properties, 'width', 180),
      height: _readDouble(layout, properties, 'height', 96),
      alignment:
          layout['alignment']?.toString() ??
          properties['alignment']?.toString() ??
          'center',
    );
  }

  RuntimeObjectLayout copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? alignment,
  }) {
    return RuntimeObjectLayout(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'alignment': alignment,
    };
  }

  static double _readDouble(
    Map<String, dynamic> layout,
    Map<String, dynamic> properties,
    String key,
    double fallback,
  ) {
    final value = layout[key] ?? properties[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
