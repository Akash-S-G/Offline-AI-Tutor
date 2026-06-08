class BuilderDraft {
  final String draftId;
  final String title;
  final DateTime updatedAt;
  final Map<String, dynamic> manifest;

  BuilderDraft({
    required this.draftId,
    required this.title,
    required this.updatedAt,
    required this.manifest,
  });

  Map<String, dynamic> toJson() {
    return {
      'draft_id': draftId,
      'title': title,
      'updated_at': updatedAt.toIso8601String(),
      'manifest': manifest,
    };
  }

  factory BuilderDraft.fromJson(Map<String, dynamic> json) {
    return BuilderDraft(
      draftId: json['draft_id'] ?? '',
      title: json['title'] ?? 'Untitled',
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      manifest: json['manifest'] as Map<String, dynamic>? ?? {},
    );
  }
}
