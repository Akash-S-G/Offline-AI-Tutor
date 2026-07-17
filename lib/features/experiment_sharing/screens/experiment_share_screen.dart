import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/experiment_sharing_controller.dart';
import '../../experiment/builder/storage/builder_draft_manager.dart';
import '../../experiment/phet/data/phet_catalog_service.dart';
import '../../experiment/phet/models/experiment_descriptor.dart';

class ExperimentShareScreen extends ConsumerStatefulWidget {
  final ExperimentSharingController sharingController;
  final BuilderDraftManager draftManager;

  const ExperimentShareScreen({
    super.key,
    required this.sharingController,
    required this.draftManager,
  });

  @override
  ConsumerState<ExperimentShareScreen> createState() => _ExperimentShareScreenState();
}

class _ExperimentShareScreenState extends ConsumerState<ExperimentShareScreen> {
  final TextEditingController _searchController = TextEditingController();
  PhetCatalogSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await ref.read(phetCatalogServiceProvider).loadCatalog();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load PhET simulations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareSimulation(ExperimentDescriptor sim) async {
    try {
      final isLocal = sim.launchSource == ExperimentLaunchSource.installedPack;
      if (isLocal && sim.launchLocation.isNotEmpty) {
        final file = File(sim.launchLocation);
        if (await file.exists()) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'PhET Simulation: ${sim.title}',
            subject: sim.title,
          );
          return;
        }
      }

      // Fallback: share link/text if the HTML is not local
      final shareText = sim.publicUrl != null && sim.publicUrl!.isNotEmpty
          ? 'Check out this PhET Simulation: ${sim.title}\n${sim.publicUrl}'
          : 'PhET Simulation: ${sim.title}';
      await Share.share(shareText, subject: sim.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share simulation: $e')),
        );
      }
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return Colors.blue.shade700;
      case 'chemistry':
        return Colors.purple.shade700;
      case 'biology':
        return Colors.green.shade700;
      case 'mathematics':
        return Colors.orange.shade700;
      default:
        return Colors.teal.shade700;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return Icons.bolt_rounded;
      case 'chemistry':
        return Icons.science_rounded;
      case 'biology':
        return Icons.yard_rounded;
      case 'mathematics':
        return Icons.calculate_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final simulations = _snapshot?.experiments.where((sim) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          return sim.title.toLowerCase().contains(query) ||
              sim.subject.toLowerCase().contains(query);
        }).toList() ??
        const <ExperimentDescriptor>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share PhET Simulations'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadCatalog,
            tooltip: 'Refresh list',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search simulations...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: simulations.isEmpty
                      ? Center(
                          child: Text(
                            'No simulations found.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: simulations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sim = simulations[index];
                            final isLocal = sim.launchSource == ExperimentLaunchSource.installedPack;
                            final subjectColor = _getSubjectColor(sim.subject);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: subjectColor.withAlpha(25),
                                      child: Icon(
                                        _getSubjectIcon(sim.subject),
                                        color: subjectColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sim.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: subjectColor.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sim.subject,
                                                  style: TextStyle(
                                                    color: subjectColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                isLocal
                                                    ? Icons.offline_pin_rounded
                                                    : Icons.cloud_queue_rounded,
                                                size: 16,
                                                color: isLocal ? Colors.green : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isLocal ? 'Offline ready' : 'Online',
                                                style: TextStyle(
                                                  color: isLocal ? Colors.green : Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () => _shareSimulation(sim),
                                      icon: const Icon(Icons.share_rounded),
                                      tooltip: 'Share Simulation',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
