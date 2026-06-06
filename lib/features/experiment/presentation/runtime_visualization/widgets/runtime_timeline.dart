import 'package:flutter/material.dart';
import '../../../runtime/runtime_event.dart';

class RuntimeTimeline extends StatelessWidget {
  final List<RuntimeEvent> timeline;

  const RuntimeTimeline({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Timeline Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            final event = timeline[index];
            return _buildEventTile(event);
          },
        ),
      ],
    );
  }

  Widget _buildEventTile(RuntimeEvent event) {
    IconData iconData;
    Color iconColor;

    switch (event.type) {
      case RuntimeEventType.sessionStarted:
      case RuntimeEventType.sessionResumed:
        iconData = Icons.play_circle;
        iconColor = Colors.green;
        break;
      case RuntimeEventType.sessionPaused:
        iconData = Icons.pause_circle;
        iconColor = Colors.orange;
        break;
      case RuntimeEventType.sessionCompleted:
      case RuntimeEventType.sessionStopped:
        iconData = Icons.stop_circle;
        iconColor = Colors.grey;
        break;
      case RuntimeEventType.measurementReceived:
        iconData = Icons.sensors;
        iconColor = Colors.blue;
        break;
      case RuntimeEventType.custom:
        if (event.message.contains('Playground event')) {
          final pType = event.metadata?['playgroundEventType'];
          if (pType == 'variableChanged') {
            iconData = Icons.functions;
            iconColor = Colors.orange;
          } else if (pType == 'objectUpdated' || pType == 'objectCreated') {
            iconData = Icons.category;
            iconColor = Colors.purple;
          } else if (pType == 'ruleExecuted') {
            iconData = Icons.rule;
            iconColor = Colors.teal;
          } else {
            iconData = Icons.memory;
            iconColor = Colors.indigo;
          }
        } else {
          iconData = Icons.info;
          iconColor = Colors.blueGrey;
        }
        break;
      case RuntimeEventType.warning:
        iconData = Icons.warning;
        iconColor = Colors.amber;
        break;
      case RuntimeEventType.error:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
    }

    final timeStr = "${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}";

    return ListTile(
      dense: true,
      leading: Icon(iconData, color: iconColor, size: 20),
      title: Text(event.type.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(event.message, style: const TextStyle(fontSize: 12)),
      trailing: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }
}
