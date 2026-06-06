import 'package:flutter/material.dart';

class VariablePanel extends StatelessWidget {
  final Map<String, dynamic> variables;

  const VariablePanel({super.key, required this.variables});

  @override
  Widget build(BuildContext context) {
    if (variables.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.functions, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text('Variables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: variables.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.key, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const Text(' = ', style: TextStyle(color: Colors.grey)),
                      Text('${_formatValue(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(3);
    }
    return value.toString();
  }
}
