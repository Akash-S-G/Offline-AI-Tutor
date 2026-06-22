import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/simulation_context_provider.dart';

/// Card displayed above chat showing current experiment context.
/// Live-updating via the SimulationContextProvider.
class ContextCard extends ConsumerWidget {
  const ContextCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(simulationContextProvider);

    if (!ctx.hasContext) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_rounded,
            color: theme.colorScheme.secondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctx.experimentName ?? ctx.experimentId ?? 'Experiment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ctx.currentState.isNotEmpty)
                  Text(
                    'State: ${ctx.currentState}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                if (ctx.variables.isNotEmpty)
                  Text(
                    ctx.variables.entries
                        .take(3) // Show max 3 variables
                        .map((e) => '${e.key}: ${e.value}')
                        .join('  •  '),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
