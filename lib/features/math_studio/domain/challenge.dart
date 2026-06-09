class MathChallenge {
  final String id;
  final String description;
  final bool Function(Map<String, dynamic> state) verifier;

  MathChallenge({
    required this.id,
    required this.description,
    required this.verifier,
  });
}

class ChallengeEngine {
  static final List<MathChallenge> functionChallenges = [
    MathChallenge(
      id: 'func_downward_parabola',
      description: 'Create a parabola that opens downward.',
      verifier: (state) {
        // Expected state: {'a': value} where value < 0
        final a = state['a'] as double?;
        return a != null && a < 0;
      },
    ),
    MathChallenge(
      id: 'func_steep_line',
      description: 'Create a line with a slope greater than 5.',
      verifier: (state) {
        final m = state['m'] as double?;
        return m != null && m > 5;
      },
    ),
  ];

  static final List<MathChallenge> geometryChallenges = [
    MathChallenge(
      id: 'geom_area_50',
      description: 'Construct a shape with an area of roughly 50 (±2).',
      verifier: (state) {
        final area = state['area'] as double?;
        return area != null && area >= 48 && area <= 52;
      },
    ),
    MathChallenge(
      id: 'geom_perimeter_100',
      description: 'Construct a shape with a perimeter of roughly 100 (±5).',
      verifier: (state) {
        final perimeter = state['perimeter'] as double?;
        return perimeter != null && perimeter >= 95 && perimeter <= 105;
      },
    ),
  ];

  static final List<MathChallenge> statisticsChallenges = [
    MathChallenge(
      id: 'stat_mean_20',
      description: 'Create a dataset whose mean is exactly 20.',
      verifier: (state) {
        final mean = state['mean'] as double?;
        return mean != null && mean == 20.0;
      },
    ),
    MathChallenge(
      id: 'stat_mode_7',
      description: 'Create a dataset with a mode of 7.',
      verifier: (state) {
        final modes = state['modes'] as List<double>?;
        return modes != null && modes.contains(7.0);
      },
    ),
  ];
}
