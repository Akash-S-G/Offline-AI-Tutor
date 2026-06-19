class VisualFocusRequest {
  final String targetId;
  final String targetCategory;
  final String reason;
  final double durationSeconds;

  const VisualFocusRequest({
    required this.targetId,
    required this.targetCategory,
    required this.reason,
    this.durationSeconds = 1.5,
  });

  bool get isValid {
    return targetId.isNotEmpty &&
        targetCategory.isNotEmpty &&
        reason.isNotEmpty &&
        durationSeconds > 0 &&
        durationSeconds <= 3;
  }
}
