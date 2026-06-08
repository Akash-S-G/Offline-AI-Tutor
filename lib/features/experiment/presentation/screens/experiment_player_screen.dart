import 'package:flutter/material.dart';
import '../../domain/models/experiment_models.dart';
import '../../application/orchestrator/experiment_execution_state.dart';
import '../controllers/experiment_player_controller.dart';
import '../widgets/experiment_status_banner.dart';
import '../widgets/measurement_counter_card.dart';
import '../widgets/execution_mode_chip.dart';
import '../runtime_visualization/controllers/runtime_visualization_controller.dart';
import '../runtime_visualization/widgets/runtime_visualization_container.dart';

class ExperimentPlayerScreen extends StatefulWidget {
  final ExperimentManifest manifest;

  const ExperimentPlayerScreen({super.key, required this.manifest});

  @override
  State<ExperimentPlayerScreen> createState() => _ExperimentPlayerScreenState();
}

class _ExperimentPlayerScreenState extends State<ExperimentPlayerScreen> {
  final ExperimentPlayerController _controller = ExperimentPlayerController();
  final RuntimeVisualizationController _visualizationController = RuntimeVisualizationController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
    _visualizationController.attachStream(_controller.eventStream);
    _initOrchestrator();
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

          _buildControls(),

          const Divider(),
          
          Expanded(
            child: RuntimeVisualizationContainer(controller: _visualizationController),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final state = _controller.state;
    final isRunning = state == ExperimentExecutionState.running;
    final isPaused = state == ExperimentExecutionState.paused;
    final isIdleOrReady = state == ExperimentExecutionState.planning || 
                          state == ExperimentExecutionState.analyzing ||
                          state == ExperimentExecutionState.idle ||
                          state == ExperimentExecutionState.preparing ||
                          state == ExperimentExecutionState.starting;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isIdleOrReady)
            ElevatedButton.icon(
              onPressed: () => _controller.start(),
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
              onPressed: () => _controller.stop(),
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
