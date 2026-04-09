import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../course/data/local/app_database.dart';
import '../../domain/content_pack_models.dart';

class ContentPackRepository {
  ContentPackRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Directory> get packRootDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'content_packs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<ContentPackManifest>> listInstalledPacks() async {
    final db = await _database.database;
    final rows = await db.query(
      'material_packs',
      orderBy: 'installed_at DESC, title ASC',
    );
    return rows
        .map((row) => ContentPackManifest.fromMap(row))
        .toList();
  }

  Future<ContentPackManifest?> getPackById(String packId) async {
    final db = await _database.database;
    final rows = await db.query(
      'material_packs',
      where: 'pack_id = ?',
      whereArgs: <Object?>[packId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ContentPackManifest.fromMap(rows.first);
  }

  Future<List<ContentPackItem>> listItemsForPack(String packId) async {
    final db = await _database.database;
    final rows = await db.query(
      'material_pack_items',
      where: 'pack_id = ?',
      whereArgs: <Object?>[packId],
      orderBy: 'kind ASC, order_index ASC, title ASC',
    );
    return rows.map((row) => ContentPackItem.fromMap(row)).toList();
  }

  Future<List<ContentPackItem>> listItemsByKind(String kind) async {
    final db = await _database.database;
    final rows = await db.query(
      'material_pack_items',
      where: 'kind = ?',
      whereArgs: <Object?>[kind],
      orderBy: 'grade ASC, subject ASC, medium ASC, order_index ASC',
    );
    return rows.map((row) => ContentPackItem.fromMap(row)).toList();
  }

  Future<void> upsertPack({
    required ContentPackManifest manifest,
    required List<ContentPackItem> items,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(
        'material_packs',
        manifest.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'material_pack_items',
        where: 'pack_id = ?',
        whereArgs: <Object?>[manifest.packId],
      );
      for (final item in items) {
        await txn.insert(
          'material_pack_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deletePack(String packId) async {
    final db = await _database.database;
    await db.delete(
      'material_packs',
      where: 'pack_id = ?',
      whereArgs: <Object?>[packId],
    );
  }

  Future<ContentPackCatalogEntry> buildCatalogEntry(String packId) async {
    final db = await _database.database;
    final packRows = await db.query(
      'material_packs',
      where: 'pack_id = ?',
      whereArgs: <Object?>[packId],
      limit: 1,
    );
    if (packRows.isEmpty) {
      throw StateError('Pack not found: $packId');
    }

    final manifest = ContentPackManifest.fromMap(packRows.first);
    final itemRows = await db.query(
      'material_pack_items',
      where: 'pack_id = ?',
      whereArgs: <Object?>[packId],
    );

    var pdfCount = 0;
    var videoCount = 0;
    var quizCount = 0;
    var otherCount = 0;
    for (final row in itemRows) {
      final kind = (row['kind'] as String? ?? 'other').toLowerCase();
      if (kind == 'pdf') {
        pdfCount += 1;
      } else if (kind == 'video') {
        videoCount += 1;
      } else if (kind == 'quiz') {
        quizCount += 1;
      } else {
        otherCount += 1;
      }
    }

    return ContentPackCatalogEntry(
      manifest: manifest,
      itemCount: itemRows.length,
      pdfCount: pdfCount,
      videoCount: videoCount,
      quizCount: quizCount,
      otherCount: otherCount,
    );
  }

  Future<int> getInstalledPackCount() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM material_packs');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> getInstalledItemCount() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM material_pack_items');
    return (rows.first['c'] as int?) ?? 0;
  }
}
