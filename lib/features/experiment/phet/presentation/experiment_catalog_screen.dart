import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/phet_catalog_service.dart';
import '../data/phet_pack_install_service.dart';
import '../models/experiment_descriptor.dart';
import 'experiment_player_screen.dart';

class ExperimentCatalogScreen extends ConsumerStatefulWidget {
  const ExperimentCatalogScreen({super.key});

  @override
  ConsumerState<ExperimentCatalogScreen> createState() =>
      _ExperimentCatalogScreenState();
}

class _ExperimentCatalogScreenState
    extends ConsumerState<ExperimentCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PhetPackInstallService _packInstaller = PhetPackInstallService();

  PhetCatalogSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isInstalling = false;
  String _installMessage = '';
  double? _installProgress;
  String _query = '';
  String? _error;

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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load PhET simulations: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _installPack() async {
    setState(() {
      _isInstalling = true;
      _installMessage = 'Preparing download...';
      _installProgress = null;
      _error = null;
    });
    try {
      await _packInstaller.install(
        onProgress: (message, progress) {
          if (!mounted) return;
          setState(() {
            _installMessage = message;
            _installProgress = progress;
          });
        },
      );
      await _loadCatalog();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'PhET pack installation failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInstalling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final experiments =
        snapshot?.experiments.where((experiment) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          return experiment.title.toLowerCase().contains(query) ||
              experiment.subject.toLowerCase().contains(query);
        }).toList() ??
        const <ExperimentDescriptor>[];

    final grouped = <String, List<ExperimentDescriptor>>{};
    for (final experiment in experiments) {
      grouped.putIfAbsent(experiment.subject, () => []).add(experiment);
    }
    final subjects = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Simulations'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadCatalog,
            tooltip: 'Refresh catalog',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCatalogHeader(context, snapshot),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFEE2E2),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search simulations',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: subjects.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            final items = grouped[subject]!;
                            return _SubjectSection(
                              subject: subject,
                              experiments: items,
                              onOpen: _openExperiment,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCatalogHeader(
    BuildContext context,
    PhetCatalogSnapshot? snapshot,
  ) {
    final installed = snapshot?.packInstalled ?? false;
    final count = snapshot?.experiments.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F7F5),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: Color(0xFF0B6E4F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count PhET simulations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (installed)
                const Chip(
                  avatar: Icon(Icons.offline_pin_rounded, size: 17),
                  label: Text('Available offline'),
                )
              else
                FilledButton.icon(
                  onPressed: _isInstalling ? null : _installPack,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Install Offline'),
                ),
            ],
          ),
          if ((snapshot?.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              snapshot!.message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_isInstalling) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _installProgress),
            const SizedBox(height: 5),
            Text(_installMessage, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('No simulations found.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadCatalog,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openExperiment(ExperimentDescriptor experiment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExperimentPlayerScreen(experiment: experiment),
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({
    required this.subject,
    required this.experiments,
    required this.onOpen,
  });

  final String subject;
  final List<ExperimentDescriptor> experiments;
  final ValueChanged<ExperimentDescriptor> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              subject,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final experiment in experiments)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(0xFF0B6E4F),
                ),
                title: Text(experiment.title),
                subtitle: Text(
                  experiment.isInstalled
                      ? 'PhET · Offline'
                      : experiment.usesBundledAsset
                      ? 'Preview only'
                      : 'PhET · Classroom',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpen(experiment),
              ),
            ),
        ],
      ),
    );
  }
}
