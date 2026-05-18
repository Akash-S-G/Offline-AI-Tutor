import 'package:flutter/material.dart';

import 'bootstrap/critical_bootstrap.dart';
import 'bootstrap/startup_coordinator.dart';
import 'config/app_environment.dart';
import 'features/course/data/local/course_repository.dart';
import 'features/home/presentation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnvironment.initialize();

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
    const primary = Color(0xFF0B6E4F);
    const surface = Color(0xFFF7FCFA);

    return MaterialApp(
      title: 'Offline Tutor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          surface: surface,
        ),
      ),
      home: AppShell(
        courseRepository: courseRepository,
        startupCoordinator: startupCoordinator,
      ),
    );
  }
}
