import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../course/data/local/app_database.dart';

class TranslationCacheEntry {
  const TranslationCacheEntry({
    required this.cacheKey,
    required this.artifactType,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceHash,
    required this.sourceText,
    required this.translatedText,
    required this.engineId,
    required this.fallbackUsed,
    required this.createdAt,
    required this.updatedAt,
    this.contentId,
  });

  final String cacheKey;
  final String artifactType;
  final String? contentId;
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceHash;
  final String sourceText;
  final String translatedText;
  final String engineId;
  final bool fallbackUsed;
  final int createdAt;
  final int updatedAt;

  factory TranslationCacheEntry.fromMap(Map<String, Object?> row) {
    return TranslationCacheEntry(
      cacheKey: row['cache_key'] as String,
      artifactType: row['artifact_type'] as String,
      contentId: row['content_id'] as String?,
      sourceLanguage: row['source_language'] as String,
      targetLanguage: row['target_language'] as String,
      sourceHash: row['source_hash'] as String,
      sourceText: row['source_text'] as String,
      translatedText: row['translated_text'] as String,
      engineId: row['engine_id'] as String,
      fallbackUsed: (row['fallback_used'] as int? ?? 0) == 1,
      createdAt: row['created_at'] as int? ?? 0,
      updatedAt: row['updated_at'] as int? ?? 0,
    );
  }
}

class TranslationCacheRepository {
  TranslationCacheRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static String hashText(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  Future<TranslationCacheEntry?> find({
    required String artifactType,
    required String sourceLanguage,
    required String targetLanguage,
    required String sourceText,
    String? contentId,
  }) async {
    final db = await _database.database;
    final sourceHash = hashText(sourceText);
    final cacheKey = _buildCacheKey(
      artifactType: artifactType,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      sourceHash: sourceHash,
      contentId: contentId,
    );
    final rows = await db.query(
      'translation_cache',
      where: 'cache_key = ?',
      whereArgs: <Object?>[cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return TranslationCacheEntry.fromMap(rows.first);
  }

  Future<void> upsert({
    required String artifactType,
    required String sourceLanguage,
    required String targetLanguage,
    required String sourceText,
    required String translatedText,
    required String engineId,
    required bool fallbackUsed,
    String? contentId,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sourceHash = hashText(sourceText);
    final cacheKey = _buildCacheKey(
      artifactType: artifactType,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      sourceHash: sourceHash,
      contentId: contentId,
    );

    await db.insert(
      'translation_cache',
      <String, Object?>{
        'cache_key': cacheKey,
        'artifact_type': artifactType,
        'content_id': contentId,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'source_hash': sourceHash,
        'source_text': sourceText,
        'translated_text': translatedText,
        'engine_id': engineId,
        'fallback_used': fallbackUsed ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _buildCacheKey({
    required String artifactType,
    required String sourceLanguage,
    required String targetLanguage,
    required String sourceHash,
    String? contentId,
  }) {
    return [
      artifactType,
      contentId ?? '',
      sourceLanguage,
      targetLanguage,
      sourceHash,
    ].join('|');
  }
}
