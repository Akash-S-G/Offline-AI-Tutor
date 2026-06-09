import '../objects/schema/runtime_object_schema.dart';

class TableObjectSchema {
  static const RuntimeObjectSchema schema = RuntimeObjectSchema(
    objectType: 'table',
    defaultState: {
      'columns': [],
      'rows': [],
      'rowCount': 0,
      'latestObservation': null,
    },
    requiredFields: [],
    optionalFields: ['columns', 'rows', 'rowCount', 'latestObservation'],
  );
}
