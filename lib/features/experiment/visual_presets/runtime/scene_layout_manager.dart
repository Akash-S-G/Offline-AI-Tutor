class SceneLayout {
  final double simulationFlex;
  final double controlsFlex;
  final double graphsFlex;
  final double observationsFlex;

  const SceneLayout({
    this.simulationFlex = 0.62,
    this.controlsFlex = 0.18,
    this.graphsFlex = 0.1,
    this.observationsFlex = 0.1,
  });
}

class SceneLayoutManager {
  const SceneLayoutManager();

  SceneLayout build({
    required bool hasControls,
    required bool hasGraphs,
    required bool hasObservations,
  }) {
    final controls = hasControls ? 0.18 : 0.08;
    final graphs = hasGraphs ? 0.12 : 0.05;
    final observations = hasObservations ? 0.12 : 0.05;
    final simulation = (1 - controls - graphs - observations).clamp(0.55, 0.8);
    return SceneLayout(
      simulationFlex: simulation.toDouble(),
      controlsFlex: controls,
      graphsFlex: graphs,
      observationsFlex: observations,
    );
  }
}
