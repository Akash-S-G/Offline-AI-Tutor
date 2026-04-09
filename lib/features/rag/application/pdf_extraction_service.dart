import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting text content from PDF files
class PdfExtractionService {
  /// Extract all text from a PDF file using in-app parser.
  static Future<String> extractTextFromPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw PdfExtractionException('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      return _extractTextFromBytes(bytes, filePath);
    } catch (e) {
      throw PdfExtractionException(
        'Failed to extract text from PDF: $e',
      );
    }
  }

  /// Extract text from multiple PDF files
  static Future<Map<String, String>> extractTextFromMultiplePdfs(
    List<String> filePaths,
  ) async {
    final results = <String, String>{};

    for (final filePath in filePaths) {
      try {
        final text = await extractTextFromPdf(filePath);
        results[filePath] = text;
      } catch (e) {
        print('Failed to extract $filePath: $e');
        results[filePath] = '';
      }
    }

    return results;
  }

  /// Get metadata about a PDF file (page count, language, size)
  static Future<PdfMetadata> getPdfMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw PdfExtractionException('File not found: $filePath');
      }

      final fileStats = await file.stat();
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final extractor = PdfTextExtractor(document);
      final firstPageText = pageCount > 0
          ? extractor.extractText(startPageIndex: 0, endPageIndex: 0)
          : '';
      final detectedLanguage = _detectLanguageFromText(firstPageText);
      document.dispose();

      return PdfMetadata(
        filePath: filePath,
        pageCount: pageCount,
        hasPages: pageCount > 0,
        detectedLanguage: detectedLanguage,
        fileSizeBytes: fileStats.size,
      );
    } catch (e) {
      throw PdfExtractionException(
        'Failed to extract PDF metadata: $e',
      );
    }
  }

  /// Detect language from text sample (Kannada vs English)
  static String _detectLanguageFromText(String text) {
    if (text.isEmpty) return 'en';

    // Kannada Unicode range: U+0C80 to U+0CF3
    final kannadaPattern = RegExp(r'[\u0C80-\u0CF3]{10,}');

    // Count Kannada characters in first 500 chars
    final sample = text.substring(0, (500).clamp(0, text.length));
    final kannadaMatches = kannadaPattern.allMatches(sample);

    // If more than 20% Kannada characters, likely Kannada
    if (kannadaMatches.isNotEmpty) {
      final kannadaChars = sample
          .split('')
          .where((c) => RegExp(r'[\u0C80-\u0CF3]').hasMatch(c))
          .length;

      if (kannadaChars / sample.length > 0.15) {
        return 'kn';
      }
    }

    return 'en';
  }

  static String _extractTextFromBytes(Uint8List bytes, String filePath) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      if (pageCount <= 0) {
        document.dispose();
        throw PdfExtractionException('PDF has no pages: $filePath');
      }

      final extractor = PdfTextExtractor(document);
      final extracted = extractor.extractText(
        startPageIndex: 0,
        endPageIndex: pageCount - 1,
      );
      document.dispose();

      final normalized = extracted
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .trim();

      if (normalized.isEmpty) {
        throw PdfExtractionException('No extractable text found in PDF: $filePath');
      }

      return normalized;
    } catch (e) {
      throw PdfExtractionException('In-app PDF parser failed: $e');
    }
  }
}

/// Metadata extracted from PDF
class PdfMetadata {
  final String filePath;
  final int pageCount;
  final bool hasPages;
  final String detectedLanguage; // 'en' or 'kn'
  final int? fileSizeBytes;

  PdfMetadata({
    required this.filePath,
    required this.pageCount,
    required this.hasPages,
    required this.detectedLanguage,
    this.fileSizeBytes,
  });

  @override
  String toString() =>
      'PdfMetadata(pages: $pageCount, language: $detectedLanguage, size: ${fileSizeBytes}B)';
}

/// Exception during PDF extraction
class PdfExtractionException implements Exception {
  final String message;

  PdfExtractionException(this.message);

  @override
  String toString() => 'PdfExtractionException: $message';
}
