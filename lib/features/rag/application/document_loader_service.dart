import 'dart:io';

/// Service for loading and parsing documents from filesystem
class DocumentLoaderService {
  /// Get list of all PDF files in a directory
  static Future<List<DocumentFile>> listPdfFiles(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        return [];
      }

      final files = <DocumentFile>[];

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final name = entity.path.split('/').last;
          final size = await entity.length();
          final stat = await entity.stat();

          files.add(
            DocumentFile(
              path: entity.path,
              name: name,
              sizeMB: (size / (1024 * 1024)).toStringAsFixed(2),
              modifiedAt: stat.modified,
              type: 'pdf',
            ),
          );
        }
      }

      // Sort by modification date descending (newest first)
      files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return files;
    } catch (e) {
      throw DocumentLoaderException('Failed to list PDF files: $e');
    }
  }

  /// Extract metadata from filename
  static DocumentMetadata parseFilename(String filename) {
    // Remove .pdf extension
    var name = filename.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');

    // Try to extract subject and part
    String? subject;
    String? part;
    String? grade;
    String? language;

    if (name.toLowerCase().contains('maths') || name.toLowerCase().contains('math')) {
      subject = 'Mathematics';
    } else if (name.toLowerCase().contains('science') ||
        name.toLowerCase().contains('sci')) {
      subject = 'Science';
    } else if (name.toLowerCase().contains('social') ||
        name.toLowerCase().contains('history') ||
        name.toLowerCase().contains('civics')) {
      subject = 'Social Science';
    }

    // Extract grade
    final gradeMatch = RegExp(r'(\d+)(?:st|nd|rd|th)?').firstMatch(name);
    if (gradeMatch != null) {
      grade = 'Grade ${gradeMatch.group(1)}';
    }

    // Extract part
    if (name.toLowerCase().contains('part 1') ||
        name.toLowerCase().contains('part-1')) {
      part = 'Part 1';
    } else if (name.toLowerCase().contains('part 2') ||
        name.toLowerCase().contains('part-2')) {
      part = 'Part 2';
    } else if (name.toLowerCase().contains('part 3') ||
        name.toLowerCase().contains('part-3')) {
      part = 'Part 3';
    }

    // Detect language (Kannada if contains 'kan')
    if (name.toLowerCase().contains('kan')) {
      language = 'kn';
    } else {
      language = 'en';
    }

    return DocumentMetadata(
      filename: filename,
      subject: subject ?? 'Unknown Subject',
      part: part,
      grade: grade,
      language: language,
      fullName: name,
    );
  }

  /// Check if file is readable
  static Future<bool> isFileReadable(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }
}

/// Metadata about a document file
class DocumentFile {
  final String path;
  final String name;
  final String sizeMB;
  final DateTime modifiedAt;
  final String type;

  DocumentFile({
    required this.path,
    required this.name,
    required this.sizeMB,
    required this.modifiedAt,
    required this.type,
  });

  @override
  String toString() => '''
DocumentFile(
  path: $path,
  name: $name,
  size: $sizeMB MB,
  modified: $modifiedAt
)''';
}

/// Extracted metadata from document filename/properties
class DocumentMetadata {
  final String filename;
  final String subject;
  final String? part;
  final String? grade;
  final String language; // 'en' or 'kn'
  final String fullName;

  DocumentMetadata({
    required this.filename,
    required this.subject,
    this.part,
    this.grade,
    required this.language,
    required this.fullName,
  });

  String get displayName {
    final parts = <String>[];
    if (grade != null) parts.add(grade!);
    parts.add(subject);
    if (part != null) parts.add(part!);
    return parts.join(' - ');
  }

  @override
  String toString() => 'DocumentMetadata($displayName, lang: $language)';
}

/// Exception during document loading
class DocumentLoaderException implements Exception {
  final String message;
  DocumentLoaderException(this.message);

  @override
  String toString() => 'DocumentLoaderException: $message';
}
