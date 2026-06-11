import 'dart:async';

import '../runtime_world.dart';
import 'runtime_session_manager.dart';

class RuntimeAutosaveManager {
  final RuntimeWorld world;
  final RuntimeSessionManager sessions;
  final Duration interval;
  Timer? _timer;
  String? _sessionId;

  RuntimeAutosaveManager({
    required this.world,
    required this.sessions,
    this.interval = const Duration(seconds: 30),
  });

  bool get isRunning => _timer?.isActive == true;
  String? get sessionId => _sessionId;

  void start({String? sessionId}) {
    _sessionId = sessionId ?? _sessionId;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => saveNow());
  }

  Future<void> saveNow() async {
    final session = await sessions.save(
      world,
      sessionId: _sessionId,
      autosave: true,
    );
    _sessionId = session.sessionId;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
