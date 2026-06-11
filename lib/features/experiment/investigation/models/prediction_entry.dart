class PredictionEntry {
  final String id;
  final String prompt;
  final String prediction;
  final String? actualResult;
  final DateTime timestamp;

  const PredictionEntry({
    required this.id,
    required this.prompt,
    required this.prediction,
    this.actualResult,
    required this.timestamp,
  });

  PredictionEntry withActualResult(String result) {
    return PredictionEntry(
      id: id,
      prompt: prompt,
      prediction: prediction,
      actualResult: result,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'prediction': prediction,
      'actualResult': actualResult,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
