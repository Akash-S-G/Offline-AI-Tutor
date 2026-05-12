/// Interface for local inference engines.
abstract class LocalInferenceSource {
  /// Whether the local inference is ready
  bool get isReady;

  /// Stream a question and get response chunks
  Stream<String> streamQuestion(String question);

  /// Stop any active generation.
  Future<void> stopGeneration();

  /// Get model info
  Future<Map<String, String>> getModelInfo();

  /// Pre-cache model if needed
  Future<void> ensureModelLoaded();

  /// Clean up resources
  void dispose();
}
