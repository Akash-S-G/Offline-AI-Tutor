import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_scene.dart';
import '../services/builder_suggestion_service.dart';

class SceneEditor extends StatefulWidget {
  final ExperimentBuilderController controller;

  const SceneEditor({super.key, required this.controller});

  @override
  State<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<SceneEditor> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    final scene = widget.controller.state.scene;
    _nameController = TextEditingController(text: scene.name);
    _descController = TextEditingController(text: scene.description);
    _tagsController = TextEditingController(text: scene.tags.join(', '));
  }

  void _save() {
    widget.controller.updateScene(
      BuilderScene(
        id: widget.controller.state.scene.id,
        name: _nameController.text,
        description: _descController.text,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scene updated')));
  }

  Widget _buildSuggestions() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final suggestions = BuilderSuggestionService.getSuggestions(
          variables: state.variables,
          objects: state.objects,
          rules: state.rules,
        );

        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Suggested Next Steps', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: suggestions.map((s) => Chip(
                    label: Text(s),
                    backgroundColor: Colors.white,
                    avatar: const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildSuggestions(),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Scene Name')),
          const SizedBox(height: 8),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 8),
          TextField(controller: _tagsController, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Save Metadata')),
        ],
      ),
    );
  }
}

