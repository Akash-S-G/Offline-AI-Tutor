import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/session_info.dart';

const _uuid = Uuid();

class SessionNotifier extends StateNotifier<SessionInfo> {
  SessionNotifier()
      : super(SessionInfo(
          sessionId: 'sess_${_uuid.v4().substring(0, 8)}',
          deviceId: 'dev_${_uuid.v4().substring(0, 8)}',
          studentId: 'stu_${_uuid.v4().substring(0, 8)}',
        ));

  void resetSession() {
    state = state.copyWith(
      sessionId: 'sess_${_uuid.v4().substring(0, 8)}',
    );
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionInfo>((ref) {
  return SessionNotifier();
});
