import 'package:flutter/material.dart';
import '../../network/application/retrieval_diagnostics_tracker.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

class RetrievalDiagnosticsScreen extends StatelessWidget {
  const RetrievalDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Retrieval Diagnostics', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: RetrievalDiagnosticsTracker.instance,
        builder: (context, _) {
          final t = RetrievalDiagnosticsTracker.instance;
          return ListView(
            padding: const EdgeInsets.all(IDPSpacing.md),
            children: [
              _buildSection('Inference & Intent', {
                'Normalized Topic': t.normalizedTopic,
                'Detected Intent': t.detectedIntent,
                'Execution Mode': t.executionMode,
              }),
              const SizedBox(height: IDPSpacing.md),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IDPSectionHeader(title: title),
        const SizedBox(height: IDPSpacing.xs),
        IDPCard(
          child: Column(
            children: data.entries.map((e) => _buildRow(e.key, e.value)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    final isPositive = value.contains('RAG') || (value.isNotEmpty && value != '0' && value != 'None' && !value.toLowerCase().contains('fallback'));
    final isNegative = value.isEmpty || value == '0' || value.toLowerCase().contains('fallback');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IDPSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: IDPTypography.bodyMedium.copyWith(color: IDPColors.textSecondary)),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.right,
              style: IDPTypography.bodyMedium.copyWith(
                color: isPositive
                    ? IDPColors.success
                    : isNegative
                        ? IDPColors.error
                        : IDPColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

