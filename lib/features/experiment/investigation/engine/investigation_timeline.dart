import '../models/investigation_timeline_entry.dart';

class InvestigationTimeline {
  final List<InvestigationTimelineEntry> _entries = [];

  List<InvestigationTimelineEntry> get entries => List.unmodifiable(_entries);

  void add({
    required InvestigationTimelineType type,
    required String title,
    required String description,
  }) {
    _entries.add(
      InvestigationTimelineEntry(
        id: '${type.name}_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
  }
}
