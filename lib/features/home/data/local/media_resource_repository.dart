import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';

class MediaResource {
  const MediaResource({
    this.id,
    required this.mediaType,
    required this.title,
    required this.localPath,
    this.sourcePath,
    required this.sizeBytes,
    required this.importedAt,
  });

  final int? id;
  final String mediaType; // textbook | video
  final String title;
  final String localPath;
  final String? sourcePath;
  final int sizeBytes;
  final int importedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'media_type': mediaType,
      'title': title,
      'local_path': localPath,
      'source_path': sourcePath,
      'size_bytes': sizeBytes,
      'imported_at': importedAt,
    };
  }

  factory MediaResource.fromMap(Map<String, dynamic> row) {
    return MediaResource(
      id: row['id'] as int?,
      mediaType: row['media_type'] as String? ?? 'unknown',
      title: row['title'] as String? ?? '',
      localPath: row['local_path'] as String? ?? '',
      sourcePath: row['source_path'] as String?,
      sizeBytes: row['size_bytes'] as int? ?? 0,
      importedAt: row['imported_at'] as int? ?? 0,
    );
  }
}

class MediaResourceRepository {
  MediaResourceRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> upsert(MediaResource resource) async {
    final db = await _database.database;
    await db.insert(
      'media_resources',
      <String, dynamic>{
        'media_type': resource.mediaType,
        'title': resource.title,
        'local_path': resource.localPath,
        'source_path': resource.sourcePath,
        'size_bytes': resource.sizeBytes,
        'imported_at': resource.importedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMany(List<MediaResource> resources) async {
    if (resources.isEmpty) {
      return;
    }

    final db = await _database.database;
    final batch = db.batch();
    for (final resource in resources) {
      batch.insert(
        'media_resources',
        <String, dynamic>{
          'media_type': resource.mediaType,
          'title': resource.title,
          'local_path': resource.localPath,
          'source_path': resource.sourcePath,
          'size_bytes': resource.sizeBytes,
          'imported_at': resource.importedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<MediaResource>> listByType(String mediaType) async {
    final db = await _database.database;
    final rows = await db.query(
      'media_resources',
      where: 'media_type = ?',
      whereArgs: <Object?>[mediaType],
      orderBy: 'imported_at DESC',
    );
    return rows.map((row) => MediaResource.fromMap(row)).toList();
  }

  Future<List<MediaResource>> listAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'media_resources',
      orderBy: 'media_type ASC, imported_at DESC',
    );
    return rows.map((row) => MediaResource.fromMap(row)).toList();
  }

  Future<void> deleteByPath(String localPath) async {
    final db = await _database.database;
    await db.delete(
      'media_resources',
      where: 'local_path = ?',
      whereArgs: <Object?>[localPath],
    );
  }
}
