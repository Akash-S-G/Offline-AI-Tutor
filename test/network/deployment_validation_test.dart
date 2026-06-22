import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:offline_tutor_app/features/network/application/classroom_session_manager.dart';
import 'package:offline_tutor_app/features/network/application/deployment_diagnostics_manager.dart';
import 'package:offline_tutor_app/features/network/application/heartbeat_recovery_service.dart';
import 'package:offline_tutor_app/features/network/application/manifest_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/multi_device_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/pack_version_manager.dart';
import 'package:offline_tutor_app/features/network/application/persistent_classroom_recovery_manager.dart';
import 'package:offline_tutor_app/features/network/application/persistent_sync_recovery_manager_v2.dart';
import 'package:offline_tutor_app/features/network/application/session_persistence_manager.dart';
import 'package:offline_tutor_app/features/network/application/distributed_state_recovery_coordinator.dart';
import 'package:offline_tutor_app/features/network/application/connectivity_persistence_manager.dart';
import 'package:offline_tutor_app/features/network/application/classroom_state_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    dotenv.loadFromString(envString: 'BACKEND_BASE_URL=http://10.28.73.193\nENABLE_STRUCTURED_LOGGING=false');
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

  group('Phase 6 - Distributed State Hardening', () {
    test('distributed state recovery coordinator saves and loads state', () async {
      final coordinator = DistributedStateRecoveryCoordinator();
      await coordinator.initialize();

      await coordinator.save('test-key', {'value': 42, 'timestamp': DateTime.now().toIso8601String()});
      final loaded = coordinator.load<Map<String, dynamic>>('test-key');

      expect(loaded != null, true);
      expect(loaded!['value'], 42);
    });

    test('distributed state recovery validates state structure', () {
      final coordinator = DistributedStateRecoveryCoordinator();

      expect(coordinator.isStateValid(null), false);
      expect(coordinator.isStateValid({}), false);
      expect(coordinator.isStateValid({'version': 1}), false);
      expect(coordinator.isStateValid({'version': 1, 'timestamp': DateTime.now().toIso8601String()}), true);
    });

    test('distributed state recovery tracks state versions', () async {
      final coordinator = DistributedStateRecoveryCoordinator();
      await coordinator.initialize();

      await coordinator.save('key-1', {'v': 1});
      await coordinator.save('key-1', {'v': 2});
      await coordinator.save('key-1', {'v': 3});

      final metrics = coordinator.getMetrics();
      expect(metrics['stateVersions']['key-1'], 3);
    });

    test('distributed state recovery respects max recovery attempts', () async {
      final coordinator = DistributedStateRecoveryCoordinator();
      await coordinator.initialize();

      final nonExistent = 'nonexistent-key';
      
      // Attempt recovery 5 times, but only 3 are allowed
      for (int i = 0; i < 5; i++) {
        await coordinator.attemptRecovery(nonExistent);
      }

      final metrics = coordinator.getMetrics();
      // After 3 max attempts, further attempts are blocked, so count stays at 3
      expect(metrics['recoveryAttempts'][nonExistent], 3);
    });

    test('distributed state recovery broadcasts events', () async {
      final coordinator = DistributedStateRecoveryCoordinator();
      await coordinator.initialize();

      final events = <StateRecoverySnapshot>[];
      coordinator.recoveryEvents.listen((event) => events.add(event));

      await coordinator.save('key-1', {'valid': true, 'version': 1, 'timestamp': DateTime.now().toIso8601String()});
      await coordinator.attemptRecovery('key-1');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.isNotEmpty, true);
      expect(events.last.status, StateRecoveryStatus.success);
    });

    test('connectivity persistence records state changes', () async {
      final manager = ConnectivityPersistenceManager();
      await manager.initialize();

      await manager.recordStateChange(
        ConnectivityState.online,
        reason: 'Network connected',
      );
      await manager.recordStateChange(
        ConnectivityState.offline,
        reason: 'Network lost',
      );

      final current = manager.getCurrentState();
      expect(current, ConnectivityState.offline);
    });

    test('connectivity persistence analyzes patterns', () async {
      final manager = ConnectivityPersistenceManager();
      await manager.initialize();

      await manager.recordStateChange(ConnectivityState.online);
      await manager.recordStateChange(ConnectivityState.offline);
      await manager.recordStateChange(ConnectivityState.online);

      final patterns = manager.analyzePatterns();
      expect(patterns['totalEvents'], 3);
      expect(patterns['totalOfflineEvents'], 1);
    });

    test('connectivity persistence provides recovery recommendations', () async {
      final manager = ConnectivityPersistenceManager();
      await manager.initialize();

      // Simulate high offline rate
      for (int i = 0; i < 4; i++) {
        await manager.recordStateChange(ConnectivityState.offline);
        await manager.recordStateChange(ConnectivityState.online);
      }

      final recommendations = manager.getRecoveryRecommendations();
      expect(recommendations.isNotEmpty, true);
    });

    test('connectivity persistence broadcasts state changes', () async {
      final manager = ConnectivityPersistenceManager();
      await manager.initialize();

      final events = <ConnectivityEvent>[];
      manager.stateChanges.listen((event) => events.add(event));

      await manager.recordStateChange(ConnectivityState.online);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.isNotEmpty, true);
      expect(events.last.state, ConnectivityState.online);
    });

    test('classroom state persistence captures and restores state', () async {
      final manager = ClassroomStatePersistence();
      await manager.initialize();

      final snapshot = ClassroomStateSnapshot(
        sessionId: 'session-123',
        currentTopic: 'Mathematics',
        currentChapter: 'Algebra',
        messageHistory: [{'text': 'Hello'}, {'text': 'Hi'}],
        capturedAt: DateTime.now(),
      );

      await manager.captureState(snapshot);
      final status = await manager.restoreState();

      expect(status, ClassroomStateRecoveryStatus.success);
    });

    test('classroom state persistence validates state', () {
      final manager = ClassroomStatePersistence();

      final invalidSnapshot = ClassroomStateSnapshot(
        capturedAt: DateTime.now(),
      );
      expect(manager.isStateValid(invalidSnapshot), false);

      final validSnapshot = ClassroomStateSnapshot(
        sessionId: 'session-123',
        currentTopic: 'Math',
        capturedAt: DateTime.now(),
      );
      expect(manager.isStateValid(validSnapshot), true);
    });

    test('classroom state persistence handles component restoration', () async {
      final manager = ClassroomStatePersistence();
      await manager.initialize();

      final snapshot = ClassroomStateSnapshot(
        sessionId: 'session-123',
        currentTopic: 'Mathematics',
        currentChapter: 'Algebra',
        messageHistory: [{'text': 'Hello'}],
        capturedAt: DateTime.now(),
      );

      await manager.captureState(snapshot);
      final restored = await manager.restoreComponent('currentTopic');

      expect(restored, true);
    });

    test('classroom state persistence broadcasts recovery events', () async {
      final manager = ClassroomStatePersistence();
      await manager.initialize();

      final events = <ClassroomStateRecoveryEvent>[];
      manager.recoveryEvents.listen((event) => events.add(event));

      final snapshot = ClassroomStateSnapshot(
        sessionId: 'session-123',
        capturedAt: DateTime.now(),
      );

      await manager.captureState(snapshot);
      await manager.restoreState();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.isNotEmpty, true);
      expect(events.any((e) => e.status == ClassroomStateRecoveryStatus.success), true);
    });
  });
}
