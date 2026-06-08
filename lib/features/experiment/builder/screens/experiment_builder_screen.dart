import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../widgets/rule_editor.dart';
import '../widgets/builder_drafts_screen.dart';

import '../widgets/design_workspace_panel.dart';
import '../widgets/preview_workspace_panel.dart';
import '../widgets/publish_workspace_panel.dart';
import '../widgets/builder_workflow_sidebar.dart';

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

class _ExperimentBuilderScreenState extends State<ExperimentBuilderScreen> with SingleTickerProviderStateMixin {
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

  @override
  void dispose() {
    _aiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  BuilderWorkflowStep _currentStep = BuilderWorkflowStep.create;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment Builder'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          if (isMobile) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildWorkspaceForStep(_currentStep),
                  ),
                ),
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: const Color(0xFF0F172A),
                  selectedItemColor: const Color(0xFF3B82F6),
                  unselectedItemColor: const Color(0xFF64748B),
                  currentIndex: BuilderWorkflowStep.values.indexOf(_currentStep),
                  onTap: (index) {
                    setState(() {
                      _currentStep = BuilderWorkflowStep.values[index];
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
                    BottomNavigationBarItem(icon: Icon(Icons.design_services), label: 'Design'),
                    BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Logic'),
                    BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Preview'),
                    BottomNavigationBarItem(icon: Icon(Icons.publish), label: 'Publish'),
                  ],
                ),
              ],
            );
          }

          // Desktop / Large Tablet Layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BuilderWorkflowSidebar(
                currentStep: _currentStep,
                controller: _controller,
                onStepSelected: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _buildWorkspaceForStep(_currentStep),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceForStep(BuilderWorkflowStep step) {
    switch (step) {
      case BuilderWorkflowStep.create:
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF1E293B),
                unselectedLabelColor: Color(0xFF64748B),
                tabs: [
                  Tab(text: 'AI Generator'),
                  Tab(text: 'My Drafts'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    AiGeneratorTab(aiController: _aiController, builderController: _controller),
                    BuilderDraftsScreen(draftManager: _controller.draftManager),
                  ],
                ),
              ),
            ],
          ),
        );
      case BuilderWorkflowStep.design:
        return DesignWorkspacePanel(controller: _controller);
      case BuilderWorkflowStep.logic:
        return RuleEditor(controller: _controller);
      case BuilderWorkflowStep.preview:
        return PreviewWorkspacePanel(controller: _controller);
      case BuilderWorkflowStep.publish:
        return PublishWorkspacePanel(controller: _controller);
    }
  }
}
