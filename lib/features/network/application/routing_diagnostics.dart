class RoutingDiagnostics {
  const RoutingDiagnostics();

  String format(Map<String, dynamic> stats) {
    return stats.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
}
