import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../educational/application/sync_manager.dart';
import '../../../config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String prefetchTaskName = 'backgroundPrefetchTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task != prefetchTaskName) return true;

      // Ensure requirements: WiFi, Charging
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
        AppEnvironment.log('SYNC', '[Prefetch] Skipping: Not on WiFi');
        return true;
      }

      final battery = Battery();
      final batteryState = await battery.batteryState;
      if (batteryState != BatteryState.charging &&
          batteryState != BatteryState.full) {
        AppEnvironment.log('SYNC', '[Prefetch] Skipping: Device not charging');
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final grade = prefs.getInt('selected_grade');
      if (grade == null) {
        AppEnvironment.log('SYNC', '[Prefetch] Skipping: No grade selected');
        return true;
      }

      final syncManager = SyncManager();
      final updates = await syncManager.checkForPackUpdates(grade: grade);
      await syncManager.processPackUpdates(updates);

      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', '[Prefetch] Error executing task: $e');
      return false; // Retry on failure if workmanager allows
    }
  });
}

class BackgroundPrefetchService {
  static Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      AppEnvironment.log(
        'SYNC',
        '[Prefetch] Workmanager not supported on this platform. Skipping initialization.',
      );
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: AppEnvironment.debugMode,
    );
  }

  static void schedulePrefetch() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    Workmanager().registerPeriodicTask(
      'offline_tutor_prefetch',
      prefetchTaskName,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.unmetered, // Wi-Fi
        requiresCharging: true,
        requiresDeviceIdle: true,
      ),
      initialDelay: const Duration(minutes: 15),
    );
    AppEnvironment.log('SYNC', '[Prefetch] Scheduled background prefetch');
  }
}
