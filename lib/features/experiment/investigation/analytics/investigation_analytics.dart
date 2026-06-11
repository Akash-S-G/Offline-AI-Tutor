class InvestigationAnalytics {
  int trialsStarted = 0;
  int trialsCompleted = 0;
  int predictionsSubmitted = 0;
  int comparisonsGenerated = 0;
  int conclusionsGenerated = 0;
  int experimentsTracked = 1;

  double get averageTrialsPerExperiment {
    if (experimentsTracked <= 0) return 0;
    return trialsCompleted / experimentsTracked;
  }

  Map<String, dynamic> toJson() {
    return {
      'trialsStarted': trialsStarted,
      'trialsCompleted': trialsCompleted,
      'predictionsSubmitted': predictionsSubmitted,
      'comparisonsGenerated': comparisonsGenerated,
      'conclusionsGenerated': conclusionsGenerated,
      'averageTrialsPerExperiment': averageTrialsPerExperiment,
    };
  }
}
