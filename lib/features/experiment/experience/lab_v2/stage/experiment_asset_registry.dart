class ExperimentSceneAsset {
  final String id;
  final String path;
  final String label;

  const ExperimentSceneAsset({
    required this.id,
    required this.path,
    required this.label,
  });
}

class ExperimentAssetRegistry {
  const ExperimentAssetRegistry();

  static const Map<String, ExperimentSceneAsset> _assets = {
    'water_sun': ExperimentSceneAsset(
      id: 'water_sun',
      path: 'assets/experiment_scenes/water_cycle/sun.svg',
      label: 'Sun',
    ),
    'water_cloud': ExperimentSceneAsset(
      id: 'water_cloud',
      path: 'assets/experiment_scenes/water_cycle/cloud.svg',
      label: 'Cloud',
    ),
    'water_rain': ExperimentSceneAsset(
      id: 'water_rain',
      path: 'assets/experiment_scenes/water_cycle/rain.svg',
      label: 'Rain',
    ),
    'water_body': ExperimentSceneAsset(
      id: 'water_body',
      path: 'assets/experiment_scenes/water_cycle/water.svg',
      label: 'Water Body',
    ),
    'free_fall_ball': ExperimentSceneAsset(
      id: 'free_fall_ball',
      path: 'assets/experiment_scenes/free_fall/ball.svg',
      label: 'Falling Object',
    ),
    'free_fall_ground': ExperimentSceneAsset(
      id: 'free_fall_ground',
      path: 'assets/experiment_scenes/free_fall/ground.svg',
      label: 'Ground',
    ),
    'free_fall_height_scale': ExperimentSceneAsset(
      id: 'free_fall_height_scale',
      path: 'assets/experiment_scenes/free_fall/height_scale.svg',
      label: 'Height Scale',
    ),
    'pendulum_support': ExperimentSceneAsset(
      id: 'pendulum_support',
      path: 'assets/experiment_scenes/pendulum/support.svg',
      label: 'Support',
    ),
    'pendulum_pendulum': ExperimentSceneAsset(
      id: 'pendulum_pendulum',
      path: 'assets/experiment_scenes/pendulum/pendulum.svg',
      label: 'Pendulum',
    ),
    'heart_rate_heart': ExperimentSceneAsset(
      id: 'heart_rate_heart',
      path: 'assets/experiment_scenes/heart_rate/heart.svg',
      label: 'Heart',
    ),
    'heart_rate_ecg': ExperimentSceneAsset(
      id: 'heart_rate_ecg',
      path: 'assets/experiment_scenes/heart_rate/ecg.svg',
      label: 'ECG',
    ),
    'plant_growth_plant': ExperimentSceneAsset(
      id: 'plant_growth_plant',
      path: 'assets/experiment_scenes/plant_growth/plant.svg',
      label: 'Plant',
    ),
    'plant_growth_soil': ExperimentSceneAsset(
      id: 'plant_growth_soil',
      path: 'assets/experiment_scenes/plant_growth/soil.svg',
      label: 'Soil',
    ),
    'plant_growth_sun': ExperimentSceneAsset(
      id: 'plant_growth_sun',
      path: 'assets/experiment_scenes/plant_growth/sun.svg',
      label: 'Sun',
    ),
  };

  ExperimentSceneAsset? byId(String id) => _assets[id];

  List<ExperimentSceneAsset> assetsFor(Iterable<String> ids) {
    return [
      for (final id in ids)
        if (_assets[id] != null) _assets[id]!,
    ];
  }
}
