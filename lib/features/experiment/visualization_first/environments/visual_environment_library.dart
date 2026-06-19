import 'visual_environment_profile.dart';

class VisualEnvironmentLibrary {
  const VisualEnvironmentLibrary._();

  static const laboratory = VisualEnvironmentProfile(
    id: 'laboratory',
    name: 'Laboratory',
    description: 'Clean lab bench background for general investigations.',
    backgroundMode: 'canvas',
    ambientMotions: ['subtle_light_sweep'],
    palette: {'surface': '#f8fafc', 'accent': '#0f766e'},
  );

  static const nature = VisualEnvironmentProfile(
    id: 'nature',
    name: 'Nature',
    description: 'Soft outdoor backdrop for biology and environmental topics.',
    backgroundMode: 'canvas',
    ambientMotions: ['leaf_breathe', 'light_particles'],
    palette: {'surface': '#ecfdf5', 'accent': '#16a34a'},
  );

  static const space = VisualEnvironmentProfile(
    id: 'space',
    name: 'Space',
    description: 'Dark star-field style backdrop for orbital or wave motion.',
    backgroundMode: 'canvas',
    ambientMotions: ['slow_star_drift'],
    palette: {'surface': '#020617', 'accent': '#38bdf8'},
  );

  static const physicsRoom = VisualEnvironmentProfile(
    id: 'physics_room',
    name: 'Physics Room',
    description: 'Grid and apparatus backdrop for motion and force.',
    backgroundMode: 'canvas',
    ambientMotions: ['grid_parallax'],
    palette: {'surface': '#f1f5f9', 'accent': '#2563eb'},
  );

  static const chemistryBench = VisualEnvironmentProfile(
    id: 'chemistry_bench',
    name: 'Chemistry Bench',
    description: 'Bench backdrop with subtle heat and fluid hints.',
    backgroundMode: 'canvas',
    ambientMotions: ['heat_shimmer', 'bubble_drift'],
    palette: {'surface': '#fff7ed', 'accent': '#ea580c'},
  );

  static const all = {laboratory, nature, space, physicsRoom, chemistryBench};

  static VisualEnvironmentProfile byId(String id) {
    return all.firstWhere(
      (environment) => environment.id == id,
      orElse: () => laboratory,
    );
  }
}
