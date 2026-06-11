enum InvestigationTimelineType {
  prediction,
  trial,
  observation,
  comparison,
  conclusion,
}

class InvestigationTimelineEntry {
  final String id;
  final InvestigationTimelineType type;
  final String title;
  final String description;
  final DateTime timestamp;

  const InvestigationTimelineEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}
