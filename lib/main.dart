import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/critical_bootstrap.dart';
import 'bootstrap/startup_coordinator.dart';
import 'config/app_environment.dart';
import 'features/course/data/local/course_repository.dart';
import 'features/home/presentation/app_shell.dart';
import 'features/language/providers/language_provider.dart';
import 'features/network/application/pi_hub_discovery_coordinator.dart';
import 'features/onboarding/application/background_prefetch_service.dart';
import 'core/theme/idp_theme.dart';
import 'features/experiment/runtime/behaviors/behavior_registry.dart';
import 'features/experiment/runtime/effects/effect_registry.dart';
import 'features/experiment/runtime/tools/measurement_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce a completely clean slate for discovery on every boot (Sprint requirement)
  await PiHubDiscoveryCoordinator.clearPersistedCache();

  await AppEnvironment.initialize();
  await BackgroundPrefetchService.initialize();

  CriticalBootstrap.configureDesktopSqlite();

  // Initialize behavior, effect, and tool registries for all experiments
  BehaviorRegistry.initialize();
  EffectRegistry.initialize();
  MeasurementRegistry.initialize();

  // Language foundation — load persisted preference before first frame
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  final startupCoordinator = StartupCoordinator(
    runtimeMode: CriticalBootstrap.resolveRuntimeMode(),
  );

  runApp(
    ProviderScope(
      child: OfflineTutorApp(
        courseRepository: CourseRepository(),
        startupCoordinator: startupCoordinator,
        languageProvider: languageProvider,
      ),
    ),
  );
}

class OfflineTutorApp extends StatelessWidget {
  const OfflineTutorApp({super.key,
    required this.courseRepository,
    required this.startupCoordinator,
    required this.languageProvider,
  });

  final CourseRepository courseRepository;
  final StartupCoordinator startupCoordinator;
  final LanguageProvider languageProvider;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Tutor',
      debugShowCheckedModeBanner: false,
      theme: IDPTheme.lightTheme,
      home: AppShell(
        courseRepository: courseRepository,
        startupCoordinator: startupCoordinator,
        languageProvider: languageProvider,
      ),
    );
  }
}
