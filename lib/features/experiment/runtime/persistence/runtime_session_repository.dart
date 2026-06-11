import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'runtime_session.dart';
import 'runtime_session_serializer.dart';

abstract class RuntimeSessionRepository {
  Future<void> save(RuntimeSession session);
  Future<RuntimeSession?> load(String sessionId);
  Future<List<RuntimeSession>> list({String? experimentId});
  Future<void> delete(String sessionId);
  Future<RuntimeSession?> latestForExperiment(String experimentId);
}

class FileRuntimeSessionRepository implements RuntimeSessionRepository {
  final Directory? rootDirectory;
  final RuntimeSessionSerializer serializer;

  const FileRuntimeSessionRepository({
    this.rootDirectory,
    this.serializer = const RuntimeSessionSerializer(),
  });

  Future<Directory> _directory() async {
    if (rootDirectory != null) {
      return rootDirectory!..createSync(recursive: true);
    }
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/runtime_sessions');
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<void> save(RuntimeSession session) async {
    final directory = await _directory();
    final file = File('${directory.path}/${_safe(session.sessionId)}.json');
    await file.writeAsString(jsonEncode(serializer.toJson(session)));
  }

  @override
  Future<RuntimeSession?> load(String sessionId) async {
    final directory = await _directory();
    final file = File('${directory.path}/${_safe(sessionId)}.json');
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString());
    return serializer.fromJson(Map<String, dynamic>.from(json as Map));
  }

  @override
  Future<List<RuntimeSession>> list({String? experimentId}) async {
    final directory = await _directory();
    if (!await directory.exists()) return const [];
    final sessions = <RuntimeSession>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString());
        final session = serializer.fromJson(Map<String, dynamic>.from(json));
        if (experimentId == null || session.experimentId == experimentId) {
          sessions.add(session);
        }
      } catch (_) {
        // Ignore corrupt session files; a later repair pass can surface them.
      }
    }
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<void> delete(String sessionId) async {
    final directory = await _directory();
    final file = File('${directory.path}/${_safe(sessionId)}.json');
    if (await file.exists()) await file.delete();
  }

  @override
  Future<RuntimeSession?> latestForExperiment(String experimentId) async {
    final sessions = await list(experimentId: experimentId);
    return sessions.isEmpty ? null : sessions.first;
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
