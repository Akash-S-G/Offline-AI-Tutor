abstract class ExperimentRuntime {
  Future<void> initialize();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> exportResults();
}
