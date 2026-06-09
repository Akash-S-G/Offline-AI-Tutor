import 'package:flutter/material.dart';
import '../controllers/experiment_builder_controller.dart';
import '../models/builder_object.dart';
import '../models/builder_variable.dart';

import '../../../shared/presentation/widgets/error_state_card.dart';
import '../../domain/models/experiment_models.dart';
import '../../domain/enums/experiment_enums.dart';
import '../../presentation/screens/experiment_player_screen.dart';

class BuilderExecutionPreviewPanel extends StatelessWidget {
  final ExperimentBuilderController controller;

  const BuilderExecutionPreviewPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pkg = controller.executionPackage;
        final validation = controller.currentValidation;
        final state = controller.state;
        final isEmptyManifest =
            state.variables.isEmpty &&
            state.objects.isEmpty &&
            state.rules.isEmpty;
        final canFetch =
            !controller.isLoading && !isEmptyManifest && validation.isValid;
        final scene = pkg?['scene'] as Map<String, dynamic>?;
        final variables = scene?['variables'] as List<dynamic>? ?? [];
        final objects = scene?['objects'] as List<dynamic>? ?? [];
        final rules = scene?['rules'] as List<dynamic>? ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: canFetch
                    ? () => controller.fetchExecutionPackage()
                    : null,
                icon: const Icon(Icons.memory),
                label: const Text('Fetch Execution Package'),
              ),
              const SizedBox(height: 16),
              _buildManifestInspector(validation, isEmptyManifest),
              const SizedBox(height: 16),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (controller.error != null && !controller.isLoading)
                ErrorStateCard(
                  error: controller.error!,
                  onRetry: () => controller.fetchExecutionPackage(),
                ),
              if (pkg != null &&
                  !controller.isLoading &&
                  controller.error == null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text('Mode: ${pkg['mode'] ?? 'unknown'}'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                            Chip(
                              label: Text(
                                'Coverage: ${pkg['coveragePercentage'] ?? 0}%',
                              ),
                              backgroundColor: Colors.green.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Missing Sensors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (pkg['missingSensors'] as List<dynamic>? ?? []).join(
                            ", ",
                          ),
                        ),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Variables: ${variables.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Objects: ${objects.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rules: ${rules.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final scene = controller.state.scene;
                              final manifest = ExperimentManifest(
                                id: scene.id,
                                title: scene.name,
                                description: scene.description,
                                subject: 'Physics', // Mock
                                grade: '10th', // Mock
                                chapter: 'Builder', // Mock
                                topic: 'Custom', // Mock
                                difficulty: ExperimentDifficulty.medium,
                                requiredSensors: List<String>.from(
                                  pkg['missingSensors'] ?? [],
                                ),
                                supportedModes: [
                                  ExperimentExecutionMode.simulation,
                                ],
                                steps: [],
                                visualizations: [],
                                estimatedDurationMinutes: 10,
                                supportsSimulation: true,
                                supportsSensorExecution: false,
                                supportsObservationMode: false,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExperimentPlayerScreen(
                                    manifest: manifest,
                                    executionPayload:
                                        pkg as Map<String, dynamic>?,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Launch Runtime'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildManifestInspector(dynamic validation, bool isEmptyManifest) {
    final state = controller.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manifest Inspector',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(label: Text('Objects: ${state.objects.length}')),
                Chip(label: Text('Variables: ${state.variables.length}')),
                Chip(label: Text('Rules: ${state.rules.length}')),
              ],
            ),
            const SizedBox(height: 12),
            _idSection(
              'Variable IDs',
              state.variables
                  .map((item) => '${item.name}: ${item.id}')
                  .toList(),
            ),
            _idSection(
              'Object IDs',
              state.objects.map((item) => '${item.name}: ${item.id}').toList(),
            ),
            _idSection(
              'Rule IDs',
              state.rules.map((item) => '${item.name}: ${item.id}').toList(),
            ),
            const SizedBox(height: 8),
            _variableRuntimeValidationSection(),
            const SizedBox(height: 8),
            _runtimeValidationSection(),
            if (isEmptyManifest) ...[
              const SizedBox(height: 12),
              const Text(
                'Manifest is empty. Add variables, objects, or rules before preparing runtime.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            if (!validation.isValid) ...[
              const SizedBox(height: 12),
              ...validation.errors.map<Widget>(
                (error) =>
                    Text(error, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _variableRuntimeValidationSection() {
    final state = controller.state;
    final variableIds = state.variables.map((variable) => variable.id).toSet();
    final rows = <(bool, String)>[
      ...state.variables.map(
        (variable) => _variableRuntimeValidation(variable, variableIds),
      ),
      ..._dependencyCycleMessages(state.variables),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variable Runtime Validation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          const Text('No variables', style: TextStyle(color: Colors.grey))
        else
          ...rows.map((result) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.$1 ? Icons.check_circle : Icons.cancel,
                  color: result.$1 ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.$2,
                    style: TextStyle(
                      color: result.$1 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  (bool, String) _variableRuntimeValidation(
    BuilderVariable variable,
    Set<String> variableIds,
  ) {
    final config = variable.runtimeConfig;
    bool exists(String key) {
      final id = config[key]?.toString();
      return id != null && id.isNotEmpty && variableIds.contains(id);
    }

    switch (variable.type) {
      case 'countdown':
        return (_number(config, 'startValue') > 0, 'Countdown Config Valid');
      case 'interval':
        return (
          _number(config, 'intervalSeconds') > 0,
          'Interval Config Valid',
        );
      case 'average':
      case 'minimum':
      case 'maximum':
        final deps = _variableDependencies(variable);
        return deps.length >= 2 && deps.every(variableIds.contains)
            ? (true, '${variable.name} dependencies valid')
            : (false, '${variable.name} dependencies invalid');
      case 'distance':
        return exists('speedVariable') && exists('timeVariable')
            ? (true, 'Distance dependencies valid')
            : (false, 'Distance dependencies invalid');
      case 'velocity':
        return exists('distanceVariable') && exists('timeVariable')
            ? (true, 'Velocity dependencies valid')
            : (false, 'Velocity dependencies invalid');
      case 'acceleration':
        return exists('velocityVariable') && exists('timeVariable')
            ? (true, 'Acceleration dependencies valid')
            : (false, 'Acceleration dependencies invalid');
      case 'force':
        return exists('massVariable') && exists('accelerationVariable')
            ? (true, 'Force dependencies valid')
            : (false, 'Force dependencies invalid');
      case 'power':
        return exists('forceVariable') && exists('velocityVariable')
            ? (true, 'Power dependencies valid')
            : (false, 'Power dependencies invalid');
      case 'energy':
        return exists('powerVariable') && exists('timeVariable')
            ? (true, 'Energy dependencies valid')
            : (false, 'Energy dependencies invalid');
      default:
        return (true, '${variable.name} Config Valid');
    }
  }

  List<(bool, String)> _dependencyCycleMessages(
    List<BuilderVariable> variables,
  ) {
    final graph = {
      for (final variable in variables)
        if (_variableDependencies(variable).isNotEmpty)
          variable.id: _variableDependencies(variable),
    };
    final cycles = <String>{};
    final visiting = <String>{};
    final visited = <String>{};
    final stack = <String>[];

    void dfs(String node) {
      if (visiting.contains(node)) {
        final start = stack.indexOf(node);
        if (start >= 0) {
          cycles.add([...stack.sublist(start), node].join(' -> '));
        }
        return;
      }
      if (visited.contains(node)) return;
      visiting.add(node);
      stack.add(node);
      for (final next in graph[node] ?? const <String>[]) {
        if (graph.containsKey(next)) dfs(next);
      }
      stack.removeLast();
      visiting.remove(node);
      visited.add(node);
    }

    for (final node in graph.keys) {
      dfs(node);
    }
    return cycles
        .map((cycle) => (false, 'Circular dependency detected: $cycle'))
        .toList();
  }

  double _number(Map<String, dynamic> config, String key) {
    final value = config[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _variableDependencies(BuilderVariable variable) {
    final config = variable.runtimeConfig;
    switch (variable.type) {
      case 'average':
      case 'minimum':
      case 'maximum':
        final value = config['dependencies'];
        if (value is List) {
          return value.map((entry) => entry.toString()).toList(growable: false);
        }
        return const [];
      case 'distance':
        return _ids(config, ['speedVariable', 'timeVariable']);
      case 'velocity':
        return _ids(config, ['distanceVariable', 'timeVariable']);
      case 'acceleration':
        return _ids(config, ['velocityVariable', 'timeVariable']);
      case 'force':
        return _ids(config, ['massVariable', 'accelerationVariable']);
      case 'power':
        return _ids(config, ['forceVariable', 'velocityVariable']);
      case 'energy':
        return _ids(config, ['powerVariable', 'timeVariable']);
      default:
        return const [];
    }
  }

  List<String> _ids(Map<String, dynamic> config, List<String> keys) {
    return keys
        .map((key) => config[key]?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Widget _runtimeValidationSection() {
    final state = controller.state;
    final variableIds = state.variables.map((variable) => variable.id).toSet();
    final rows = state.objects.map((object) {
      final result = _objectRuntimeValidation(object, variableIds);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.$1 ? Icons.check_circle : Icons.cancel,
            color: result.$1 ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.$2,
              style: TextStyle(color: result.$1 ? Colors.green : Colors.red),
            ),
          ),
        ],
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Object Runtime Validation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          const Text('No objects', style: TextStyle(color: Colors.grey))
        else
          ...rows,
      ],
    );
  }

  (bool, String) _objectRuntimeValidation(
    BuilderObject object,
    Set<String> variableIds,
  ) {
    final config = Map<String, dynamic>.from(object.runtimeConfig);
    final type = object.type;
    final name = object.name;
    num? number(String key) {
      final value = config[key];
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '');
    }

    switch (type) {
      case 'numericDisplay':
        final precision = number('precision') ?? 0;
        return precision >= 0
            ? (true, 'Numeric Display Config Valid')
            : (false, 'Numeric Display "$name" precision must be >= 0');
      case 'gauge':
        final min = number('min') ?? 0;
        final max = number('max') ?? 100;
        final threshold = number('warningThreshold');
        if (min >= max) return (false, 'Gauge "$name" min must be < max');
        if (threshold != null && (threshold < min || threshold > max)) {
          return (false, 'Gauge "$name" threshold outside range');
        }
        return (true, 'Gauge Config Valid');
      case 'progressBar':
        final min = number('min') ?? 0;
        final max = number('max') ?? 100;
        return min < max
            ? (true, 'Progress Bar Config Valid')
            : (false, 'Progress Bar "$name" min must be < max');
      case 'lineGraph':
        final variableId =
            config['variableId']?.toString() ??
            object.properties['linked_variable']?.toString();
        return variableIds.contains(variableId)
            ? (true, 'Line Graph Config Valid')
            : (false, 'Line Graph "$name" missing variable');
      case 'scatterPlot':
        final x = config['xVariable']?.toString();
        final y = config['yVariable']?.toString();
        if (x == null || x.isEmpty || !variableIds.contains(x)) {
          return (false, 'Missing X Variable');
        }
        if (y == null || y.isEmpty || !variableIds.contains(y)) {
          return (false, 'Missing Y Variable');
        }
        if (x == y) return (false, 'Scatter Plot variables must differ');
        return (true, 'Scatter Plot Valid');
      case 'table':
        final maxRows = number('maxRows') ?? 100;
        return maxRows > 0
            ? (true, 'Table Config Valid')
            : (false, 'Table "$name" maxRows must be > 0');
      default:
        return (true, '${object.type} Config Valid');
    }
  }

  Widget _idSection(String title, List<String> ids) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (ids.isEmpty)
            const Text('None', style: TextStyle(color: Colors.grey))
          else
            ...ids.map(
              (id) => Text(id, style: const TextStyle(fontFamily: 'monospace')),
            ),
        ],
      ),
    );
  }
}
