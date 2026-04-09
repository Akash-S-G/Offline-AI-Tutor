import '../../../course/data/local/app_database.dart';
import '../../domain/tutor_message.dart';

class ChatSessionRepository {
  ChatSessionRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<String> createOrGetSession({
    required String chapterId,
    required String languageCode,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_sessions',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'last_message_at DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first['id'] as String;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionId = '${chapterId}_$now';

    await db.insert('chat_sessions', {
      'id': sessionId,
      'chapter_id': chapterId,
      'language_code': languageCode,
      'started_at': now,
      'last_message_at': now,
    });

    return sessionId;
  }

  Future<void> appendMessage({
    required String sessionId,
    required bool isUser,
    required String text,
    required DateTime timestamp,
  }) async {
    final db = await _database.database;
    final createdAt = timestamp.millisecondsSinceEpoch;

    await db.insert('chat_messages', {
      'session_id': sessionId,
      'role': isUser ? 'user' : 'assistant',
      'text': text,
      'created_at': createdAt,
    });

    await db.update(
      'chat_sessions',
      {'last_message_at': createdAt},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<TutorMessage>> getMessages(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map(
          (row) => TutorMessage(
            text: row['text'] as String,
            isUser: (row['role'] as String) == 'user',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<DateTime?> getLastMessageAt(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query(
      'chat_sessions',
      columns: <String>['last_message_at'],
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['last_message_at'] as int?;
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> clearMessages(String sessionId) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: <Object?>[sessionId],
    );

    await db.update(
      'chat_sessions',
      <String, Object?>{'last_message_at': now},
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
    );
  }
}
