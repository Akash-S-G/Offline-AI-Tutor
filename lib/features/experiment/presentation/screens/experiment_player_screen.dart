import 'package:flutter/material.dart';
import '../../domain/models/experiment_models.dart';
import '../../application/orchestrator/experiment_execution_state.dart';
import '../controllers/experiment_player_controller.dart';
import '../widgets/experiment_status_banner.dart';
import '../runtime_visualization/controllers/runtime_visualization_controller.dart';
import '../runtime_visualization/widgets/runtime_visualization_container.dart';
import '../../domain/experiment_progress_repository.dart';
import 'package:flame/game.dart';
import '../../runtime/engine/experiment_flame_game.dart';
import '../../runtime/graphs/line_graph_renderer.dart';
import '../../runtime/runtime_serializer.dart';
import '../../runtime/relationship_graph_model.dart';
import '../../runtime/runtime_event.dart';
import '../../runtime/models/runtime_variable.dart';
import '../../runtime/scatter/scatter_plot_renderer.dart';
import '../widgets/native_graph_view.dart';

class ExperimentPlayerScreen extends StatefulWidget {
  final ExperimentManifest manifest;
  final Map<String, dynamic>? executionPayload;

  const ExperimentPlayerScreen({
    super.key,
    required this.manifest,
    this.executionPayload,
  });

  @override
  State<ExperimentPlayerScreen> createState() => _ExperimentPlayerScreenState();
}

class _ExperimentPlayerScreenState extends State<ExperimentPlayerScreen> {
  final ExperimentPlayerController _controller = ExperimentPlayerController();
  final RuntimeVisualizationController _visualizationController =
      RuntimeVisualizationController();
  ExperimentProgressRepository? _progressRepo;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
    _initOrchestrator();
    _initProgressTracking();
  }

  Future<void> _initProgressTracking() async {
    _progressRepo = await ExperimentProgressRepository.create();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Future<void> _initOrchestrator() async {
    await _controller.prepare(
      widget.manifest,
      payload: widget.executionPayload,
    );
    if (_controller.world != null) {
      _visualizationController.attachStream(_controller.world!.eventBus.stream);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _visualizationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.manifest.title), actions: const []),
      body: Column(
        children: [
          ExperimentStatusBanner(state: _controller.state),
          _buildRuntimeStatusIndicator(),

          if (_controller.state == ExperimentExecutionState.failed)
            _buildErrorState(),

          Expanded(
            flex: 5,
            child: _controller.world != null
                ? GameWidget(game: ExperimentFlameGame(_controller.world!))
                : const Center(child: Text('Loading Simulation Canvas...')),
          ),

          _buildControls(),

          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _buildRuntimeHealthCard(),
                _buildLastErrorPanel(),
                _buildActiveWarningsPanel(),
                _buildRuntimeInspector(),
                _buildRuleExecutionFeed(),
                _buildEventMonitor(),
                RuntimeVisualizationContainer(
                  controller: _visualizationController,
                ),
                _buildDiagnosticsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final lastError = _controller.lastError;
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Runtime Failed',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastError?.detail ??
                  'The experiment engine encountered an error while preparing or running the simulation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Force a retry by calling prepare again
                    _controller.prepare(widget.manifest);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeStatusIndicator() {
    final label = _statusLabel(_controller.state);
    final color = _statusColor(_controller.state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            _controller.world == null
                ? 'Runtime initializing'
                : 'Runtime ready',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ExperimentExecutionState state) {
    switch (state) {
      case ExperimentExecutionState.running:
        return 'RUNNING';
      case ExperimentExecutionState.paused:
        return 'PAUSED';
      case ExperimentExecutionState.failed:
        return 'FAILED';
      case ExperimentExecutionState.preparing:
      case ExperimentExecutionState.analyzing:
      case ExperimentExecutionState.planning:
        return 'PREPARING';
      default:
        return 'READY';
    }
  }

  Color _statusColor(ExperimentExecutionState state) {
    switch (state) {
      case ExperimentExecutionState.running:
        return Colors.green;
      case ExperimentExecutionState.paused:
        return Colors.orange;
      case ExperimentExecutionState.failed:
        return Colors.red;
      case ExperimentExecutionState.preparing:
      case ExperimentExecutionState.analyzing:
      case ExperimentExecutionState.planning:
        return Colors.blueGrey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildRuntimeHealthCard() {
    final world = _controller.world;
    final manifestLoaded = _controller.rawManifestData.isNotEmpty;
    final objectsLoaded = world != null && world.objects.allObjects.isNotEmpty;
    final variablesLoaded =
        world != null && world.variables.allVariables.isNotEmpty;
    final rulesLoaded = world != null;
    final runtimePrepared =
        world != null && _controller.state != ExperimentExecutionState.failed;
    final simulationRunning =
        _controller.state == ExperimentExecutionState.running;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Runtime Health',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _healthItem('Manifest Loaded', manifestLoaded),
                _healthItem('Objects Loaded', objectsLoaded),
                _healthItem('Variables Loaded', variablesLoaded),
                _healthItem('Rules Loaded', rulesLoaded),
                _healthItem('Runtime Prepared', runtimePrepared),
                _healthItem('Simulation Running', simulationRunning),
              ],
            ),
            if (_controller.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                _controller.lastError!.detail,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _summaryChip(
                  'Objects',
                  '${world?.objects.allObjects.length ?? 0}',
                ),
                _summaryChip(
                  'Variables',
                  '${world?.variables.allVariables.length ?? 0}',
                ),
                _summaryChip('Rules', '${world?.rules.allRules.length ?? 0}'),
                _summaryChip('Events', '${_controller.events.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthItem(String label, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: passed ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _summaryChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLastErrorPanel() {
    final error = _controller.lastError;
    if (error == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Error',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error.title, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 4),
            Text(error.detail),
            const SizedBox(height: 8),
            Text(
              'Timestamp: ${_formatTime(error.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWarningsPanel() {
    final warnings = _controller.events
        .where((event) => event.type == RuntimeEventType.warning)
        .take(5)
        .toList();
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Warnings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(warning.message),
                subtitle: Text(_formatTime(warning.timestamp)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsPanel() {
    return ExpansionTile(
      title: const Text(
        'Debug Information',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
      iconColor: Colors.blueAccent,
      collapsedIconColor: Colors.grey,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: Colors.black87,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'monospace',
              fontSize: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('State: ${_controller.state.name.toUpperCase()}'),
                Text('Manifest ID: ${widget.manifest.id}'),
                if (_controller.world != null) ...[
                  Text(
                    'Profile: ${_controller.world!.profile.name.toUpperCase()}',
                  ),
                  Text(
                    'Variables: ${_controller.world!.variables.allVariables.length}',
                  ),
                  Text(
                    'Objects: ${_controller.world!.objects.allObjects.length}',
                  ),
                  Text('Events Logged: ${_controller.events.length}'),
                  Text(
                    'Rule Executions: ${_controller.world!.analytics.ruleExecutions}',
                  ),
                  Text(
                    'Variable Updates: ${_controller.world!.analytics.variableUpdates}',
                  ),
                  Text(
                    'Time Simulated: ${_controller.world!.clock.elapsedTime.toStringAsFixed(2)}s',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Snapshot: ${RuntimeSerializer.serialize(_controller.world!)}',
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_controller.world != null)
          SizedBox(
            height: 260,
            child: NativeGraphView(
              model: RelationshipGraphModel.fromManifest(
                _controller.rawManifestData,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRuntimeInspector() {
    final world = _controller.world;
    final variables =
        world?.variables.allRuntimeVariables ??
        const <String, RuntimeVariable>{};
    final objects = world?.objects.allObjects ?? const <Map<String, dynamic>>[];
    final objectStates = world?.objects.allObjectStates ?? const [];
    final objectLifecycleStatuses =
        world?.objectLifecycle.getAllStatuses() ?? const [];
    final interactiveObjectStates = objectStates
        .where((state) {
          return state.objectType == 'slider' ||
              state.objectType == 'toggle' ||
              state.objectType == 'button';
        })
        .toList(growable: false);
    final bindings = world?.bindings.allBindings() ?? const [];
    final rules = world?.rules.allRules ?? const <Map<String, dynamic>>[];
    final timerVariables = world?.variableExecutor.timerVariables ?? const [];
    final computedVariables =
        world?.variableExecutor.computedVariables ?? const [];
    final measuredVariableIds =
        world?.measurementStore.trackedVariableIds ?? const <String>[];
    final graphStatuses = objectLifecycleStatuses
        .where((status) => status.objectType == 'lineGraph')
        .toList(growable: false);
    final scatterStatuses = objectLifecycleStatuses
        .where((status) => status.objectType == 'scatterPlot')
        .toList(growable: false);
    final sensorStates = world?.sensors.sensorStates ?? const [];
    final experimentState = world?.experimentState.state;
    final lastTick = world == null
        ? 'Waiting'
        : '${world.clock.elapsedTime.toStringAsFixed(2)}s';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check_outlined, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Runtime Inspector',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _inspectorChip('State', _controller.state.name),
                _inspectorChip('Objects', '${objects.length}'),
                _inspectorChip('Variables', '${variables.length}'),
                _inspectorChip('Rules', '${rules.length}'),
                _inspectorChip('Bindings', '${bindings.length}'),
                _inspectorChip('Events', '${_controller.events.length}'),
                _inspectorChip('Last Tick', lastTick),
                if (world != null)
                  _inspectorChip(
                    'Vars Registered',
                    '${world.analytics.variablesRegistered}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Vars Updated',
                    '${world.analytics.variableUpdates}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Vars Removed',
                    '${world.analytics.variablesRemoved}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Bindings Active',
                    '${bindings.where((binding) => binding.active).length}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Bindings Failed',
                    '${world.analytics.bindingsFailed}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Objects Updated',
                    '${world.analytics.objectsUpdated}',
                  ),
                if (world != null)
                  _inspectorChip('Schemas', '${world.analytics.schemasLoaded}'),
                if (world != null)
                  _inspectorChip(
                    'Behaviors',
                    '${world.analytics.behaviorsCreated}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Renderers',
                    '${world.analytics.renderersCreated}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Obj Validation Failures',
                    '${world.analytics.objectValidationFailures}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Slider Interactions',
                    '${world.analytics.sliderInteractions}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Toggle Interactions',
                    '${world.analytics.toggleInteractions}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Button Interactions',
                    '${world.analytics.buttonInteractions}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Rules Evaluated',
                    '${world.analytics.rulesEvaluated}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Rules Fired',
                    '${world.analytics.rulesFired}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Actions',
                    '${world.analytics.actionsExecuted}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Warnings',
                    '${world.analytics.warningsGenerated}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Timer Ticks',
                    '${world.analytics.timerTicks}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Countdowns',
                    '${world.analytics.countdownsFinished}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Intervals',
                    '${world.analytics.intervalEvents}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Computed',
                    '${world.analytics.computedEvaluations}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Dependencies',
                    '${world.analytics.dependencyResolutions}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Samples',
                    '${world.analytics.measurementsCollected}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Discarded Samples',
                    '${world.analytics.measurementsDiscarded}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Measured Vars',
                    '${world.analytics.measurementVariablesTracked}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Graphs Rendered',
                    '${world.analytics.graphsRendered}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Graph Updates',
                    '${world.analytics.graphUpdates}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Graph Samples',
                    '${world.analytics.graphSamplesProcessed}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Scatter Rendered',
                    '${world.analytics.scatterPlotsRendered}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Scatter Updates',
                    '${world.analytics.scatterPlotUpdates}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Scatter Points',
                    '${world.analytics.scatterPointsProcessed}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Sensor Vars',
                    '${world.analytics.sensorVariables}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Active Sensors',
                    '${world.analytics.activeSensors}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Sensor Samples',
                    '${world.analytics.sensorMeasurements}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Sensor Errors',
                    '${world.analytics.sensorErrors}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Permission Denials',
                    '${world.analytics.permissionDenials}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Observations',
                    '${world.analytics.observationsRecorded}',
                  ),
                if (world != null)
                  _inspectorChip('Rows', '${world.analytics.observationRows}'),
                if (world != null)
                  _inspectorChip(
                    'Exports',
                    '${world.analytics.observationExports}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Experiments Started',
                    '${world.analytics.experimentsStarted}',
                  ),
                if (world != null)
                  _inspectorChip(
                    'Experiments Done',
                    '${world.analytics.experimentsCompleted}',
                  ),
              ],
            ),
            if (experimentState != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Experiment State',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Status: ${experimentState.status.name}'),
                subtitle: Text(
                  'Runtime: ${(experimentState.runtime.inMilliseconds / 1000).toStringAsFixed(1)}s | '
                  'Measurements: ${experimentState.measurements} | '
                  'Observations: ${experimentState.observations} | '
                  'Warnings: ${experimentState.warnings} | '
                  'Rules Fired: ${experimentState.rulesTriggered}',
                ),
              ),
            ],
            if (world != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Observations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Rows: ${world.observationStore.rowCount}'),
                subtitle: Text(
                  'Mode: ${world.observationScheduler.collectionMode.name} | '
                  'Variables: ${world.observationScheduler.recordedVariableCount} | '
                  'Last: ${_formatInspectorValue(world.observationStore.latestObservation()?.values)}',
                ),
              ),
            ],
            if (world != null && objects.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Object Runtime Config',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...objects.map((object) {
                final properties = Map<String, dynamic>.from(
                  object['properties'] as Map? ?? const {},
                );
                final runtimeConfig = Map<String, dynamic>.from(
                  object['runtimeConfig'] as Map? ??
                      properties['runtimeConfig'] as Map? ??
                      const {},
                );
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    object['name']?.toString() ??
                        object['objectId']?.toString() ??
                        'Object',
                  ),
                  subtitle: Text(
                    runtimeConfig.isEmpty
                        ? 'No runtime config'
                        : runtimeConfig.entries
                              .map((entry) => '${entry.key}: ${entry.value}')
                              .join(' | '),
                  ),
                );
              }),
            ],
            if (graphStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Graph Objects',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...graphStatuses.map((status) {
                final object = world?.objects.get(status.objectId);
                final properties = Map<String, dynamic>.from(
                  object?['properties'] as Map? ?? const {},
                );
                final linkedVariableId =
                    properties['linked_variable'] ??
                    properties['linkedVariable'] ??
                    properties['valueVariable'];
                final renderer = world?.objectLifecycle.getRenderer(
                  status.objectId,
                );
                final graphState = renderer is LineGraphRenderer
                    ? renderer.graphState
                    : null;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(object?['name']?.toString() ?? status.objectId),
                  subtitle: Text(
                    'linked=${linkedVariableId ?? 'None'} | '
                    'samples=${graphState?.sampleCount ?? 0} | '
                    'min=${graphState == null ? 'None' : _formatInspectorValue(graphState.minY)} | '
                    'max=${graphState == null ? 'None' : _formatInspectorValue(graphState.maxY)}',
                  ),
                );
              }),
            ],
            if (scatterStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Scatter Plots',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...scatterStatuses.map((status) {
                final object = world?.objects.get(status.objectId);
                final properties = Map<String, dynamic>.from(
                  object?['properties'] as Map? ?? const {},
                );
                final renderer = world?.objectLifecycle.getRenderer(
                  status.objectId,
                );
                final scatterState = renderer is ScatterPlotRenderer
                    ? renderer.scatterState
                    : null;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(object?['name']?.toString() ?? status.objectId),
                  subtitle: Text(
                    'x=${properties['xVariable'] ?? properties['x_variable'] ?? 'None'} | '
                    'y=${properties['yVariable'] ?? properties['y_variable'] ?? 'None'} | '
                    'points=${scatterState?.pointCount ?? 0} | '
                    'xRange=${scatterState == null ? 'None' : '${_formatInspectorValue(scatterState.minX)}..${_formatInspectorValue(scatterState.maxX)}'} | '
                    'yRange=${scatterState == null ? 'None' : '${_formatInspectorValue(scatterState.minY)}..${_formatInspectorValue(scatterState.maxY)}'}',
                  ),
                );
              }),
            ],
            if (sensorStates.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Sensor Runtime',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sensorStates.map((state) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(state.type.name),
                  subtitle: Text(
                    'active=${state.active} | '
                    'paused=${state.paused} | '
                    'available=${state.available} | '
                    'measurements=${state.measurementCount} | '
                    'last=${state.lastMeasurementAt == null ? 'None' : _formatTime(state.lastMeasurementAt!)}'
                    '${state.lastError == null ? '' : ' | error=${state.lastError}'}'
                    '${state.warning == null ? '' : ' | warning=${state.warning}'}',
                  ),
                );
              }),
            ],
            if (measuredVariableIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Measurements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...measuredVariableIds.map((variableId) {
                final variable = world?.variables.getVariable(variableId);
                final history =
                    world?.measurementStore.getMeasurements(variableId) ??
                    const [];
                final latest = world?.measurementStore.getLatestMeasurement(
                  variableId,
                );
                final oldest = history.isEmpty ? null : history.first;
                final newest = history.isEmpty ? null : history.last;
                final policy = world?.measurementCollector.policyFor(
                  variableId,
                );
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(variable?.name ?? variableId),
                  subtitle: Text(
                    'Samples: ${history.length} | '
                    'Latest: ${_formatInspectorValue(latest?.value)} | '
                    'Policy: ${policy?.name ?? 'unknown'} | '
                    'Oldest: ${oldest == null ? 'None' : oldest.runtimeSeconds.toStringAsFixed(2)}s | '
                    'Newest: ${newest == null ? 'None' : newest.runtimeSeconds.toStringAsFixed(2)}s',
                  ),
                );
              }),
            ],
            if (timerVariables.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Timer Variables',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...timerVariables.map((variable) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(variable.name),
                  subtitle: Text(
                    'type=${variable.type} | '
                    'value=${_formatInspectorValue(variable.value)} | '
                    'updated=${_formatTime(variable.lastUpdated)}',
                  ),
                );
              }),
            ],
            if (computedVariables.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Computed Variables',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...computedVariables.map((variable) {
                final dependencies =
                    world?.variableExecutor.dependenciesFor(variable.id) ??
                    const <String>[];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(variable.name),
                  subtitle: Text(
                    'Formula: ${_formulaForVariable(variable.type)} | '
                    'Dependencies: ${dependencies.length} | '
                    'Current Value: ${_formatInspectorValue(variable.value)} | '
                    'deps=${dependencies.isEmpty ? 'None' : dependencies.join(', ')} | '
                    'updated=${_formatTime(variable.lastUpdated)}',
                  ),
                );
              }),
            ],
            if (world?.rules.ruleStates.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text(
                'Rule Definitions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...world!.rules.allRules.map((rule) {
                final condition = Map<String, dynamic>.from(
                  rule['condition'] as Map? ?? const {},
                );
                final actions = rule['actions'] is List
                    ? List<Map<String, dynamic>>.from(
                        (rule['actions'] as List).map(
                          (entry) => Map<String, dynamic>.from(entry as Map),
                        ),
                      )
                    : [
                        Map<String, dynamic>.from(
                          rule['action'] as Map? ?? const {},
                        ),
                      ];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(rule['name']?.toString() ?? 'Rule'),
                  subtitle: Text(
                    'Condition: ${condition['variableId']} ${condition['operator']} ${condition['value']} | '
                    'Actions: ${actions.map((action) => _formatRuleDefinitionAction(action)).join(', ')}',
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Rule Inspector',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...world.rules.ruleStates.map((state) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(state.rule.name),
                  subtitle: Text(
                    'last=${state.lastEvaluation == null ? 'Never' : _formatTime(state.lastEvaluation!)} | '
                    'result=${state.lastResult == null
                        ? 'None'
                        : state.lastResult!
                        ? 'PASSED'
                        : 'FAILED'} | '
                    'fireCount=${state.fireCount}',
                  ),
                );
              }),
            ],
            if (interactiveObjectStates.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Interactive Objects',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...interactiveObjectStates.map((objectState) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${objectState.objectId} (${objectState.objectType})',
                  ),
                  subtitle: Text(
                    'value=${objectState.state['value']} | '
                    'enabled=${objectState.state['enabled']} | '
                    'pressed=${objectState.state['pressed']} | '
                    'pressCount=${objectState.state['pressCount']} | '
                    'updated=${_formatTime(objectState.updatedAt)}',
                  ),
                );
              }),
              if (world?.analytics.lastInteractionTime != null)
                Text(
                  'Last interaction: '
                  '${world!.analytics.lastInteractionSource ?? 'unknown'} '
                  'at ${_formatTime(world.analytics.lastInteractionTime!)}',
                ),
            ],
            if (objectLifecycleStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Rendered Objects',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...objectLifecycleStatuses
                  .where((status) => status.rendererLoaded)
                  .map((status) {
                    final objectState = world?.objects.getObjectState(
                      status.objectId,
                    );
                    final renderer = world?.objectLifecycle.getRenderer(
                      status.objectId,
                    );
                    final lastRenderTime = renderer?.lastRenderTime;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(status.objectId),
                      subtitle: Text(
                        'renderer=${renderer?.rendererType ?? 'Missing'} | '
                        'visible=${objectState?.visible ?? false} | '
                        'lastRender=${lastRenderTime == null ? 'Never' : _formatTime(lastRenderTime)}',
                      ),
                    );
                  }),
            ],
            if (objectLifecycleStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Runtime Objects',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...objectLifecycleStatuses.map((status) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${status.objectId} (${status.objectType})'),
                  subtitle: Text(
                    'Schema ${status.schemaLoaded ? 'OK' : 'Missing'} | '
                    'Behavior ${status.behaviorLoaded ? 'OK' : 'Missing'} | '
                    'Renderer ${status.rendererLoaded ? 'OK' : 'Missing'} | '
                    'Valid ${status.isValid ? 'OK' : 'Failed'}',
                  ),
                );
              }),
            ],
            if (bindings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Bindings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...bindings.map((binding) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${binding.variableId} -> '
                    '${binding.objectId}.${binding.objectProperty}',
                  ),
                  trailing: Text(binding.active ? 'ACTIVE' : 'FAILED'),
                );
              }),
            ],
            if (objectStates.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Object Inspector',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...objectStates.map((objectState) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objectState.objectId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('type: ${objectState.objectType}'),
                      Text('visible: ${objectState.visible}'),
                      Text('state: ${objectState.state}'),
                    ],
                  ),
                );
              }),
            ],
            if (variables.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Variable Monitor',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...variables.values.map((variable) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variable.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${variable.id}'),
                      Text('type: ${variable.type}'),
                      Text('value: ${_formatInspectorValue(variable.value)}'),
                      Text('source: ${variable.source.name}'),
                      Text('strategy: ${variable.updateStrategy.name}'),
                      Text('updated: ${_formatTime(variable.lastUpdated)}'),
                      Text('initialized: ${variable.isInitialized}'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleExecutionFeed() {
    final ruleEvents = _controller.events.where(_isRuleEvent).take(8).toList();
    final rules = _controller.world?.rules.allRules ?? const [];
    final lastTrigger = ruleEvents.isEmpty
        ? 'None'
        : _formatElapsed(ruleEvents.first.timestamp);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Rule Execution Feed',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _summaryChip('Rules Loaded', '${rules.length}'),
                _summaryChip('Rules Triggered', '${ruleEvents.length}'),
                _summaryChip('Last Trigger', lastTrigger),
              ],
            ),
            const SizedBox(height: 12),
            if (ruleEvents.isEmpty)
              const Text(
                'No rules have triggered yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...ruleEvents.map(_buildRuleEventRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleEventRow(RuntimeEvent event) {
    final rule = _findRuleForEvent(event);
    final condition = rule?['condition'];
    final action = rule?['action'];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(
        _formatElapsed(event.timestamp),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: Text(_formatRuleCondition(condition, event)),
      subtitle: Text('Action: ${_formatRuleAction(action)}'),
      trailing: const Text(
        'TRUE',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEventMonitor() {
    final events = _controller.events.take(12).toList();
    final processed = _visualizationController.state.eventsProcessed;
    final pending = (_controller.events.length - processed).clamp(0, 9999);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Event Monitor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _summaryChip('Events Fired', '${_controller.events.length}'),
                _summaryChip('Events Processed', '$processed'),
                _summaryChip('Events Pending', '$pending'),
              ],
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text(
                'No runtime events have fired yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...events.map(_buildEventRow),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(RuntimeEvent event) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(_eventIcon(event), color: _eventColor(event), size: 20),
      title: Text(_eventCategory(event)),
      subtitle: Text(_eventDescription(event)),
      trailing: Text(
        _formatElapsed(event.timestamp),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  bool _isRuleEvent(RuntimeEvent event) {
    return event.message == 'RuleTriggered' ||
        event.message == 'RuleEvaluated' ||
        event.message == 'RulePassed' ||
        event.message == 'RuleFailed' ||
        event.message == 'RuleFired' ||
        event.metadata?['playgroundEventType'] == 'ruleExecuted';
  }

  Map<String, dynamic>? _findRuleForEvent(RuntimeEvent event) {
    final ruleId = event.metadata?['ruleId']?.toString();
    if (ruleId == null) return null;
    for (final rule in _controller.world?.rules.allRules ?? const []) {
      if (rule['ruleId']?.toString() == ruleId) return rule;
    }
    return null;
  }

  String _formatRuleCondition(dynamic condition, RuntimeEvent event) {
    if (condition is Map) {
      return '${condition['variableId'] ?? 'value'} ${condition['operator'] ?? ''} ${condition['value'] ?? ''}';
    }
    if (condition != null) return condition.toString();
    return event.metadata?['ruleId']?.toString() ?? event.message;
  }

  String _formatRuleAction(dynamic action) {
    if (action is Map) {
      return _titleCase(action['type']?.toString() ?? 'Action');
    }
    if (action != null) return action.toString();
    return 'No action payload';
  }

  String _eventCategory(RuntimeEvent event) {
    if (_isRuleEvent(event)) return 'Rule Event';
    switch (event.type) {
      case RuntimeEventType.measurementReceived:
        return 'Sensor Update';
      case RuntimeEventType.sessionStarted:
      case RuntimeEventType.sessionPaused:
      case RuntimeEventType.sessionResumed:
      case RuntimeEventType.sessionStopped:
      case RuntimeEventType.sessionCompleted:
      case RuntimeEventType.sessionCreated:
        return 'Runtime Event';
      case RuntimeEventType.warning:
        return 'Runtime Warning';
      case RuntimeEventType.error:
        return 'Runtime Error';
      case RuntimeEventType.custom:
        final pType = event.metadata?['playgroundEventType']?.toString();
        if (pType == 'buttonPressed') return 'Button Press';
        if (pType == 'timerTick') return 'Timer Event';
        return 'Runtime Event';
    }
  }

  String _eventDescription(RuntimeEvent event) {
    final payload = event.metadata?['payload'];
    if (payload is Map && payload.isNotEmpty) {
      return payload.entries
          .take(2)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
    }
    if (event.type == RuntimeEventType.measurementReceived) {
      return event.metadata?['sensorType']?.toString() ?? event.message;
    }
    return event.message;
  }

  IconData _eventIcon(RuntimeEvent event) {
    if (_isRuleEvent(event)) return Icons.rule;
    switch (event.type) {
      case RuntimeEventType.measurementReceived:
        return Icons.sensors;
      case RuntimeEventType.warning:
        return Icons.warning_amber;
      case RuntimeEventType.error:
        return Icons.error_outline;
      case RuntimeEventType.custom:
        return Icons.bolt;
      default:
        return Icons.play_circle_outline;
    }
  }

  Color _eventColor(RuntimeEvent event) {
    if (_isRuleEvent(event)) return Colors.deepPurple;
    switch (event.type) {
      case RuntimeEventType.measurementReceived:
        return Colors.blue;
      case RuntimeEventType.warning:
        return Colors.orange;
      case RuntimeEventType.error:
        return Colors.red;
      case RuntimeEventType.custom:
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatElapsed(DateTime timestamp) => _formatTime(timestamp);

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _inspectorChip(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatInspectorValue(dynamic value) {
    if (value is double) return value.toStringAsFixed(2);
    return value.toString();
  }

  String _formulaForVariable(String type) {
    switch (type) {
      case 'average':
        return 'mean(dependencies)';
      case 'minimum':
        return 'min(dependencies)';
      case 'maximum':
        return 'max(dependencies)';
      case 'distance':
        return 'speed x time';
      case 'velocity':
        return 'distance / time';
      case 'acceleration':
        return 'velocity / time';
      case 'force':
        return 'mass x acceleration';
      case 'power':
        return 'force x velocity';
      case 'energy':
        return 'power x time';
      default:
        return type;
    }
  }

  String _formatRuleDefinitionAction(Map<String, dynamic> action) {
    final type = action['type']?.toString() ?? 'action';
    switch (type) {
      case 'hide_object':
      case 'show_object':
        return '$type(${action['objectId'] ?? ''})';
      case 'set_variable':
        return '$type(${action['variableId'] ?? ''}=${action['value'] ?? ''})';
      case 'toggle_variable':
        return '$type(${action['variableId'] ?? ''})';
      case 'show_warning':
      default:
        return type;
    }
  }

  Widget _buildControls() {
    final state = _controller.state;
    final isRunning = state == ExperimentExecutionState.running;
    final isPaused = state == ExperimentExecutionState.paused;
    final isPreparing =
        state == ExperimentExecutionState.preparing ||
        state == ExperimentExecutionState.analyzing ||
        state == ExperimentExecutionState.planning;
    final isReady =
        state == ExperimentExecutionState.idle ||
        state == ExperimentExecutionState.starting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (isPreparing)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Preparing Runtime...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

          if (isReady &&
              !isPreparing &&
              state != ExperimentExecutionState.failed)
            ElevatedButton.icon(
              onPressed: () {
                _progressRepo?.markExperimentStarted(
                  widget.manifest.id,
                  widget.manifest.chapter,
                );
                _controller.start();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('START'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

          if (isRunning)
            ElevatedButton.icon(
              onPressed: () => _controller.pause(),
              icon: const Icon(Icons.pause),
              label: const Text('PAUSE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

          if (isPaused)
            ElevatedButton.icon(
              onPressed: () => _controller.resume(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('RESUME'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

          if (isRunning || isPaused)
            ElevatedButton.icon(
              onPressed: _controller.world == null
                  ? null
                  : () {
                      final observation = _controller.world!
                          .recordObservation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Recorded observation ${observation.values.length} values',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Record Observation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),

          if (isRunning || isPaused)
            ElevatedButton.icon(
              onPressed: () {
                _progressRepo?.markExperimentCompleted(
                  widget.manifest.id,
                  widget.manifest.chapter,
                  score: 100,
                );
                _controller.stop();
              },
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
