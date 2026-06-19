class VisualCauseEffectEvent {
  final String sourceId;
  final String targetId;
  final String changedValueLabel;
  final String visualResponse;
  final DateTime timestamp;

  VisualCauseEffectEvent({
    required this.sourceId,
    required this.targetId,
    required this.changedValueLabel,
    required this.visualResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isActionable {
    return sourceId.isNotEmpty &&
        targetId.isNotEmpty &&
        changedValueLabel.isNotEmpty &&
        visualResponse.isNotEmpty;
  }
}
