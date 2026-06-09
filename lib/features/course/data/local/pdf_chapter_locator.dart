import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/curriculum_models.dart';

class ChapterPdfReference {
  final String pdfPath;
  final int startPage;
  final int? endPage; // Null means until the end of the document

  const ChapterPdfReference({
    required this.pdfPath,
    required this.startPage,
    this.endPage,
  });
}

class PdfChapterLocator {
  /// Locates the NCERT PDF for a given curriculum chapter.
  /// 
  /// Currently assumes that the PDF is packaged inside the chapter's root path
  /// as `source.pdf`. If a single-grade-level PDF architecture is adopted later,
  /// this mapping can be updated to return specific page ranges.
  Future<ChapterPdfReference?> locateChapterPdf(CurriculumChapter chapter) async {
    final pdfPath = p.join(chapter.rootPath, 'source.pdf');
    final file = File(pdfPath);
    
    if (await file.exists()) {
      return ChapterPdfReference(
        pdfPath: pdfPath,
        startPage: 0, // 0-indexed in flutter_pdfview
        endPage: null, // Full document
      );
    }

    // Fallback or alternative names if required
    final alternativePath = p.join(chapter.rootPath, 'textbook.pdf');
    final altFile = File(alternativePath);
    if (await altFile.exists()) {
      return ChapterPdfReference(
        pdfPath: alternativePath,
        startPage: 0,
        endPage: null,
      );
    }

    return null; // PDF not found locally
  }
}
