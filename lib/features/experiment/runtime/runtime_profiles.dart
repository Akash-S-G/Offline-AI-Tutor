enum RuntimeProfile {
  physics,
  biology,
  chemistry,
  mathematics,
  general,
}

class RuntimeProfileManager {
  static RuntimeProfile determineProfile(Map<String, dynamic> manifest) {
    final metadata = manifest['metadata'] as Map<String, dynamic>? ?? {};
    final category = (metadata['category']?.toString() ?? '').toLowerCase();

    switch (category) {
      case 'physics':
        return RuntimeProfile.physics;
      case 'biology':
        return RuntimeProfile.biology;
      case 'chemistry':
        return RuntimeProfile.chemistry;
      case 'mathematics':
      case 'math':
        return RuntimeProfile.mathematics;
      default:
        return RuntimeProfile.general;
    }
  }

  static bool requiresPhysicsEngine(RuntimeProfile profile) {
    return profile == RuntimeProfile.physics;
  }
}
