import 'package:flutter/foundation.dart';
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
  final RuntimeVisualizationController _visualizationController = RuntimeVisualizationController();
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
    await _controller.prepare(widget.manifest, payload: widget.executionPayload);
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
      appBar: AppBar(
        title: Text(widget.manifest.title),
        actions: const [],
      ),
      body: Column(
        children: [
          ExperimentStatusBanner(state: _controller.state),

          if (_controller.state == ExperimentExecutionState.failed)
            _buildErrorState(),
            
          if (kDebugMode)
            _buildDiagnosticsPanel(),

          _buildControls(),

          const Divider(),
          
          Expanded(
            flex: 2,
            child: _controller.world != null 
              ? GameWidget(game: ExperimentFlameGame(_controller.world!))
              : const Center(child: Text('Loading Simulation Canvas...')),
          ),
          
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: RuntimeVisualizationContainer(controller: _visualizationController)),
                if (_controller.world != null)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Relationship Graph', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: NativeGraphView(
                              model: RelationshipGraphModel.fromManifest(_controller.rawManifestData),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text('Runtime Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('The experiment engine encountered an error while preparing or running the simulation.', textAlign: TextAlign.center),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsPanel() {
    return ExpansionTile(
      title: const Text('Developer Diagnostics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      iconColor: Colors.blueAccent,
      collapsedIconColor: Colors.grey,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: Colors.black87,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('State: ${_controller.state.name.toUpperCase()}'),
                Text('Manifest ID: ${widget.manifest.id}'),
                if (_controller.world != null) ...[
                  Text('Profile: ${_controller.world!.profile.name.toUpperCase()}'),
                  Text('Variables: ${_controller.world!.variables.allVariables.length}'),
                  Text('Objects: ${_controller.world!.objects.allObjects.length}'),
                  Text('Events Logged: ${_controller.events.length}'),
                  Text('Rule Executions: ${_controller.world!.analytics.ruleExecutions}'),
                  Text('Variable Updates: ${_controller.world!.analytics.variableUpdates}'),
                  Text('Time Simulated: ${_controller.world!.clock.elapsedTime.toStringAsFixed(2)}s'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger snapshot print
                      final snapshot = RuntimeSerializer.serialize(_controller.world!);
                      print('--- RUNTIME SNAPSHOT ---');
                      print(snapshot);
                      print('------------------------');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                    child: const Text('Print Memory Snapshot', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final state = _controller.state;
    final isRunning = state == ExperimentExecutionState.running;
    final isPaused = state == ExperimentExecutionState.paused;
    final isPreparing = state == ExperimentExecutionState.preparing || 
                        state == ExperimentExecutionState.analyzing ||
                        state == ExperimentExecutionState.planning;
    final isReady = state == ExperimentExecutionState.idle || 
                    state == ExperimentExecutionState.starting;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isPreparing)
            const Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Preparing Runtime...', style: TextStyle(color: Colors.grey)),
              ],
            ),
            
          if (isReady && !isPreparing && state != ExperimentExecutionState.failed)
            ElevatedButton.icon(
              onPressed: () {
                _progressRepo?.markExperimentStarted(widget.manifest.id, widget.manifest.chapter);
                _controller.start();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('START'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          
          if (isRunning)
            ElevatedButton.icon(
              onPressed: () => _controller.pause(),
              icon: const Icon(Icons.pause),
              label: const Text('PAUSE'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),

          if (isPaused)
            ElevatedButton.icon(
              onPressed: () => _controller.resume(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('RESUME'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),

          if (isRunning || isPaused)
            ElevatedButton.icon(
              onPressed: () {
                _progressRepo?.markExperimentCompleted(widget.manifest.id, widget.manifest.chapter, score: 100);
                _controller.stop();
              },
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
