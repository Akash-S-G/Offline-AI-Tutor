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
import '../../runtime/runtime_serializer.dart';
import '../../runtime/relationship_graph_model.dart';
import '../../runtime/runtime_event.dart';
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
        world?.variables.allVariables ?? const <String, dynamic>{};
    final objects = world?.objects.allObjects ?? const <Map<String, dynamic>>[];
    final rules = world?.rules.allRules ?? const <Map<String, dynamic>>[];
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
                _inspectorChip('Events', '${_controller.events.length}'),
                _inspectorChip('Last Tick', lastTick),
              ],
            ),
            if (variables.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Variable Monitor',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: variables.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key} = ${_formatInspectorValue(entry.value)}',
                    ),
                  );
                }).toList(),
              ),
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
