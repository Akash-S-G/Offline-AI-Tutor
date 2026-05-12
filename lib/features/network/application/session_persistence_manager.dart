import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionPersistenceManager {
  static const String _prefix = 'classroom_session_';

  final Map<String, Map<String, dynamic>> _memoryStorage = <String, Map<String, dynamic>>{};

  Future<void> saveSession(String sessionId, Map<String, dynamic> data) async {
    final snapshot = Map<String, dynamic>.from(data)
      ..['sessionId'] = sessionId
      ..['savedAt'] = DateTime.now().toIso8601String();

    _memoryStorage[sessionId] = snapshot;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(sessionId), jsonEncode(snapshot));
  }

  Future<Map<String, dynamic>?> loadSession(String sessionId) async {
    final memory = _memoryStorage[sessionId];
    if (memory != null) {
      return Map<String, dynamic>.from(memory);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key(sessionId));
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(encoded);
    if (decoded is Map<String, dynamic>) {
      final snapshot = Map<String, dynamic>.from(decoded);
      _memoryStorage[sessionId] = snapshot;
      return snapshot;
    }

    return null;
  }

  Future<void> clearSession(String sessionId) async {
    _memoryStorage.remove(sessionId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(sessionId));
  }

  bool isValidSession(Map<String, dynamic> data) {
    return data['sessionId'] is String && data['savedAt'] is String;
  }

  String _key(String sessionId) => '$_prefix$sessionId';
}
