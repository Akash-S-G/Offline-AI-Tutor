abstract class TutorInferenceGateway {
  Stream<String> streamResponse({
    required String prompt,
  });

  Stream<Map<String, dynamic>> metricsStream();

  Future<void> stopGeneration();
}
