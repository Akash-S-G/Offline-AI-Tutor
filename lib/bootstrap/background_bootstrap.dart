import 'dart:async';
import 'dart:io';

import '../config/app_environment.dart';
import '../features/chat/data/llm_admin_channel_service.dart';
import '../features/content_packs/application/content_pack_bootstrap_service.dart';
import '../features/course/data/local/course_repository.dart';
import '../features/educational/application/inverted_index.dart';
import '../features/educational/data/educational_database.dart';
import '../features/educational/application/sync_manager.dart';
import '../features/rag/data/local/rag_repository.dart';
import 'startup_coordinator.dart';

class BackgroundBootstrap {
  BackgroundBootstrap({
    required StartupCoordinator coordinator,
    required CourseRepository courseRepository,
  })  : _coordinator = coordinator,
        _courseRepository = courseRepository;

  final StartupCoordinator _coordinator;
  final CourseRepository _courseRepository;

  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    Future<void>(() async {
      await _run();
    });
  }

  Future<void> _run() async {
    try {
      _coordinator.beginStep('Warming local database');
      await EducationalDatabase.database;
      _coordinator.completeStep('Warming local database');

      _coordinator.beginStep('Seeding courses');
      await _courseRepository.ensureSeedData();
      _coordinator.completeStep('Seeding courses');

      _coordinator.beginStep('Seeding offline retrieval');
      await RagRepository().ensureSeedChunks();
      _coordinator.completeStep('Seeding offline retrieval');

      _coordinator.beginStep('Deferring content sync');
      _runAsyncBackgroundSync();
      _coordinator.completeStep('Deferring content sync');

      _coordinator.beginStep('Building offline search');
      if (!EducationalDatabase.isFullTextSearchAvailable) {
        await InvertedIndexService().buildIndex();
      }
      _coordinator.markOfflineSearchReady();
      _coordinator.completeStep('Building offline search');

      if (Platform.isAndroid) {
        _coordinator.beginStep('Preparing local AI');
        try {
          await LlmAdminChannelService().preloadModel();
          _coordinator.markLocalAiReady();
        } catch (e) {
          AppEnvironment.log('SYNC', '[BackgroundBootstrap] Local AI warmup failed: $e');
        }
        _coordinator.completeStep('Preparing local AI');
      } else {
        _coordinator.markLocalAiReady();
      }

      _coordinator.markBackgroundComplete();
    } catch (e) {
      AppEnvironment.log('SYNC', '[BackgroundBootstrap] Startup warmup failed: $e');
    }
  }

  void _runAsyncBackgroundSync() {
    Future<void>(() async {
      try {
        AppEnvironment.log('SYNC', '[DIAGNOSTICS] BACKGROUND_SYNC_START');
        await Future<void>.delayed(const Duration(seconds: 2));
        
        AppEnvironment.log('SYNC', '[DIAGNOSTICS] SYNC_START');
        await SyncManager().checkForPackUpdates();
        AppEnvironment.log('SYNC', '[DIAGNOSTICS] SYNC_END');

        AppEnvironment.log('SYNC', '[DIAGNOSTICS] PACK_INSTALL_START');
        await ContentPackBootstrapService().bootstrapLegacyMediaIntoPacks();
        AppEnvironment.log('SYNC', '[DIAGNOSTICS] PACK_INSTALL_END');
        
        AppEnvironment.log('SYNC', '[DIAGNOSTICS] BACKGROUND_SYNC_COMPLETE');
      } catch (e) {
        AppEnvironment.log('SYNC', 'Async background sync failed: $e');
      }
    });
  }
}
