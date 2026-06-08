import 'package:workmanager/workmanager.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../educational/application/sync_manager.dart';
import '../../network/domain/endpoint_builder.dart';
import '../../network/domain/runtime_backend_url.dart';
import '../../../config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../educational/domain/pack_sync_entry.dart';

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
      if (batteryState != BatteryState.charging && batteryState != BatteryState.full) {
        AppEnvironment.log('SYNC', '[Prefetch] Skipping: Device not charging');
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final grade = prefs.getInt('selected_grade');
      if (grade == null) {
        AppEnvironment.log('SYNC', '[Prefetch] Skipping: No grade selected');
        return true;
      }

      final url = RuntimeBackendUrl().current;
      final endpoint = '${EndpointBuilder(baseUrl: url).packsRecommended}?grade=$grade';
      
      AppEnvironment.log('SYNC', '[Prefetch] Fetching recommended packs: $endpoint');

      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final packsList = data['packs'];

        if (packsList is List) {
          final syncManager = SyncManager();
          final entries = packsList.map((pkg) => PackSyncEntry.fromJson(pkg)).toList();
          await syncManager.processPackUpdates(entries);
        }
      }

      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', '[Prefetch] Error executing task: $e');
      return false; // Retry on failure if workmanager allows
    }
  });
}

class BackgroundPrefetchService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: AppEnvironment.debugMode,
    );
  }

  static void schedulePrefetch() {
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
