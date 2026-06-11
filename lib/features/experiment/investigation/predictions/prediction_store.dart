import '../analytics/investigation_analytics.dart';
import '../models/prediction_entry.dart';

class PredictionStore {
  final InvestigationAnalytics analytics;
  final List<PredictionEntry> _predictions = [];

  PredictionStore({required this.analytics});

  List<PredictionEntry> get predictions => List.unmodifiable(_predictions);
  bool get hasPrediction => _predictions.isNotEmpty;

  PredictionEntry submit({required String prompt, required String prediction}) {
    final entry = PredictionEntry(
      id: 'prediction_${DateTime.now().microsecondsSinceEpoch}',
      prompt: prompt,
      prediction: prediction,
      timestamp: DateTime.now(),
    );
    _predictions.add(entry);
    analytics.predictionsSubmitted++;
    return entry;
  }

  void attachActualResult(String predictionId, String actualResult) {
    final index = _predictions.indexWhere((entry) => entry.id == predictionId);
    if (index < 0) return;
    _predictions[index] = _predictions[index].withActualResult(actualResult);
  }
}
