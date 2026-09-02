import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_environment.dart';
import '../../course/data/local/app_database.dart';
import '../domain/endpoint_builder.dart';

class PendingSyncQueueItem {
  final int? id;
  final String payloadType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String status;
  final int retryCount;

  PendingSyncQueueItem({
    this.id,
    required this.payloadType,
    required this.payload,
    required this.createdAt,
    this.status = 'pending',
    this.retryCount = 0,
  });
}

class PendingSyncQueueRepository {
  Future<int> enqueue(String payloadType, Map<String, dynamic> payload) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('pending_sync_queue', {
      'payload_type': payloadType,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
      'retry_count': 0,
    });
    AppEnvironment.log('SYNC_QUEUE', 'Enqueued offline item #$id ($payloadType)');
    return id;
  }

  Future<List<PendingSyncQueueItem>> getPendingItems({int limit = 50}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'pending_sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map((r) {
      return PendingSyncQueueItem(
        id: r['id'] as int,
        payloadType: r['payload_type'] as String,
        payload: jsonDecode(r['payload_json'] as String) as Map<String, dynamic>,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        status: r['status'] as String,
        retryCount: r['retry_count'] as int,
      );
    }).toList();
  }

  Future<int> flushPendingItems() async {
    if (!AppEnvironment.enableBackend) return 0;
    final pending = await getPendingItems();
    if (pending.isEmpty) return 0;

    final endpoints = EndpointBuilder.fromEnvironment();
    final db = await AppDatabase.instance.database;
    int syncedCount = 0;

    for (final item in pending) {
      try {
        final url = Uri.parse(endpoints.classroomSync);
        final res = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'action': 'complete',
                'device_id': AppEnvironment.deviceName,
                'payload_type': item.payloadType,
                'payload': item.payload,
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 201) {
          await db.update(
            'pending_sync_queue',
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [item.id],
          );
          syncedCount++;
        } else {
          await db.rawUpdate(
            'UPDATE pending_sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
            [item.id],
          );
        }
      } catch (e) {
        await db.rawUpdate(
          'UPDATE pending_sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
          [item.id],
        );
      }
    }

    if (syncedCount > 0) {
      AppEnvironment.log('SYNC_QUEUE', 'Successfully flushed $syncedCount pending items to server');
    }
    return syncedCount;
  }
}
