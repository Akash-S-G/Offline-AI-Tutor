import 'package:flutter/material.dart';

class MeasurementDashboard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> measurements;

  const MeasurementDashboard({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No measurements available yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Live Measurements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: measurements.keys.length,
            itemBuilder: (context, index) {
              final sensorType = measurements.keys.elementAt(index);
              final data = measurements[sensorType]!;
              return _buildSensorCard(context, sensorType, data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(BuildContext context, String sensorType, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 12.0),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sensorType.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: data.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.key}:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatValue(e.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}
