import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../../application/execution_definition_mapper.dart';
import '../../runtime/playground/engine/simulation_playground_engine.dart';
import 'dart:convert';

class RuntimePreviewPanel extends StatefulWidget {
  final ExperimentBuilderController controller;

  const RuntimePreviewPanel({super.key, required this.controller});

  @override
  State<RuntimePreviewPanel> createState() => _RuntimePreviewPanelState();
}

class _RuntimePreviewPanelState extends State<RuntimePreviewPanel> {
  final SimulationPlaygroundEngine _engine = SimulationPlaygroundEngine();
  String _status = 'Idle';
  int _objectCount = 0;
  int _variableCount = 0;

  Set<String> _knownVariables = {};
  Set<String> _knownObjects = {};
  Set<String> _knownRules = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_engine.state != PlaygroundState.loaded &&
        _engine.state != PlaygroundState.running) {
      return;
    }

    final state = widget.controller.state;
    final newVarIds = state.variables.map((v) => v.id).toSet();
    final newObjIds = state.objects.map((o) => o.id).toSet();
    final newRuleIds = state.rules.map((r) => r.id).toSet();

    // Variables
    final varsToAdd = newVarIds.difference(_knownVariables);
    final varsToRemove = _knownVariables.difference(newVarIds);
    for (final vId in varsToRemove) {
      _engine.removeVariable(vId);
    }
    for (final vId in varsToAdd) {
      final v = state.variables.firstWhere((x) => x.id == vId);
      final model = ExecutionDefinitionMapper.mapVariable(
        jsonDecode(jsonEncode(v.toJson())),
      );
      _engine.addVariable(model);
    }
    _knownVariables = newVarIds;

    // Objects
    final objsToAdd = newObjIds.difference(_knownObjects);
    final objsToRemove = _knownObjects.difference(newObjIds);
    for (final oId in objsToRemove) {
      _engine.removeObject(oId);
    }
    for (final oId in objsToAdd) {
      final o = state.objects.firstWhere((x) => x.id == oId);
      final model = ExecutionDefinitionMapper.mapObject(
        jsonDecode(jsonEncode(o.toJson())),
      );
      _engine.addObject(model);
    }
    _knownObjects = newObjIds;

    // Rules
    final rulesToAdd = newRuleIds.difference(_knownRules);
    final rulesToRemove = _knownRules.difference(newRuleIds);
    for (final rId in rulesToRemove) {
      _engine.removeRule(rId);
    }
    for (final rId in rulesToAdd) {
      final r = state.rules.firstWhere((x) => x.id == rId);
      final model = ExecutionDefinitionMapper.mapRule(
        jsonDecode(jsonEncode(r.toJson())),
      );
      _engine.addRule(model);
    }
    _knownRules = newRuleIds;

    setState(() {
      _objectCount = newObjIds.length;
      _variableCount = newVarIds.length;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _engine.dispose();
    super.dispose();
  }

  void _runPreview() {
    final isValid = widget.controller.validateManifest();
    if (!isValid) {
      setState(() {
        _status =
            'Validation Failed: ${widget.controller.validationResult?.errors.join(', ')}';
      });
      return;
    }

    try {
      final manifestJson = widget.controller.generateManifest();
      final decodedJson = jsonDecode(jsonEncode(manifestJson));
      final sceneModel = ExecutionDefinitionMapper.mapToScene(decodedJson);

      _engine.loadSceneModel(sceneModel);

      final state = widget.controller.state;
      _knownVariables = state.variables.map((v) => v.id).toSet();
      _knownObjects = state.objects.map((o) => o.id).toSet();
      _knownRules = state.rules.map((r) => r.id).toSet();

      setState(() {
        _status = 'Preview Engine Loaded Successfully.';
        _objectCount = sceneModel.objects.length;
        _variableCount = sceneModel.variables.length;
      });
    } catch (e) {
      setState(() {
        _status = 'Engine Load Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final validation = widget.controller.currentValidation;
    final state = widget.controller.state;
    final isEmptyManifest =
        state.variables.isEmpty && state.objects.isEmpty && state.rules.isEmpty;
    final canLoad = !isEmptyManifest && validation.isValid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: canLoad ? _runPreview : null,
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('Validate & Load into Engine'),
          ),
          if (isEmptyManifest) ...[
            const SizedBox(height: 8),
            const Text(
              'Add at least one variable, object, or rule before loading the preview engine.',
              style: TextStyle(color: Colors.red),
            ),
          ],
          if (!validation.isValid) ...[
            const SizedBox(height: 8),
            ...validation.errors.map(
              (error) => Text(error, style: const TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: $_status',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category, size: 16),
                        label: Text('Objects Loaded: $_objectCount'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.data_object, size: 16),
                        label: Text('Variables Loaded: $_variableCount'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
