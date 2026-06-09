import 'runtime_observation.dart';
import 'runtime_observation_store.dart';

class TableState {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final int rowCount;
  final Map<String, dynamic>? latestObservation;

  const TableState({
    required this.columns,
    required this.rows,
    required this.rowCount,
    required this.latestObservation,
  });

  const TableState.empty()
    : columns = const [],
      rows = const [],
      rowCount = 0,
      latestObservation = null;

  Map<String, dynamic> toObjectState() {
    return {
      'columns': columns,
      'rows': rows,
      'rowCount': rowCount,
      'latestObservation': latestObservation,
    };
  }
}

class TableBehavior {
  static const int visibleRowLimit = 20;

  final RuntimeObservationStore observationStore;

  const TableBehavior({required this.observationStore});

  TableState buildState() {
    final observations = observationStore.getObservations();
    if (observations.isEmpty) return const TableState.empty();
    final columns = _buildColumns(observations);
    final visibleRows = observations
        .skip(
          observations.length > visibleRowLimit
              ? observations.length - visibleRowLimit
              : 0,
        )
        .map((observation) => _rowFor(observation, columns))
        .toList(growable: false);
    final latest = observationStore.latestObservation();
    return TableState(
      columns: columns,
      rows: visibleRows,
      rowCount: observations.length,
      latestObservation: latest == null ? null : _rowFor(latest, columns),
    );
  }

  List<String> _buildColumns(List<RuntimeObservation> observations) {
    final columns = <String>['Time'];
    for (final observation in observations) {
      for (final key in observation.values.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }
    return columns;
  }

  Map<String, dynamic> _rowFor(
    RuntimeObservation observation,
    List<String> columns,
  ) {
    final row = <String, dynamic>{'Time': observation.runtimeSeconds};
    for (final column in columns.skip(1)) {
      row[column] = observation.values[column];
    }
    return row;
  }
}
