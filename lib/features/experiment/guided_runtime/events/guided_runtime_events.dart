import '../../runtime/runtime_event.dart';

RuntimeEvent guidedRuntimeEvent(
  String message, {
  Map<String, dynamic>? metadata,
}) {
  return RuntimeEvent(
    id: '${message}_${DateTime.now().microsecondsSinceEpoch}',
    timestamp: DateTime.now(),
    type: RuntimeEventType.custom,
    message: message,
    metadata: metadata,
  );
}
