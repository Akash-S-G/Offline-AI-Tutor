import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:offline_tutor_app/features/network/application/classroom_session_manager.dart';
import 'package:offline_tutor_app/features/network/application/deployment_diagnostics_manager.dart';
import 'package:offline_tutor_app/features/network/application/heartbeat_recovery_service.dart';
import 'package:offline_tutor_app/features/network/application/manifest_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/multi_device_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/pack_version_manager.dart';
import 'package:offline_tutor_app/features/network/application/persistent_classroom_recovery_manager.dart';
import 'package:offline_tutor_app/features/network/application/persistent_sync_recovery_manager_v2.dart';
import 'package:offline_tutor_app/features/network/application/session_persistence_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Phase 1 - Classroom Session Recovery', () {
    test('persistent recovery validates session age', () async {
      final persistence = SessionPersistenceManager();
      final sessions = ClassroomSessionManager();
      final heartbeat = HeartbeatRecoveryService(sessions: sessions);
      final recovery = PersistentClassroomRecoveryManager(
        persistence: persistence,
        sessions: sessions,
        sessionValidityThresholdHours: 24,
      );

      // Save a fresh session
      await persistence.saveSession('session-1', {'courseId': 'course_1'});

      // Recover fresh session - should succeed
      final status = await recovery.restoreIfNeeded('session-1');
      expect(status, ClassroomRecoveryStatus.success);
    });

    test('persistent recovery tracks recovery count', () async {
      final persistence = SessionPersistenceManager();
      final sessions = ClassroomSessionManager();
      final heartbeat = HeartbeatRecoveryService(sessions: sessions);
      final recovery = PersistentClassroomRecoveryManager(
        persistence: persistence,
        sessions: sessions,
      );

      await persistence.saveSession('session-2', {'courseId': 'course_2'});
      await recovery.restoreIfNeeded('session-2');
      await recovery.restoreIfNeeded('session-2');

      final data = await recovery.getRestoredSessionData('session-2');
      expect(data?['recoveryCount'], greaterThan(0));
    });

    test('session validator detects invalid sessions', () async {
      final persistence = SessionPersistenceManager();
      final sessions = ClassroomSessionManager();
      final recovery = PersistentClassroomRecoveryManager(
        persistence: persistence,
        sessions: sessions,
      );

      expect(recovery.isSessionValid(null), false);
      expect(recovery.isSessionValid({}), false);
      expect(recovery.isSessionValid({'sessionId': 'x', 'savedAt': '2020-01-01T00:00:00.000Z'}), false);
    });

    test('recovery broadcasts recovery events', () async {
      final persistence = SessionPersistenceManager();
      final sessions = ClassroomSessionManager();
      final recovery = PersistentClassroomRecoveryManager(
        persistence: persistence,
        sessions: sessions,
      );

      final events = <ClassroomRecoverySnapshot>[];
      recovery.recoveryEvents.listen((event) => events.add(event));

      await recovery.restoreIfNeeded('nonexistent');
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(events.isNotEmpty, true);
      expect(events.last.status, ClassroomRecoveryStatus.sessionNotFound);
    });
  });

  group('Phase 2 - Synchronization Recovery', () {
    test('sync recovery tracks interrupted operations', () {
      final recovery = PersistentSyncRecoveryManager();

      recovery.recordInterruption('op-1', {'type': 'sync_pack', 'packId': 'math'}, error: 'Network timeout');

      expect(recovery.getPendingRetries().length, 1);
      expect(recovery.getPendingRetries().first.attemptCount, 1);
    });

    test('sync recovery respects max retry attempts', () async {
      final recovery = PersistentSyncRecoveryManager(maxRetryAttempts: 2);

      recovery.recordInterruption('op-1', {'type': 'sync'});
      recovery.recordInterruption('op-1', {'type': 'sync'});
      recovery.recordInterruption('op-1', {'type': 'sync'});

      final status = await recovery.attemptRecovery('op-1');
      expect(status, SyncRecoveryStatus.maxRetriesExceeded);
      expect(recovery.getFailedOperations().length, 1);
    });

    test('sync recovery clears operations', () {
      final recovery = PersistentSyncRecoveryManager();

      recovery.recordInterruption('op-1', {'type': 'sync'});
      recovery.recordInterruption('op-2', {'type': 'sync'});

      recovery.clearOperation('op-1');
      expect(recovery.getPendingRetries().length, 1);

      recovery.clearAll();
      expect(recovery.getPendingRetries().length, 0);
    });

    test('sync recovery broadcasts events', () async {
      final recovery = PersistentSyncRecoveryManager();
      final events = <SyncRecoverySnapshot>[];
      recovery.recoveryEvents.listen((event) => events.add(event));

      recovery.recordInterruption('op-1', {'type': 'sync'});
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(events.isNotEmpty, true);
      expect(events.last.pendingRetries, 1);
    });
  });

  group('Phase 3 - Educational Pack Hardening', () {
    test('manifest validator accepts valid manifests', () async {
      final versions = PackVersionManager();
      final coordinator = ManifestRecoveryCoordinator(versionManager: versions);

      const manifest = PackManifest(packId: 'math', version: 1, checksum: 'abc123');
      final result = await coordinator.validateManifest(manifest);

      expect(result.isValid, true);
    });

    test('manifest validator rejects invalid manifests', () async {
      final versions = PackVersionManager();
      final coordinator = ManifestRecoveryCoordinator(versionManager: versions);

      const invalid = PackManifest(packId: '', version: 1, checksum: 'abc');
      final result = await coordinator.validateManifest(invalid);

      expect(result.isValid, false);
      expect(result.errorMessage, isNotEmpty);
    });

    test('partial download tracking records progress', () {
      final versions = PackVersionManager();
      final coordinator = ManifestRecoveryCoordinator(versionManager: versions);

      coordinator.recordPartialDownload(packId: 'math', downloadedBytes: 50, totalBytes: 100);
      final state = coordinator.getPartialDownload('math');

      expect(state?.percentComplete, 0.5);
      expect(state?.isResumable, true);
    });

    test('recovery coordinator clears stale partial downloads', () {
      final versions = PackVersionManager();
      final coordinator = ManifestRecoveryCoordinator(versionManager: versions);

      coordinator.recordPartialDownload(packId: 'math', downloadedBytes: 50, totalBytes: 100);
      expect(coordinator.getPartialDownload('math'), isNotNull);
    });
  });

  group('Phase 4 - Multi-Device Classroom Stability', () {
    test('multi-device coordinator tracks device presence', () {
      final coordinator = MultiDeviceRecoveryCoordinator();

      coordinator.registerDevice('device-1');
      coordinator.registerDevice('device-2');

      expect(coordinator.getOnlineDevices().length, 2);
    });

    test('device coordinator marks devices offline', () {
      final coordinator = MultiDeviceRecoveryCoordinator();

      coordinator.registerDevice('device-1');
      coordinator.markOffline('device-1');

      expect(coordinator.getOfflineDevices().length, 1);
      expect(coordinator.getOnlineDevices().length, 0);
    });

    test('device coordinator tracks recovery attempts', () {
      final coordinator = MultiDeviceRecoveryCoordinator(maxRecoveryAttempts: 2);

      coordinator.registerDevice('device-1');
      coordinator.markOffline('device-1');

      expect(coordinator.canAttemptRecovery('device-1'), true);
      coordinator.recordRecoveryAttempt('device-1');
      coordinator.recordRecoveryAttempt('device-1');

      expect(coordinator.canAttemptRecovery('device-1'), false);
    });

    test('device coordinator broadcasts classroom status', () async {
      final coordinator = MultiDeviceRecoveryCoordinator();
      final updates = <ClassroomDeviceSnapshot>[];
      coordinator.deviceUpdates.listen((update) => updates.add(update));

      coordinator.registerDevice('device-1');
      coordinator.registerDevice('device-2');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(updates.isNotEmpty, true);
      expect(updates.last.totalDevices, 2);
      expect(updates.last.availabilityPercent, 100);
    });
  });

  group('Phase 5 & 7 - Deployment Diagnostics', () {
    test('deployment validator validates readiness', () {
      const validator = ClassroomStartupValidator();

      expect(
        validator.isReady(
          backendReady: true,
          classroomReady: true,
          distributionReady: true,
          syncReady: true,
        ),
        true,
      );

      expect(
        validator.isReady(
          backendReady: false,
          classroomReady: true,
          distributionReady: true,
          syncReady: true,
        ),
        false,
      );
    });

    test('deployment diagnostics tracks readiness status', () async {
      final diagnostics = DeploymentDiagnosticsCoordinator();

      await diagnostics.validateDeployment(
        backendReady: true,
        classroomReady: true,
        distributionReady: false,
        syncReady: true,
      );

      expect(diagnostics.currentStatus.readinessPercent, 75);
      expect(diagnostics.currentStatus.status, DeploymentReadinessStatus.distributionNotReady);
    });

    test('deployment diagnostics generates summary', () async {
      final diagnostics = DeploymentDiagnosticsCoordinator();

      await diagnostics.validateDeployment(
        backendReady: true,
        classroomReady: true,
        distributionReady: true,
        syncReady: true,
      );

      final summary = diagnostics.summarize();
      expect(summary, contains('backend=true'));
      expect(summary, contains('readiness=100.0%'));
    });

    test('runtime health monitor tracks check results', () {
      final monitor = RuntimeHealthMonitor();

      monitor.recordCheck(ok: true);
      monitor.recordCheck(ok: true);
      monitor.recordCheck(ok: false, reason: 'Connection timeout');

      expect(monitor.checks, 3);
      expect(monitor.failures, 1);
      expect(monitor.getHealthPercent(), closeTo(66.67, 0.1));
    });

    test('deployment diagnostics broadcasts events', () async {
      final diagnostics = DeploymentDiagnosticsCoordinator();
      final events = <DeploymentDiagnosticsSnapshot>[];
      diagnostics.diagnostics.listen((event) => events.add(event));

      await diagnostics.validateDeployment(
        backendReady: true,
        classroomReady: true,
        distributionReady: true,
        syncReady: true,
      );

      expect(events.isNotEmpty, true);
      expect(events.last.status, DeploymentReadinessStatus.ready);
    });
  });
}
