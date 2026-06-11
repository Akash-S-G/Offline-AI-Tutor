import 'package:flutter/material.dart';

class RuntimeActor {
  final String id;
  final String type;
  final double positionX;
  final double positionY;
  final double rotation;
  final double scale;
  final double opacity;
  final bool visible;
  final Map<String, dynamic> state;

  const RuntimeActor({
    required this.id,
    required this.type,
    this.positionX = 0,
    this.positionY = 0,
    this.rotation = 0,
    this.scale = 1,
    this.opacity = 1,
    this.visible = true,
    this.state = const {},
  });

  factory RuntimeActor.fromJson(Map<String, dynamic> json) {
    return RuntimeActor(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'rectangle',
      positionX: _double(json['positionX'] ?? json['x']),
      positionY: _double(json['positionY'] ?? json['y']),
      rotation: _double(json['rotation']),
      scale: _double(json['scale'], fallback: 1),
      opacity: _double(json['opacity'], fallback: 1).clamp(0, 1).toDouble(),
      visible: json['visible'] is bool ? json['visible'] as bool : true,
      state: _stateFromJson(json),
    );
  }

  RuntimeActor copyWith({
    String? id,
    String? type,
    double? positionX,
    double? positionY,
    double? rotation,
    double? scale,
    double? opacity,
    bool? visible,
    Map<String, dynamic>? state,
  }) {
    return RuntimeActor(
      id: id ?? this.id,
      type: type ?? this.type,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
      state: state ?? this.state,
    );
  }

  RuntimeActor withProperty(String property, dynamic value) {
    switch (property) {
      case 'positionX':
      case 'x':
        return copyWith(positionX: _double(value));
      case 'positionY':
      case 'y':
        return copyWith(positionY: _double(value));
      case 'rotation':
        return copyWith(rotation: _double(value));
      case 'scale':
        return copyWith(scale: _double(value, fallback: scale));
      case 'opacity':
        return copyWith(
          opacity: _double(value, fallback: opacity).clamp(0, 1).toDouble(),
        );
      case 'visible':
        return copyWith(
          visible: value is bool ? value : value.toString() == 'true',
        );
      default:
        return copyWith(state: {...state, property: value});
    }
  }

  Color color({Color fallback = Colors.teal}) {
    final raw = state['color'];
    if (raw is Color) return raw;
    if (raw is int) return Color(raw);
    if (raw is String) {
      final normalized = raw.replaceFirst('#', '');
      final parsed = int.tryParse(
        normalized.length == 6 ? 'ff$normalized' : normalized,
        radix: 16,
      );
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'positionX': positionX,
      'positionY': positionY,
      'rotation': rotation,
      'scale': scale,
      'opacity': opacity,
      'visible': visible,
      'state': state,
    };
  }

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic> _stateFromJson(Map<String, dynamic> json) {
    final state = <String, dynamic>{};
    if (json['state'] is Map) {
      state.addAll(Map<String, dynamic>.from(json['state'] as Map));
    }
    for (final entry in json.entries) {
      if (!_reservedKeys.contains(entry.key)) {
        state[entry.key] = entry.value;
      }
    }
    return state;
  }

  static const _reservedKeys = {
    'id',
    'type',
    'positionX',
    'positionY',
    'x',
    'y',
    'rotation',
    'scale',
    'opacity',
    'visible',
    'state',
  };
}
