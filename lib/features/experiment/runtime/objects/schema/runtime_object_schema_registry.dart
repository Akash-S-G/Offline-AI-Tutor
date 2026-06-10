import 'runtime_object_schema.dart';
import '../../observations/table_object_schema.dart';

class RuntimeObjectSchemaRegistry {
  final Map<String, RuntimeObjectSchema> _schemas = {};

  RuntimeObjectSchemaRegistry() {
    registerDefaults();
  }

  void registerSchema(RuntimeObjectSchema schema) {
    _schemas[schema.objectType] = schema;
  }

  RuntimeObjectSchema? getSchema(String objectType) => _schemas[objectType];

  bool containsSchema(String objectType) => _schemas.containsKey(objectType);

  List<RuntimeObjectSchema> allSchemas() =>
      List.unmodifiable(_schemas.values.toList(growable: false));

  void registerDefaults() {
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'numericDisplay',
        defaultState: {
          'value': 0,
          'unit': '',
          'precision': 1,
          'formattedValue': '0',
        },
        requiredFields: ['value'],
        optionalFields: ['unit', 'precision', 'formattedValue'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'textDisplay',
        defaultState: {'text': '', 'formattedText': ''},
        requiredFields: ['text'],
        optionalFields: ['formattedText'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'gauge',
        defaultState: {'value': 0, 'min': 0, 'max': 100, 'normalizedValue': 0},
        requiredFields: ['value'],
        optionalFields: ['min', 'max', 'normalizedValue'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'progressBar',
        defaultState: {'value': 0, 'min': 0, 'max': 100, 'progress': 0},
        requiredFields: ['value'],
        optionalFields: ['min', 'max', 'progress'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'lineGraph',
        defaultState: {'value': 0, 'sampleCount': 0, 'minY': 0, 'maxY': 0},
        requiredFields: [],
        optionalFields: ['value', 'sampleCount', 'minY', 'maxY'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'scatterPlot',
        defaultState: {
          'pointCount': 0,
          'minX': 0,
          'maxX': 0,
          'minY': 0,
          'maxY': 0,
        },
        requiredFields: [],
        optionalFields: ['pointCount', 'minX', 'maxX', 'minY', 'maxY'],
      ),
    );
    registerSchema(TableObjectSchema.schema);
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'vectorVisualizer',
        defaultState: {
          'x': 0,
          'y': 0,
          'z': 0,
          'magnitude': 0,
          'direction': 0,
          'unit': '',
        },
        requiredFields: [],
        optionalFields: ['x', 'y', 'z', 'magnitude', 'direction', 'unit'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'oscilloscope',
        defaultState: {
          'samples': [],
          'sampleRate': 60,
          'amplitudeScale': 1,
          'timeWindow': 0,
          'sampleCount': 0,
        },
        requiredFields: [],
        optionalFields: [
          'samples',
          'sampleRate',
          'amplitudeScale',
          'timeWindow',
          'sampleCount',
        ],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'spectrumAnalyzer',
        defaultState: {
          'bins': [],
          'amplitudes': [],
          'frequencies': [],
          'peakFrequency': 0,
          'binCount': 0,
        },
        requiredFields: [],
        optionalFields: [
          'bins',
          'amplitudes',
          'frequencies',
          'peakFrequency',
          'binCount',
        ],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'barChart',
        defaultState: {
          'labels': [],
          'values': [],
          'min': 0,
          'max': 0,
          'barCount': 0,
        },
        requiredFields: [],
        optionalFields: ['labels', 'values', 'min', 'max', 'barCount'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'button',
        defaultState: {
          'pressed': false,
          'pressCount': 0,
          'enabled': true,
          'label': 'START',
        },
        requiredFields: [],
        optionalFields: ['label', 'pressed', 'pressCount', 'enabled'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'slider',
        defaultState: {
          'value': 25,
          'min': 0,
          'max': 100,
          'step': 1,
          'enabled': true,
        },
        requiredFields: [],
        optionalFields: ['value', 'min', 'max', 'step', 'enabled'],
      ),
    );
    registerSchema(
      const RuntimeObjectSchema(
        objectType: 'toggle',
        defaultState: {
          'value': false,
          'enabled': true,
          'onLabel': 'ON',
          'offLabel': 'OFF',
        },
        requiredFields: [],
        optionalFields: ['value', 'enabled', 'onLabel', 'offLabel'],
      ),
    );
  }
}
