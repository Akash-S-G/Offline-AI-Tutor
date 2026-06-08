import 'package:flutter/material.dart';

class ErrorStateCard extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorStateCard({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 16),
              Expanded(child: Text('An error occurred', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: Colors.red.shade700)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.red.shade900, backgroundColor: Colors.red.shade100),
            )
          ]
        ],
      ),
    );
  }
}
