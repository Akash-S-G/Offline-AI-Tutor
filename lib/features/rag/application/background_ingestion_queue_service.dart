import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../course/data/local/app_database.dart';
import '../data/local/rag_repository_v2.dart';
import 'document_ingestion_orchestrator.dart';
import 'document_loader_service.dart';

class IngestionQueueSnapshot {
  const IngestionQueueSnapshot({
    required this.pending,
    required this.running,
    required this.failed,
    required this.completed,
    required this.paused,
    required this.lastMessage,
  });

  final int pending;
  final int running;
  final int failed;
  final int completed;
  final bool paused;
  final String lastMessage;
}

class BackgroundIngestionQueueService {
  BackgroundIngestionQueueService({
    AppDatabase? database,
    DocumentIngestionOrchestrator? orchestrator,
    RagRepositoryV2? repository,
  })  : _database = database ?? AppDatabase.instance,
        _orchestrator = orchestrator ?? DocumentIngestionOrchestrator(),
        _repository = repository ?? RagRepositoryV2();

  final AppDatabase _database;
  final DocumentIngestionOrchestrator _orchestrator;
  final RagRepositoryV2 _repository;

  final StreamController<IngestionQueueSnapshot> _controller =
      StreamController<IngestionQueueSnapshot>.broadcast();

  bool _processing = false;
  bool _paused = false;

  Stream<IngestionQueueSnapshot> get snapshots => _controller.stream;

  Future<int> enqueueJob({
    required String chapterId,
    required List<DocumentFile> files,
    int maxRetries = 3,
  }) async {
    if (files.isEmpty) {
      throw Exception('No files to enqueue.');
    }

    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode(
      files
          .map(
            (f) => <String, dynamic>{
              'path': f.path,
              'name': f.name,
              'sizeMB': f.sizeMB,
              'modifiedAt': f.modifiedAt.millisecondsSinceEpoch,
              'type': f.type,
            },
          )
          .toList(),
    );

    final id = await db.insert(
      'rag_ingestion_jobs',
      <String, Object?>{
        'chapter_id': chapterId,
        'status': 'pending',
        'files_json': payload,
        'current_index': 0,
        'retry_count': 0,
        'max_retries': maxRetries,
        'created_at': now,
        'updated_at': now,
      },
    );

    await _emitSnapshot('Queued ${files.length} documents for ingestion.');
    unawaited(start());
    return id;
  }

  Future<void> start() async {
    if (_processing) {
      return;
    }

    _processing = true;
    try {
      await _recoverInterruptedJobs();
      while (!_paused) {
        final job = await _nextRunnableJob();
        if (job == null) {
          break;
        }
        await _runJob(job);
      }
    } finally {
      _processing = false;
      await _emitSnapshot(_paused ? 'Queue paused.' : 'Queue idle.');
    }
  }

  Future<void> pause() async {
    _paused = true;
    await _emitSnapshot('Queue paused by user.');
  }

  Future<void> resume() async {
    if (!_paused) {
      return;
    }
    _paused = false;
    await _emitSnapshot('Queue resumed.');
    await start();
  }

  Future<void> retryFailedJobs() async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'rag_ingestion_jobs',
      <String, Object?>{
        'status': 'pending',
        'updated_at': now,
      },
      where: 'status = ?',
      whereArgs: <Object?>['failed'],
    );
    await _emitSnapshot('Retrying failed ingestion jobs.');
    await start();
  }

  Future<IngestionQueueSnapshot> getSnapshot() async {
    final db = await _database.database;
    final pending = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM rag_ingestion_jobs WHERE status = ?',
          <Object?>['pending'],
        )) ??
        0;
    final running = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM rag_ingestion_jobs WHERE status = ?',
          <Object?>['running'],
        )) ??
        0;
    final failed = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM rag_ingestion_jobs WHERE status = ?',
          <Object?>['failed'],
        )) ??
        0;
    final completed = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM rag_ingestion_jobs WHERE status = ?',
          <Object?>['completed'],
        )) ??
        0;

    return IngestionQueueSnapshot(
      pending: pending,
      running: running,
      failed: failed,
      completed: completed,
      paused: _paused,
      lastMessage: '',
    );
  }

  Future<void> _recoverInterruptedJobs() async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'rag_ingestion_jobs',
      <String, Object?>{
        'status': 'pending',
        'updated_at': now,
      },
      where: 'status = ?',
      whereArgs: <Object?>['running'],
    );
  }

  Future<Map<String, dynamic>?> _nextRunnableJob() async {
    final db = await _database.database;
    final rows = await db.query(
      'rag_ingestion_jobs',
      where: 'status IN (?, ?)',
      whereArgs: <Object?>['pending', 'running'],
      orderBy: 'updated_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> _runJob(Map<String, dynamic> job) async {
    final id = job['id'] as int;
    final chapterId = job['chapter_id'] as String;
    final maxRetries = (job['max_retries'] as int?) ?? 3;
    var currentIndex = (job['current_index'] as int?) ?? 0;
    var retryCount = (job['retry_count'] as int?) ?? 0;
    final files = _decodeFiles((job['files_json'] as String?) ?? '[]');

    if (files.isEmpty) {
      await _markJob(
        id: id,
        status: 'failed',
        lastError: 'No files payload in job.',
      );
      return;
    }

    await _markJob(id: id, status: 'running');

    while (currentIndex < files.length && !_paused) {
      final file = files[currentIndex];
      final result = await _orchestrator.processDocument(
        documentFile: file,
        chapterId: chapterId,
      );

      if (!result.success) {
        retryCount += 1;
        if (retryCount > maxRetries) {
          await _markJob(
            id: id,
            status: 'failed',
            lastError: result.message,
            currentIndex: currentIndex,
            retryCount: retryCount,
          );
          await _emitSnapshot('Ingestion failed permanently for ${file.name}.');
          return;
        }

        await _markJob(
          id: id,
          status: 'pending',
          lastError: result.message,
          currentIndex: currentIndex,
          retryCount: retryCount,
        );
        await _emitSnapshot(
          'Retrying ${file.name} ($retryCount/$maxRetries).',
        );
        return;
      }

      if (result.chunks.isNotEmpty) {
        await _repository.insertChunks(result.chunks);
      }

      currentIndex += 1;
      await _markJob(
        id: id,
        status: 'running',
        currentIndex: currentIndex,
        retryCount: retryCount,
      );
      await _emitSnapshot(
        'Ingested ${file.name} ($currentIndex/${files.length}).',
      );
    }

    if (currentIndex >= files.length) {
      await _markJob(id: id, status: 'completed', currentIndex: currentIndex);
      await _emitSnapshot('Ingestion job completed.');
    }
  }

  Future<void> _markJob({
    required int id,
    required String status,
    String? lastError,
    int? currentIndex,
    int? retryCount,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final values = <String, Object?>{
      'status': status,
      'updated_at': now,
    };
    if (lastError != null) {
      values['last_error'] = lastError;
    }
    if (currentIndex != null) {
      values['current_index'] = currentIndex;
    }
    if (retryCount != null) {
      values['retry_count'] = retryCount;
    }

    await db.update(
      'rag_ingestion_jobs',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  List<DocumentFile> _decodeFiles(String filesJson) {
    try {
      final decoded = jsonDecode(filesJson);
      if (decoded is! List) {
        return const <DocumentFile>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (raw) => DocumentFile(
              path: (raw['path'] as String?) ?? '',
              name: (raw['name'] as String?) ?? '',
              sizeMB: (raw['sizeMB'] as String?) ?? '0',
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(
                (raw['modifiedAt'] as int?) ?? 0,
              ),
              type: (raw['type'] as String?) ?? 'pdf',
            ),
          )
          .where((f) => f.path.isNotEmpty)
          .toList();
    } catch (_) {
      return const <DocumentFile>[];
    }
  }

  Future<void> _emitSnapshot(String message) async {
    if (_controller.isClosed) {
      return;
    }
    final snapshot = await getSnapshot();
    _controller.add(
      IngestionQueueSnapshot(
        pending: snapshot.pending,
        running: snapshot.running,
        failed: snapshot.failed,
        completed: snapshot.completed,
        paused: snapshot.paused,
        lastMessage: message,
      ),
    );
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
