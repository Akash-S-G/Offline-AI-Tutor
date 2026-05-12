class RuntimeHealthMonitor {
  int checks = 0;
  bool healthy = true;

  void recordCheck({required bool ok}) {
    checks++;
    healthy = healthy && ok;
  }
}
