// ignore_for_file: avoid_print

class RuntimeMetrics {
  DateTime? startTime;
  DateTime? endTime;
  Duration duration = Duration.zero;
  int eventCount = 0;
  int errorCount = 0;
  int warningCount = 0;
  int measurementCount = 0;

  void recordEvent() {
    eventCount++;
  }

  void recordWarning() {
    warningCount++;
  }

  void recordError() {
    errorCount++;
  }

  void recordMeasurement() {
    measurementCount++;
  }

  void complete() {
    endTime = DateTime.now();
    if (startTime != null) {
      duration = endTime!.difference(startTime!);
    }
    print('[EXPERIMENT] EVENT_COUNT=$eventCount');
    print('[EXPERIMENT] ERROR_COUNT=$errorCount');
    print('[EXPERIMENT] DURATION_MS=${duration.inMilliseconds}');
  }
}
