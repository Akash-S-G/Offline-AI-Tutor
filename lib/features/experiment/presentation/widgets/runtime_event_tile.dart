import 'package:flutter/material.dart';
import '../../runtime/runtime_event.dart';

class RuntimeEventTile extends StatelessWidget {
  final RuntimeEvent event;

  const RuntimeEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (event.type) {
      case RuntimeEventType.measurementReceived:
        icon = Icons.timeline;
        iconColor = Colors.blue;
        break;
      case RuntimeEventType.warning:
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case RuntimeEventType.error:
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case RuntimeEventType.sessionStarted:
        icon = Icons.play_circle;
        iconColor = Colors.green;
        break;
      case RuntimeEventType.sessionCompleted:
        icon = Icons.check_circle;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    final timeString = '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        event.type.name.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        event.message,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(timeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }
}
