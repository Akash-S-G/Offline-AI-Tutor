import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';

class StudyNote {
  const StudyNote({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String body;
  final int createdAt;
  final int updatedAt;

  factory StudyNote.fromMap(Map<String, dynamic> row) {
    return StudyNote(
      id: row['id'] as int?,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: row['created_at'] as int? ?? 0,
      updatedAt: row['updated_at'] as int? ?? 0,
    );
  }
}

class StudyNoteRepository {
  StudyNoteRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<StudyNote>> listAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'study_notes',
      orderBy: 'updated_at DESC',
    );
    return rows.map(StudyNote.fromMap).toList();
  }

  Future<StudyNote> create({
    required String title,
    required String body,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert(
      'study_notes',
      <String, dynamic>{
        'title': title,
        'body': body,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return StudyNote(
      id: id,
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update({
    required int id,
    required String title,
    required String body,
  }) async {
    final db = await _database.database;
    await db.update(
      'study_notes',
      <String, dynamic>{
        'title': title,
        'body': body,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete(
      'study_notes',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
