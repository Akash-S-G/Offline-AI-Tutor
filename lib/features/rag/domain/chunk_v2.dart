import 'dart:convert';

/// Formula metadata extracted from chunk content
class Formula {
  Formula({
    required this.original,
    required this.type,
    this.latex,
    this.mathml,
    this.variables = const [],
    this.position = 0,
  });

  final String original; // "2x + 3 = 7"
  final String? latex; // "\frac{2x + 3}{1} = 7" (optional)
  final String? mathml; // "<math>...</math>" (optional)
  final String type; // 'equation' | 'expression' | 'inequality' | 'formula'
  final List<String> variables; // ['x', 'y']
  final int position; // byte offset in chunk content

  Map<String, dynamic> toJson() => {
        'original': original,
        'latex': latex,
        'mathml': mathml,
        'type': type,
        'variables': variables,
        'position': position,
      };

  static Formula fromJson(Map<String, dynamic> json) => Formula(
        original: json['original'] as String,
        latex: json['latex'] as String?,
        mathml: json['mathml'] as String?,
        type: json['type'] as String? ?? 'formula',
        variables: List<String>.from(json['variables'] as List? ?? []),
        position: json['position'] as int? ?? 0,
      );
}

/// Enhanced chunk with multilingual support and semantic typing
class ChunkV2 {
  ChunkV2({
    required this.id,
    required this.chapterId,
    required this.sourceTitle,
    required this.sourceLanguage,
    required this.content,
    required this.contentType,
    required this.chunkOrder,
    required this.createdAt,
    this.formulas = const [],
    this.originalMarkdown,
    this.tokenCount = 0,
    this.metadata = const {},
  });

  final String id;
  final String chapterId;
  final String sourceTitle;
  final String sourceLanguage; // 'en' | 'kn'
  final String content; // Plain text with <formula> tags
  final String contentType; // 'definition' | 'example' | 'proof' | 'concept' | 'exercise'
  final int chunkOrder;
  final DateTime createdAt;

  // NEW: Lossless preservation
  final List<Formula> formulas;
  final String? originalMarkdown; // Preserve original formatting if available
  final int tokenCount; // For retrieval efficiency
  final Map<String, dynamic> metadata; // {section, subsection, difficulty, prerequisites}

  String get formulasJson => jsonEncode(formulas.map((f) => f.toJson()).toList());

  String get metadataJson => jsonEncode(metadata);

  /// Get human-readable difficulty label
  String get difficulty {
    final diff = metadata['difficulty'] as String?;
    return diff ?? 'beginner';
  }

  /// Get chunk section path (for navigation)
  String get sectionPath {
    final section = metadata['section'] as String? ?? '';
    final subsection = metadata['subsection'] as String? ?? '';
    return subsection.isNotEmpty ? '$section > $subsection' : section;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter_id': chapterId,
        'source_title': sourceTitle,
        'source_language': sourceLanguage,
        'content': content,
        'content_type': contentType,
        'chunk_order': chunkOrder,
        'formulas_json': formulasJson,
        'original_markdown': originalMarkdown,
        'token_count': tokenCount,
        'metadata_json': metadataJson,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  static ChunkV2 fromJson(Map<String, dynamic> json) {
    List<Formula> formulas = [];
    try {
      final formulasJson = json['formulas_json'] as String?;
      if (formulasJson != null && formulasJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(formulasJson);
        formulas = decoded.map((f) => Formula.fromJson(f as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Silently skip malformed formula JSON
    }

    Map<String, dynamic> metadata = {};
    try {
      final metadataJson = json['metadata_json'] as String?;
      if (metadataJson != null && metadataJson.isNotEmpty) {
        metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      }
    } catch (_) {
      // Silently skip malformed metadata JSON
    }

    return ChunkV2(
      id: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      sourceTitle: json['source_title'] as String,
      sourceLanguage: json['source_language'] as String? ?? 'en',
      content: json['content'] as String,
      contentType: json['content_type'] as String? ?? 'concept',
      chunkOrder: json['chunk_order'] as int? ?? 0,
      formulas: formulas,
      originalMarkdown: json['original_markdown'] as String?,
      tokenCount: json['token_count'] as int? ?? 0,
      metadata: metadata,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int? ?? 0),
    );
  }
}
