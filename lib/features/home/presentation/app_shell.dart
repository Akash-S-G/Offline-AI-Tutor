import 'package:flutter/material.dart';

import '../../course/data/local/course_repository.dart';
import '../../content_packs/application/content_pack_bootstrap_service.dart';
import '../../rag/data/local/rag_repository.dart';
import 'hero_page.dart';
import 'main_dashboard_screen.dart';

/// App shell that manages navigation between hero page and main dashboard
class AppShell extends StatefulWidget {
  const AppShell({
    required this.courseRepository,
    super.key,
  });

  final CourseRepository courseRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showHero = true;
  bool _contentPacksInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRagData();
  }

  Future<void> _initializeRagData() async {
    final ragRepository = RagRepository();
    await ragRepository.ensureSeedChunks();
  }

  Future<void> _initializeContentPacks() async {
    final bootstrapService = ContentPackBootstrapService();
    await bootstrapService.bootstrapLegacyMediaIntoPacks();
    if (mounted) {
      setState(() {
        _contentPacksInitialized = true;
      });
    }
  }

  void _onGetStarted() {
    setState(() {
      _showHero = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_contentPacksInitialized) {
      _contentPacksInitialized = true;
      _initializeContentPacks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showHero) {
      return HeroPage(onGetStarted: _onGetStarted);
    }

    return MainDashboardScreen(courseRepository: widget.courseRepository);
  }
}
