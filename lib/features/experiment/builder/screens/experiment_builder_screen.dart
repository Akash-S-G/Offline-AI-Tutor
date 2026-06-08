import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../widgets/scene_editor.dart';
import '../widgets/variable_editor.dart';
import '../widgets/object_editor.dart';
import '../widgets/rule_editor.dart';
import '../widgets/manifest_preview_panel.dart';
import '../widgets/runtime_preview_panel.dart';
import '../widgets/builder_validation_panel.dart';
import '../widgets/builder_compatibility_panel.dart';
import '../widgets/builder_execution_preview_panel.dart';
import '../widgets/builder_drafts_screen.dart';

import '../storage/builder_draft_manager.dart';
import '../storage/builder_draft_repository.dart';
import '../data/repositories/experiment_manifest_repository.dart';
import '../data/api/experiment_manifest_api_service.dart';
import '../../../network/domain/backend_config.dart';

import '../ai/controllers/ai_generator_controller.dart';
import '../ai/repositories/ai_experiment_repository.dart';
import '../ai/api/ai_experiment_api_service.dart';
import '../ai/widgets/ai_generator_tab.dart';

class ExperimentBuilderScreen extends StatefulWidget {
  const ExperimentBuilderScreen({super.key});

  @override
  State<ExperimentBuilderScreen> createState() => _ExperimentBuilderScreenState();
}

class _ExperimentBuilderScreenState extends State<ExperimentBuilderScreen> {
  late final ExperimentBuilderController _controller;
  late final AiGeneratorController _aiController;

  @override
  void initState() {
    super.initState();
    final config = BackendConfig.fromEnvironment() ?? BackendConfig(baseUrl: 'http://localhost', apiKey: 'dummy');
    
    // Core Builder Config
    final apiService = ExperimentManifestApiService(config);
    final repo = ExperimentManifestRepositoryImpl(apiService);
    final draftManager = BuilderDraftManager(SharedPreferencesBuilderDraftRepository());
    
    _controller = ExperimentBuilderController(
      draftManager: draftManager,
      manifestRepository: repo,
    );

    // AI Generator Config
    final aiApiService = AiExperimentApiService(config);
    final aiRepo = AiExperimentRepositoryImpl(aiApiService);
    
    _aiController = AiGeneratorController(
      aiRepository: aiRepo,
      manifestRepository: repo,
    );
  }

  int _currentIndex = 0;

  final List<String> _tabTitles = [
    'AI Generator',
    'Drafts',
    'Scene',
    'Variables',
    'Objects',
    'Rules',
    'Manifest Preview',
    'Runtime Preview',
    'Validation',
    'Compatibility',
    'Execution',
  ];

  @override
  void dispose() {
    _aiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Select View',
            onSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (BuildContext context) {
              return List.generate(_tabTitles.length, (index) {
                return PopupMenuItem<int>(
                  value: index,
                  child: Text(
                    _tabTitles[index],
                    style: TextStyle(
                      fontWeight: _currentIndex == index ? FontWeight.bold : FontWeight.normal,
                      color: _currentIndex == index ? Colors.blue : Colors.black87,
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AiGeneratorTab(aiController: _aiController, builderController: _controller),
          BuilderDraftsScreen(draftManager: _controller.draftManager),
          SceneEditor(controller: _controller),
          VariableEditor(controller: _controller),
          ObjectEditor(controller: _controller),
          RuleEditor(controller: _controller),
          ManifestPreviewPanel(controller: _controller),
          RuntimePreviewPanel(controller: _controller),
          BuilderValidationPanel(controller: _controller),
          BuilderCompatibilityPanel(controller: _controller),
          BuilderExecutionPreviewPanel(controller: _controller),
        ],
      ),
    );
  }
}
