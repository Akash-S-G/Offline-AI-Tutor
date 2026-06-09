import 'runtime_object_layout.dart';

class RuntimeObjectState {
  static const Object _unset = Object();

  final String objectId;
  final String objectType;
  final Map<String, dynamic> state;
  final bool visible;
  final DateTime updatedAt;
  final RuntimeObjectLayout layout;

  const RuntimeObjectState({
    required this.objectId,
    required this.objectType,
    required this.state,
    required this.visible,
    required this.updatedAt,
    required this.layout,
  });

  factory RuntimeObjectState.fromObjectJson(Map<String, dynamic> json) {
    return RuntimeObjectState(
      objectId: json['objectId']?.toString() ?? json['id']?.toString() ?? '',
      objectType:
          json['objectType']?.toString() ?? json['type']?.toString() ?? '',
      state: Map<String, dynamic>.from(json['state'] as Map? ?? const {}),
      visible: json['visible'] == false ? false : true,
      updatedAt: DateTime.now(),
      layout: RuntimeObjectLayout.fromJson(json),
    );
  }

  RuntimeObjectState copyWith({
    String? objectId,
    String? objectType,
    Map<String, dynamic>? state,
    Object? visible = _unset,
    DateTime? updatedAt,
    RuntimeObjectLayout? layout,
  }) {
    return RuntimeObjectState(
      objectId: objectId ?? this.objectId,
      objectType: objectType ?? this.objectType,
      state: state ?? this.state,
      visible: identical(visible, _unset) ? this.visible : visible as bool,
      updatedAt: updatedAt ?? this.updatedAt,
      layout: layout ?? this.layout,
    );
  }

  RuntimeObjectState withProperty(String property, dynamic value) {
    return copyWith(
      state: {...state, property: value},
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'objectType': objectType,
      'state': state,
      'visible': visible,
      'updatedAt': updatedAt.toIso8601String(),
      'layout': layout.toJson(),
    };
  }
}
