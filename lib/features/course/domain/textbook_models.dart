class TextbookBlock {
  final String type;
  final String content;
  final Map<String, dynamic> metadata;

  const TextbookBlock({
    required this.type,
    required this.content,
    this.metadata = const {},
  });

  factory TextbookBlock.fromJson(Map<String, dynamic> json) {
    return TextbookBlock(
      type: json['type'] as String? ?? 'paragraph',
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class TextbookSection {
  final String id;
  final String title;
  final List<TextbookBlock> blocks;

  const TextbookSection({
    required this.id,
    required this.title,
    required this.blocks,
  });

  factory TextbookSection.fromJson(Map<String, dynamic> json) {
    return TextbookSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => TextbookBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TextbookChapter {
  final String id;
  final String title;
  final List<TextbookSection> sections;

  const TextbookChapter({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory TextbookChapter.fromJson(Map<String, dynamic> json) {
    return TextbookChapter(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => TextbookSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
