import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backend_discovery_service.dart';

final backendDiscoveryProvider =
    ChangeNotifierProvider<BackendDiscoveryService>((ref) {
      return BackendDiscoveryService();
    });

final classroomConnectionProvider = backendDiscoveryProvider;
