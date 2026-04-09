import 'package:flutter/material.dart';
import '../../application/rag_ingestion_service.dart';
import '../../data/local/rag_repository_v2.dart';

/// Screen for ingesting RAG seed data and managing documents
class RagIngestionScreen extends StatefulWidget {
  const RagIngestionScreen({super.key});

  @override
  State<RagIngestionScreen> createState() => _RagIngestionScreenState();
}

class _RagIngestionScreenState extends State<RagIngestionScreen> {
  final _ingestionService = RagIngestionService();
  final _repository = RagRepositoryV2();

  IngestionResult? _lastResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIngestionStatus();
  }

  Future<void> _loadIngestionStatus() async {
    setState(() => _isLoading = true);
    try {
      final chunkCount = await _repository.getTotalChunkCount();
      if (chunkCount > 0 && mounted) {
        setState(() {
          _lastResult = IngestionResult(
            success: true,
            message: 'Already ingested',
            chunksIngested: chunkCount,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading ingestion status: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ingestSeedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await _ingestionService.ingestSeedData('assets/seed_data_math_science.json');

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isLoading = false;
          if (!result.success) {
            _errorMessage = result.message;
          }
        });

        if (result.success) {
          _showSuccessSnackbar(
            'Ingestion complete: ${result.chunksIngested} chunks loaded',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ingestion failed: $e';
        });
      }
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAG Data Ingestion'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadIngestionStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status card
                _buildStatusCard(),
                const SizedBox(height: 20),

                // Ingestion actions
                _buildActionsSection(),
                const SizedBox(height: 20),

                // Results display
                if (_lastResult != null) _buildResultsCard(),
                if (_errorMessage != null) _buildErrorCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _lastResult;
    final hasData = status != null && status.chunksIngested > 0;

    return Card(
      elevation: 2,
      color: hasData ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasData ? Icons.check_circle : Icons.info,
                  color: hasData ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData ? 'Data Ingested' : 'No Data Ingested',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasData ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                    ),
                    if (hasData)
                      Text(
                        '${status.chunksIngested} chunks available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                  ],
                ),
              ],
            ),
            if (hasData) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 12),
              _buildStatRow('Courses', status.coursesIngested.toString()),
              const SizedBox(height: 8),
              _buildStatRow('Subjects', status.subjectsIngested.toString()),
              const SizedBox(height: 8),
              _buildStatRow('Chapters', status.chaptersIngested.toString()),
              const SizedBox(height: 8),
              _buildStatRow('Chunks', status.chunksIngested.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Ingestion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildIngestButton(),
            const SizedBox(height: 12),
            Text(
              'Load pre-built Math & Physics curriculum with formulas, definitions, and examples.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngestButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _ingestSeedData,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade700,
                ),
              ),
            )
          : const Icon(Icons.upload),
      label: Text(
        _isLoading ? 'Ingesting...' : 'Load Seed Data',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final result = _lastResult!;
    return Card(
      elevation: 2,
      color: result.success ? Colors.blue.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.blue : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (result.success) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildResultStat(
                      'Courses',
                      result.coursesIngested,
                      Icons.school,
                    ),
                    const SizedBox(height: 8),
                    _buildResultStat(
                      'Subjects',
                      result.subjectsIngested,
                      Icons.category,
                    ),
                    const SizedBox(height: 8),
                    _buildResultStat(
                      'Chapters',
                      result.chaptersIngested,
                      Icons.menu_book,
                    ),
                    const SizedBox(height: 8),
                    _buildResultStat(
                      'Chunks',
                      result.chunksIngested,
                      Icons.widgets,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
