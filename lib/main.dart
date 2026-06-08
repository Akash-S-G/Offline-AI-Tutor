import 'package:flutter/material.dart';

import 'bootstrap/critical_bootstrap.dart';
import 'bootstrap/startup_coordinator.dart';
import 'config/app_environment.dart';
import 'features/course/data/local/course_repository.dart';
import 'features/home/presentation/app_shell.dart';
import 'features/network/application/pi_hub_discovery_coordinator.dart';
import 'features/onboarding/application/background_prefetch_service.dart';
import 'core/theme/idp_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce a completely clean slate for discovery on every boot (Sprint requirement)
  await PiHubDiscoveryCoordinator.clearPersistedCache();

  await AppEnvironment.initialize();
  await BackgroundPrefetchService.initialize();

  CriticalBootstrap.configureDesktopSqlite();

  final startupCoordinator = StartupCoordinator(
    runtimeMode: CriticalBootstrap.resolveRuntimeMode(),
  );

  runApp(
    OfflineTutorApp(
      courseRepository: CourseRepository(),
      startupCoordinator: startupCoordinator,
    ),
  );
}

class OfflineTutorApp extends StatelessWidget {
  const OfflineTutorApp({super.key,
    required this.courseRepository,
    required this.startupCoordinator,
  });

  final CourseRepository courseRepository;
  final StartupCoordinator startupCoordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Tutor',
      debugShowCheckedModeBanner: false,
      theme: IDPTheme.lightTheme,
      home: AppShell(
        courseRepository: courseRepository,
        startupCoordinator: startupCoordinator,
      ),
    );
  }
}
