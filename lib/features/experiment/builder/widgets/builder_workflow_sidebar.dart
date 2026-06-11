import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';

enum BuilderWorkflowStep { create, design, logic, preview, publish }

class BuilderWorkflowSidebar extends StatelessWidget {
  final BuilderWorkflowStep currentStep;
  final Function(BuilderWorkflowStep) onStepSelected;
  final ExperimentBuilderController controller;

  const BuilderWorkflowSidebar({
    super.key,
    required this.currentStep,
    required this.onStepSelected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final state = controller.state;
          final isValid = controller.validationResult?.isValid ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Creator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildStepItem(
                      step: BuilderWorkflowStep.create,
                      title: '1. Overview',
                      subtitle: 'Start, assistant, saved labs',
                      icon: Icons.auto_awesome_rounded,
                      isComplete:
                          state.scene.name.isNotEmpty &&
                          state.scene.name != 'Untitled',
                    ),
                    _buildStepItem(
                      step: BuilderWorkflowStep.design,
                      title: '2. Components',
                      subtitle: 'Scene, instruments, readings',
                      icon: Icons.design_services_rounded,
                      isComplete:
                          state.objects.isNotEmpty ||
                          state.variables.isNotEmpty,
                    ),
                    _buildStepItem(
                      step: BuilderWorkflowStep.logic,
                      title: '3. Interactions',
                      subtitle: 'Cause and effect',
                      icon: Icons.account_tree_rounded,
                      isComplete: state.rules.isNotEmpty,
                    ),
                    _buildStepItem(
                      step: BuilderWorkflowStep.preview,
                      title: '4. Simulation',
                      subtitle: 'Launch and test',
                      icon: Icons.play_circle_fill_rounded,
                      isComplete: controller.executionPackage != null,
                    ),
                    _buildStepItem(
                      step: BuilderWorkflowStep.publish,
                      title: '5. Share',
                      subtitle: 'Check and export',
                      icon: Icons.publish_rounded,
                      isComplete: isValid,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepItem({
    required BuilderWorkflowStep step,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isComplete,
  }) {
    final isSelected = currentStep == step;

    Color getStatusColor() {
      if (isSelected) return const Color(0xFF3B82F6); // Blue
      if (isComplete) return const Color(0xFF10B981); // Green
      return const Color(0xFF64748B); // Slate
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onStepSelected(step),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                width: 4,
              ),
              bottom: const BorderSide(color: Color(0xFF1E293B), width: 1),
            ),
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete && !isSelected ? Icons.check_circle_rounded : icon,
                  color: getStatusColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFCBD5E1),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
