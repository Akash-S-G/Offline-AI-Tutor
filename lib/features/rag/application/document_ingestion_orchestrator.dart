import '../domain/chunk_v2.dart';
import 'document_loader_service.dart';
import 'formula_extractor.dart';
import 'multilingual_processor.dart';
import 'pdf_extraction_service.dart';
import 'pdf_structure_extraction_service.dart';
import 'semantic_chunking_service.dart';

/// Orchestrates full ingestion pipeline for document files (PDFs, text, etc.)
class DocumentIngestionOrchestrator {
  DocumentIngestionOrchestrator();

  /// Process a single PDF document
  /// Returns list of ChunkV2 objects ready for database insertion
  Future<DocumentProcessResult> processDocument({
    required DocumentFile documentFile,
    required String chapterId,
  }) async {
    try {
      // Parse metadata from filename
      final metadata = DocumentLoaderService.parseFilename(documentFile.name);

      // Check if file is readable
      final readable = await DocumentLoaderService.isFileReadable(documentFile.path);
      if (!readable) {
        return DocumentProcessResult(
          success: false,
          message: 'File not readable: ${documentFile.path}',
          documentName: documentFile.name,
        );
      }

      // Extract text content from PDF
      // NOTE: For real PDF parsing, integrate pdfx or similar library
      // For now, this is a placeholder that simulates text extraction
      final textContent = await _extractTextFromPdf(documentFile.path);

      if (textContent.isEmpty) {
        return DocumentProcessResult(
          success: false,
          message: 'No text content extracted from PDF',
          documentName: documentFile.name,
        );
      }

      // Detect language and normalize
      final detectedLang = MultilingualProcessor.detectLanguage(textContent);
      String processedContent = textContent;

      if (detectedLang == 'kn') {
        processedContent = MultilingualProcessor.normalizeKannada(textContent);
        processedContent = MultilingualProcessor.cleanMixedLanguage(processedContent);
      }

      // Extract layout-aware blocks before chunking.
      final blocks = PdfStructureExtractionService.extractBlocks(processedContent);

      final chunks = <ChunkV2>[];
      var chunkOffset = 0;
      for (final block in blocks) {
        final blockChunks = SemanticChunkingService.chunkText(
          text: block.content,
          chapterId: chapterId,
          sourceTitle: metadata.displayName,
          sourceLanguage: detectedLang,
          section: block.heading.isEmpty ? metadata.subject : block.heading,
          subsection: block.type,
        );

        for (final c in blockChunks) {
          chunks.add(
            ChunkV2(
              id: c.id,
              chapterId: c.chapterId,
              sourceTitle: c.sourceTitle,
              sourceLanguage: c.sourceLanguage,
              content: c.content,
              contentType: c.contentType,
              chunkOrder: chunkOffset,
              createdAt: c.createdAt,
              tokenCount: c.tokenCount,
              originalMarkdown: c.originalMarkdown,
              formulas: c.formulas,
              metadata: {
                ...c.metadata,
                'layout_type': block.type,
              },
            ),
          );
          chunkOffset += 1;
        }
      }

      // Enrich chunks with formulas
      final enrichedChunks = <ChunkV2>[];
      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];

        // Extract formulas from this chunk
        final formulas = FormulaExtractor.extractFormulas(chunk.content);

        // Enrich metadata with document info
        final enrichedMetadata = {
          ...chunk.metadata,
          'source_document': metadata.displayName,
          'document_part': metadata.part,
          'source_grade': metadata.grade,
        };

        final enrichedChunk = ChunkV2(
          id: '${chapterId}_${metadata.subject.replaceAll(' ', '_')}_chunk_$i',
          chapterId: chapterId,
          sourceTitle: metadata.displayName,
          sourceLanguage: detectedLang,
          content: chunk.content,
          contentType: chunk.contentType,
          chunkOrder: i,
          createdAt: DateTime.now(),
          tokenCount: _estimateTokenCount(chunk.content),
          originalMarkdown: null,
          formulas: formulas,
          metadata: enrichedMetadata,
        );

        enrichedChunks.add(enrichedChunk);
      }

      return DocumentProcessResult(
        success: true,
        message: 'Processed successfully',
        documentName: documentFile.name,
        chunksCreated: enrichedChunks.length,
        chunks: enrichedChunks,
        language: detectedLang,
        subject: metadata.subject,
      );
    } catch (e) {
      return DocumentProcessResult(
        success: false,
        message: 'Processing failed: $e',
        documentName: documentFile.name,
      );
    }
  }

  /// Batch process multiple documents
  Future<List<DocumentProcessResult>> processBatch(
    List<DocumentFile> documents,
    String chapterId,
  ) async {
    final results = <DocumentProcessResult>[];

    for (final doc in documents) {
      final result = await processDocument(
        documentFile: doc,
        chapterId: chapterId,
      );
      results.add(result);
    }

    return results;
  }

  // ─────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────

  /// Extract text from PDF file using pdfx library
  Future<String> _extractTextFromPdf(String filePath) async {
    try {
      return await PdfExtractionService.extractTextFromPdf(filePath);
    } catch (e) {
      throw Exception('PDF extraction failed: $e');
    }
  }

  int _estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }
}

/// Result of processing a single document
class DocumentProcessResult {
  final bool success;
  final String message;
  final String documentName;
  final int chunksCreated;
  final List<ChunkV2> chunks;
  final String? language;
  final String? subject;

  DocumentProcessResult({
    required this.success,
    required this.message,
    required this.documentName,
    this.chunksCreated = 0,
    this.chunks = const [],
    this.language,
    this.subject,
  });

  @override
  String toString() => '''
DocumentProcessResult(
  document: $documentName,
  success: $success,
  chunks: $chunksCreated,
  language: $language,
  subject: $subject
)''';
}
