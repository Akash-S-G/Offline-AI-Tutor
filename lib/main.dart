import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'config/app_environment.dart';
import 'features/course/data/local/course_repository.dart';
import 'features/home/presentation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize centralized environment configuration from .env file
  await AppEnvironment.initialize();
  
  // Initialize sqflite for desktop (Linux, Windows, macOS)
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final courseRepository = CourseRepository();
  await courseRepository.ensureSeedData();

  runApp(OfflineTutorApp(courseRepository: courseRepository));
}

class OfflineTutorApp extends StatelessWidget {
  const OfflineTutorApp({super.key, 
    required this.courseRepository,
  });

  final CourseRepository courseRepository;

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
      home: AppShell(courseRepository: courseRepository),
    );
  }
}
