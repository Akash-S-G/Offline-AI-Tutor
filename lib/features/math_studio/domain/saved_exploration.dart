import 'dart:convert';

enum ExplorationType {
  algebra,
  geometry,
  functions,
  statistics,
  formulaPlayground,
}

class SavedExploration {
  final String id;
  final String title;
  final ExplorationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedExploration({
    required this.id,
    required this.title,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedExploration.create({
    required String title,
    required ExplorationType type,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now();
    return SavedExploration(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      data: data,
      createdAt: now,
      updatedAt: now,
    );
  }

  SavedExploration copyWith({
    String? title,
    Map<String, dynamic>? data,
  }) {
    return SavedExploration(
      id: id,
      title: title ?? this.title,
      type: type,
      data: data ?? this.data,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'data': jsonEncode(data),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedExploration.fromMap(Map<String, dynamic> map) {
    return SavedExploration(
      id: map['id'],
      title: map['title'],
      type: ExplorationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ExplorationType.algebra,
      ),
      data: jsonDecode(map['data'] as String),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
