import '../runtime_event_bus.dart';
import 'runtime_observation_events.dart';
import 'runtime_observation_store.dart';

class RuntimeObservationExporter {
  final RuntimeObservationStore store;
  final RuntimeEventBus eventBus;

  RuntimeObservationExporter({required this.store, required this.eventBus});

  List<Map<String, dynamic>> exportJson() {
    final rows = store.exportJson();
    eventBus.emit(observationExportedEvent(rowCount: rows.length));
    return rows;
  }
}
