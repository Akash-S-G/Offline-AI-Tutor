import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:offline_tutor_app/features/network/application/classroom_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/classroom_session_manager.dart';
import 'package:offline_tutor_app/features/network/application/classroom_startup_validator.dart';
import 'package:offline_tutor_app/features/network/application/deferred_synchronization_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/deferred_sync_manager.dart';
import 'package:offline_tutor_app/features/network/application/deployment_diagnostics_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/heartbeat_recovery_service.dart';
import 'package:offline_tutor_app/features/network/application/pack_integrity_validator.dart';
import 'package:offline_tutor_app/features/network/application/persistent_sync_recovery_manager.dart';
import 'package:offline_tutor_app/features/network/application/session_persistence_manager.dart';
import 'package:offline_tutor_app/features/network/application/transfer_integrity_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    dotenv.loadFromString(envString: 'BACKEND_BASE_URL=http://10.28.73.193\nENABLE_STRUCTURED_LOGGING=false');
  });

  test('classroom session can be persisted and recovered', () async {
    final persistence = SessionPersistenceManager();
    final sessions = ClassroomSessionManager();
    final heartbeat = HeartbeatRecoveryService(sessions: sessions);
    final recovery = ClassroomRecoveryCoordinator(
      persistence: persistence,
      sessions: sessions,
      heartbeatRecovery: heartbeat,
    );

    persistence.saveSession('room-1', {'teacher': 'A'});
    await recovery.restoreIfNeeded('room-1');

    expect(sessions.current.connected, true);
    expect(sessions.current.sessionId, 'room-1');
  });

  test('sync recovery coordinator drains deferred operations', () {
    final manager = PersistentSyncRecoveryManager();
    final deferred = DeferredSynchronizationCoordinator(recovery: manager);

    deferred.defer({'kind': 'pack-sync', 'id': 'math'});
    deferred.defer({'kind': 'pack-sync', 'id': 'science'});

    expect(deferred.flush().length, 2);
  });

  test('pack and transfer validators accept valid inputs', () {
    const packValidator = PackIntegrityValidator();
    const transferValidator = TransferIntegrityValidator();

    expect(
      packValidator.validateManifest(packId: 'math', version: 1, checksum: 'abc'),
      true,
    );
    expect(
      transferValidator.validate(checksum: 'abc', expectedChecksum: 'abc'),
      true,
    );
  });

  test('deployment diagnostics and startup validator produce readiness state', () {
    const validator = ClassroomStartupValidator();
    final diagnostics = DeploymentDiagnosticsCoordinator();

    expect(validator.isReady(backendReady: true, classroomReady: true), true);
    expect(
      diagnostics.summarize(backendReady: true, classroomReady: true),
      contains('backend=true'),
    );
  });
}
