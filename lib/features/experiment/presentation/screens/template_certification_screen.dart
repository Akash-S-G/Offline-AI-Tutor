import 'package:flutter/material.dart';
import '../../builder/templates/experiment_templates.dart';
import '../../runtime/runtime_world.dart';
import '../../runtime/runtime_profiles.dart';

class TemplateCertificationScreen extends StatefulWidget {
  const TemplateCertificationScreen({super.key});

  @override
  State<TemplateCertificationScreen> createState() => _TemplateCertificationScreenState();
}

class _TemplateCertificationScreenState extends State<TemplateCertificationScreen> {
  final List<Map<String, dynamic>> _results = [];
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _runCertification();
  }

  Future<void> _runCertification() async {
    for (final template in ExperimentTemplates.allTemplates) {
      final name = template['scene']?['name'] ?? 'Unknown';
      try {
        final world = RuntimeWorld();
        
        final scene = template['scene'] as Map<String, dynamic>;
        final metadata = template['metadata'] as Map<String, dynamic>? ?? {};

        world.initialize(
          variablesJson: (scene['variables'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          objectsJson: (scene['objects'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          rulesJson: (scene['rules'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          runtimeProfile: RuntimeProfile.general,
          curriculumMetadata: metadata,
        );

        world.start();

        // Run 5 seconds of simulation
        for (int i = 0; i < 50; i++) {
          world.tick(0.1);
        }
        
        world.stop();
        world.dispose();

        setState(() {
          _results.add({
            'name': name,
            'status': 'PASS',
            'detail': 'Successfully ran 5s simulation',
            'error': false,
          });
        });
      } catch (e, stack) {
        setState(() {
          _results.add({
            'name': name,
            'status': 'FAIL',
            'detail': e.toString(),
            'error': true,
          });
        });
      }
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Certification Workspace'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blueGrey.shade50,
              child: Row(
                children: [
                  if (_isRunning) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    const Text('Running Certification...'),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text('Certification Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const Spacer(),
                  Text('${_results.length} / ${ExperimentTemplates.allTemplates.length} processed'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isError = result['error'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isError ? Icons.error : Icons.check_circle,
                        color: isError ? Colors.red : Colors.green,
                      ),
                      title: Text(result['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(result['detail']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isError ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result['status'],
                          style: TextStyle(
                            color: isError ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
