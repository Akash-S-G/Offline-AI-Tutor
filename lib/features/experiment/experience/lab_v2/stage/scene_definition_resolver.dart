import '../../../runtime/runtime_world.dart';
import 'scene_definition.dart';

class SceneDefinitionResolver {
  const SceneDefinitionResolver();

  SceneDefinition resolve(RuntimeWorld world) {
    final profileId = world.visualizationState?.activeProfile.presetId;
    switch (profileId) {
      case 'waterCycle':
        return const SceneDefinition(
          id: 'waterCycle',
          background: 'sky',
          primaryObject: 'Water Cycle',
          primaryVariable: 'Temperature',
          primaryOutcome: 'Evaporation',
          backgroundLayers: ['Sky Layer', 'Cloud Layer', 'Water Layer'],
          assetIds: ['water_sun', 'water_cloud', 'water_rain', 'water_body'],
          anchors: [
            SceneAnchor(id: 'sun', x: 0.80, y: 0.18, label: 'Sun'),
            SceneAnchor(id: 'cloud', x: 0.42, y: 0.20, label: 'Cloud'),
            SceneAnchor(id: 'rain', x: 0.46, y: 0.42, label: 'Rain'),
            SceneAnchor(id: 'water', x: 0.50, y: 0.78, label: 'Water Body'),
            SceneAnchor(
              id: 'data_overlay',
              x: 0.72,
              y: 0.70,
              label: 'Data Overlay',
            ),
          ],
          zones: [
            SceneZone(
              id: 'rain_zone',
              x: 0.28,
              y: 0.28,
              width: 0.34,
              height: 0.34,
              label: 'Rain Zone',
            ),
          ],
          overlays: ['evaporation', 'rainfall'],
        );
      case 'freeFall':
        return const SceneDefinition(
          id: 'freeFall',
          background: 'physics',
          primaryObject: 'Falling Object',
          primaryVariable: 'Height',
          primaryOutcome: 'Speed',
          backgroundLayers: ['Physics Lab', 'Height Scale', 'Ground Zone'],
          assetIds: [
            'free_fall_ball',
            'free_fall_ground',
            'free_fall_height_scale',
          ],
          anchors: [
            SceneAnchor(
              id: 'height_scale',
              x: 0.20,
              y: 0.45,
              label: 'Height Scale',
            ),
            SceneAnchor(id: 'drop_zone', x: 0.54, y: 0.34, label: 'Drop Zone'),
            SceneAnchor(id: 'ground', x: 0.55, y: 0.84, label: 'Ground'),
            SceneAnchor(
              id: 'measurement',
              x: 0.76,
              y: 0.48,
              label: 'Measurement Zone',
            ),
          ],
          zones: [
            SceneZone(
              id: 'fall_path',
              x: 0.42,
              y: 0.12,
              width: 0.22,
              height: 0.68,
              label: 'Fall Path',
            ),
          ],
        );
      case 'pendulum':
        return const SceneDefinition(
          id: 'pendulum',
          background: 'physics',
          primaryObject: 'Pendulum',
          primaryVariable: 'Length',
          primaryOutcome: 'Period',
          backgroundLayers: ['Lab Frame', 'Swing Arc', 'Trail Zone'],
          assetIds: ['pendulum_support', 'pendulum_pendulum'],
          anchors: [
            SceneAnchor(
              id: 'support',
              x: 0.50,
              y: 0.18,
              label: 'Support Point',
            ),
            SceneAnchor(
              id: 'measurement',
              x: 0.77,
              y: 0.55,
              label: 'Measurement Zone',
            ),
          ],
          zones: [
            SceneZone(
              id: 'swing_zone',
              x: 0.28,
              y: 0.22,
              width: 0.44,
              height: 0.56,
              label: 'Swing Zone',
            ),
          ],
          overlays: ['motion_trail'],
        );
      case 'plantGrowth':
        return const SceneDefinition(
          id: 'plantGrowth',
          background: 'nature',
          primaryObject: 'Plant',
          primaryVariable: 'Water',
          primaryOutcome: 'Growth',
          backgroundLayers: ['Nature', 'Soil', 'Leaves'],
          assetIds: ['plant_growth_plant', 'plant_growth_soil', 'plant_growth_sun'],
          anchors: [
            SceneAnchor(id: 'sun', x: 0.80, y: 0.18, label: 'Sun'),
            SceneAnchor(id: 'plant', x: 0.50, y: 0.55, label: 'Plant'),
            SceneAnchor(id: 'roots', x: 0.50, y: 0.72, label: 'Roots'),
            SceneAnchor(id: 'soil', x: 0.50, y: 0.82, label: 'Soil'),
            SceneAnchor(
              id: 'water_zone',
              x: 0.22,
              y: 0.66,
              label: 'Water Zone',
            ),
          ],
        );
      case 'heartRate':
        return const SceneDefinition(
          id: 'heartRate',
          background: 'medical',
          primaryObject: 'Heart',
          primaryVariable: 'BPM',
          primaryOutcome: 'Pulse',
          backgroundLayers: ['Medical Monitor', 'Pulse Ring', 'ECG Zone'],
          assetIds: ['heart_rate_heart', 'heart_rate_ecg'],
          anchors: [
            SceneAnchor(id: 'heart', x: 0.36, y: 0.48, label: 'Heart'),
            SceneAnchor(
              id: 'pulse_ring',
              x: 0.36,
              y: 0.48,
              label: 'Pulse Ring',
            ),
            SceneAnchor(id: 'ecg', x: 0.70, y: 0.48, label: 'ECG Zone'),
            SceneAnchor(id: 'vitals', x: 0.78, y: 0.70, label: 'Vitals Zone'),
          ],
          zones: [
            SceneZone(
              id: 'monitor_zone',
              x: 0.56,
              y: 0.28,
              width: 0.34,
              height: 0.38,
              label: 'ECG Zone',
            ),
          ],
        );
      default:
        return const SceneDefinition(
          id: 'generic',
          background: 'laboratory',
          primaryObject: 'Experiment',
          primaryVariable: 'Reading',
          primaryOutcome: 'Finding',
          backgroundLayers: ['Laboratory'],
          anchors: [
            SceneAnchor(
              id: 'experiment',
              x: 0.50,
              y: 0.50,
              label: 'Experiment',
            ),
          ],
        );
    }
  }
}
