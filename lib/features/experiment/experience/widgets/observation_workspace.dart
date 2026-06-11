import 'package:flutter/material.dart';

import '../../runtime/observations/runtime_observation_store.dart';

class ObservationWorkspace extends StatelessWidget {
  final RuntimeObservationStore store;
  final VoidCallback onRecordObservation;

  const ObservationWorkspace({
    super.key,
    required this.store,
    required this.onRecordObservation,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Observations: ${store.rowCount}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: onRecordObservation,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
