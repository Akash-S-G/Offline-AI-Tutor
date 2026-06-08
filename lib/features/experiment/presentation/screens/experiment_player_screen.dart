import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/models/experiment_models.dart';
import '../../application/orchestrator/experiment_execution_state.dart';
import '../controllers/experiment_player_controller.dart';
import '../widgets/experiment_status_banner.dart';
import '../widgets/measurement_counter_card.dart';
import '../widgets/execution_mode_chip.dart';
import '../runtime_visualization/controllers/runtime_visualization_controller.dart';
import '../runtime_visualization/widgets/runtime_visualization_container.dart';
import '../../domain/experiment_progress_repository.dart';

class ExperimentPlayerScreen extends StatefulWidget {
  final ExperimentManifest manifest;

  const ExperimentPlayerScreen({super.key, required this.manifest});

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
    _visualizationController.attachStream(_controller.eventStream);
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
    await _controller.prepare(widget.manifest);
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
        actions: [
          if (_controller.executionResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExecutionModeChip(mode: _controller.executionResult!.executionMode),
            ),
        ],
      ),
      body: Column(
        children: [
          ExperimentStatusBanner(state: _controller.state),
          
          if (_controller.metrics != null)
            MeasurementCounterCard(metrics: _controller.metrics!),

          if (_controller.state == ExperimentExecutionState.failed)
            _buildErrorState(),
            
          if (kDebugMode)
            _buildDiagnosticsPanel(),

          _buildControls(),

          const Divider(),
          
          Expanded(
            child: RuntimeVisualizationContainer(controller: _visualizationController),
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
      title: const Text('Runtime Diagnostics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      iconColor: Colors.grey,
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
                Text('Manifest: ${widget.manifest.id}'),
                Text('Events Logged: ${_controller.events.length}'),
                if (_controller.metrics != null) ...[
                  Text('FPS: ${_controller.metrics!.averageFps.toStringAsFixed(1)}'),
                  Text('Tick Rate: ${_controller.metrics!.ticksPerSecond.toStringAsFixed(1)}'),
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
