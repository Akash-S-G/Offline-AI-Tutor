import 'package:flutter/material.dart';

import '../../../bootstrap/background_bootstrap.dart';
import '../../../bootstrap/optional_bootstrap.dart';
import '../../../bootstrap/startup_coordinator.dart';
import '../../course/data/local/course_repository.dart';
import 'hero_page.dart';
import 'main_dashboard_screen.dart';

/// App shell that manages navigation between hero page and main dashboard
class AppShell extends StatefulWidget {
  const AppShell({
    required this.courseRepository,
    required this.startupCoordinator,
    super.key,
  });

  final CourseRepository courseRepository;
  final StartupCoordinator startupCoordinator;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showHero = true;
  late final BackgroundBootstrap _backgroundBootstrap;
  late final OptionalBootstrap _optionalBootstrap;

  @override
  void initState() {
    super.initState();
    _backgroundBootstrap = BackgroundBootstrap(
      coordinator: widget.startupCoordinator,
      courseRepository: widget.courseRepository,
    );
    _optionalBootstrap = OptionalBootstrap(
      coordinator: widget.startupCoordinator,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backgroundBootstrap.start();
      _optionalBootstrap.start();
    });
  }

  void _onGetStarted() {
    setState(() {
      _showHero = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.startupCoordinator,
      builder: (context, _) {
        if (_showHero) {
          return HeroPage(onGetStarted: _onGetStarted);
        }

        return MainDashboardScreen(
          courseRepository: widget.courseRepository,
        );
      },
    );
  }
}
