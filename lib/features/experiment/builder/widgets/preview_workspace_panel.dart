import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import 'builder_execution_preview_panel.dart';
import 'runtime_preview_panel.dart';

class PreviewWorkspacePanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const PreviewWorkspacePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final leftPane = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Execution Preparation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: BuilderExecutionPreviewPanel(controller: controller),
            ),
          ],
        );

        final rightPane = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Runtime State Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: RuntimePreviewPanel(controller: controller)),
          ],
        );

        if (isMobile) {
          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TabBar(
                  labelColor: Color(0xFF1E293B),
                  unselectedLabelColor: Color(0xFF64748B),
                  tabs: [
                    Tab(icon: Icon(Icons.memory), text: 'Prepare'),
                    Tab(icon: Icon(Icons.preview), text: 'Runtime'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [leftPane, rightPane],
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 1, child: leftPane),
            const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            Expanded(flex: 2, child: rightPane),
          ],
        );
      },
    );
  }
}
