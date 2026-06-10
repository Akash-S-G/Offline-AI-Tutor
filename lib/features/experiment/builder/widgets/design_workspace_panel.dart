import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import 'object_editor.dart';
import 'variable_editor.dart';
import 'scene_editor.dart';

class DesignWorkspacePanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const DesignWorkspacePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final leftPane = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => TabBar(
                  labelColor: const Color(0xFF1E293B),
                  unselectedLabelColor: const Color(0xFF64748B),
                  tabs: [
                    Tab(
                      text: 'Variables (${controller.state.variables.length})',
                    ),
                    Tab(text: 'Objects (${controller.state.objects.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    VariableEditor(controller: controller),
                    ObjectEditor(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );

        final centerPane = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Scene Canvas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: SceneEditor(controller: controller)),
          ],
        );

        final rightPane = Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Properties Inspector',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.tune_rounded,
                        size: 48,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Selection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select an object or variable\nto view its properties.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (isMobile) {
          return DefaultTabController(
            length: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => TabBar(
                    isScrollable: true,
                    labelColor: const Color(0xFF1E293B),
                    unselectedLabelColor: const Color(0xFF64748B),
                    tabs: [
                      const Tab(icon: Icon(Icons.brush), text: 'Scene'),
                      Tab(
                        icon: const Icon(Icons.data_object),
                        text:
                            'Variables (${controller.state.variables.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.category),
                        text: 'Objects (${controller.state.objects.length})',
                      ),
                      const Tab(icon: Icon(Icons.tune), text: 'Props'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      centerPane,
                      VariableEditor(controller: controller),
                      ObjectEditor(controller: controller),
                      rightPane,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: leftPane),
            const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            Expanded(flex: 4, child: centerPane),
            const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
            Expanded(flex: 2, child: rightPane),
          ],
        );
      },
    );
  }
}
