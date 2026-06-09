import 'package:sqflite/sqflite.dart';
import '../domain/saved_exploration.dart';
import '../../course/data/local/app_database.dart';

class ExplorationRepository {
  final Database _db;

  ExplorationRepository(this._db);

  static Future<ExplorationRepository> create() async {
    final db = await AppDatabase.instance.database;
    await _initTable(db);
    return ExplorationRepository(db);
  }

  static Future<void> _initTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS math_explorations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveExploration(SavedExploration exploration) async {
    await _db.insert(
      'math_explorations',
      exploration.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SavedExploration>> getAllExplorations() async {
    final maps = await _db.query(
      'math_explorations',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => SavedExploration.fromMap(map)).toList();
  }

  Future<void> deleteExploration(String id) async {
    await _db.delete(
      'math_explorations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> renameExploration(String id, String newTitle) async {
    await _db.update(
      'math_explorations',
      {
        'title': newTitle,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
