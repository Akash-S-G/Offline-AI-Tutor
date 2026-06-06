import 'package:flutter/material.dart';
import '../../network/application/retrieval_diagnostics_tracker.dart';

class RetrievalDiagnosticsScreen extends StatelessWidget {
  const RetrievalDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Retrieval Diagnostics'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: ListenableBuilder(
        listenable: RetrievalDiagnosticsTracker.instance,
        builder: (context, _) {
          final t = RetrievalDiagnosticsTracker.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('Inference & Intent', {
                'Normalized Topic': t.normalizedTopic,
                'Detected Intent': t.detectedIntent,
                'Execution Mode': t.executionMode,
              }),
              const SizedBox(height: 16),
              _buildSection('RAG State', {
                'Retrieval Mode': t.retrievalMode,
                'Chunks Found': t.chunksFound.toString(),
                'Fallback Reason': t.fallbackReason.isEmpty ? 'None' : t.fallbackReason,
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...data.entries.map((e) => _buildRow(e.key, e.value)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    final isPositive = value.contains('RAG') || value.isNotEmpty && value != '0' && value != 'None' && !value.toLowerCase().contains('fallback');
    final isNegative = value.isEmpty || value == '0' || value.toLowerCase().contains('fallback') || value == 'None' && label != 'Fallback Reason';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isPositive
                    ? Colors.greenAccent
                    : isNegative
                        ? Colors.redAccent
                        : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
