import 'package:flutter/material.dart';

class ObjectStatePanel extends StatelessWidget {
  final Map<String, Map<String, dynamic>> objectStates;

  const ObjectStatePanel({super.key, required this.objectStates});

  @override
  Widget build(BuildContext context) {
    if (objectStates.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.purple),
                SizedBox(width: 8),
                Text('Playground Objects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...objectStates.entries.map((e) => _buildObjectRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectRow(String objectId, Map<String, dynamic> state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(objectId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: state.entries.map((prop) {
              return Text('${prop.key}: ${prop.value}', style: const TextStyle(fontSize: 12, color: Colors.grey));
            }).toList(),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
