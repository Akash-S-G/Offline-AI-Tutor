class BlueprintAnalytics {
  int blueprintsLoaded = 0;
  int blueprintsStarted = 0;
  int blueprintsCompleted = 0;
  int questionsAnswered = 0;
  int predictionsSubmitted = 0;
  int observationRowsRecorded = 0;
  double _completionTimeTotalSeconds = 0;

  double get averageCompletionTime {
    if (blueprintsCompleted == 0) return 0;
    return _completionTimeTotalSeconds / blueprintsCompleted;
  }

  void recordLoaded() => blueprintsLoaded++;
  void recordStarted() => blueprintsStarted++;
  void recordQuestionAnswered({bool prediction = false}) {
    questionsAnswered++;
    if (prediction) predictionsSubmitted++;
  }

  void recordObservationRow() => observationRowsRecorded++;

  void recordCompleted(Duration duration) {
    blueprintsCompleted++;
    _completionTimeTotalSeconds += duration.inMilliseconds / 1000;
  }

  Map<String, dynamic> toJson() {
    return {
      'blueprintsLoaded': blueprintsLoaded,
      'blueprintsStarted': blueprintsStarted,
      'blueprintsCompleted': blueprintsCompleted,
      'questionsAnswered': questionsAnswered,
      'predictionsSubmitted': predictionsSubmitted,
      'observationRowsRecorded': observationRowsRecorded,
      'averageCompletionTime': averageCompletionTime,
    };
  }
}
