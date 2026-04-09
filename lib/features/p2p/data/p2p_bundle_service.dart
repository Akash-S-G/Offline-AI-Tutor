import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../course/domain/course_tree.dart';
import '../../rag/data/local/rag_repository.dart';

class BundleExportResult {
  const BundleExportResult({
    required this.filePath,
    required this.chunkCount,
  });

  final String filePath;
  final int chunkCount;
}

class BundleImportResult {
  const BundleImportResult({
    required this.chapterId,
    required this.importedChunkCount,
    required this.manifestVersion,
  });

  final String chapterId;
  final int importedChunkCount;
  final int manifestVersion;
}

class BundleTransferProgress {
  const BundleTransferProgress({
    required this.current,
    required this.total,
    required this.operation,
    this.estimatedRemainingSeconds,
  });

  final int current;
  final int total;
  final String operation; // 'exporting' or 'importing'
  final int? estimatedRemainingSeconds;

  double get percentComplete => total > 0 ? (current / total) : 0.0;
}

class BundleTransferError {
  const BundleTransferError({
    required this.message,
    required this.isRetryable,
    this.attemptedRetries = 0,
    this.originalError,
  });

  final String message;
  final bool isRetryable;
  final int attemptedRetries;
  final Exception? originalError;
}

class P2PBundleService {
  P2PBundleService({required RagRepository ragRepository})
      : _ragRepository = ragRepository;

  final RagRepository _ragRepository;

  Future<BundleExportResult> exportChapterBundle(
    Chapter chapter, {
    required String sharedSecret,
    required void Function(BundleTransferProgress) onProgress,
  }) async {
    final secret = sharedSecret.trim();
    if (secret.isEmpty) {
      throw Exception('Shared secret is required to export signed bundles.');
    }

    onProgress(BundleTransferProgress(
      current: 0,
      total: 3,
      operation: 'exporting',
    ));

    final chunks = await _ragRepository.getChunksForChapter(chapter.id);
    final chunkCount = chunks.length;

    onProgress(BundleTransferProgress(
      current: 1,
      total: 3,
      operation: 'exporting',
    ));

    final payload = {
      'chapterId': chapter.id,
      'chapterTitle': chapter.title,
      'chunks': chunks
          .map(
            (c) => {
              'id': c.id,
              'sourceTitle': c.sourceTitle,
              'chunkOrder': c.chunkOrder,
              'content': c.content,
            },
          )
          .toList(),
    };

    final payloadJson = jsonEncode(payload);
    final payloadHash = sha256.convert(utf8.encode(payloadJson)).toString();
    final payloadSignature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(payloadJson))
        .toString();

    onProgress(BundleTransferProgress(
      current: 2,
      total: 3,
      operation: 'exporting',
    ));

    final bundle = {
      'manifest': {
        'version': 2,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'payloadHash': payloadHash,
        'payloadSignature': payloadSignature,
        'signatureAlgo': 'hmac-sha256',
        'payloadType': 'chapter-rag-bundle',
      },
      'payload': payload,
    };

    final outDir = await _getExportDir();
    final safeTitle =
        chapter.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final fileName = 'bundle_${chapter.id}_$safeTitle.json';
    final file = File(path.join(outDir.path, fileName));
    await file.writeAsString(jsonEncode(bundle));

    onProgress(BundleTransferProgress(
      current: 3,
      total: 3,
      operation: 'exporting',
    ));

    return BundleExportResult(
      filePath: file.path,
      chunkCount: chunkCount,
    );
  }

  Future<BundleImportResult> importBundleFromFile(
    String filePath, {
    required List<String> verificationSecrets,
    required void Function(BundleTransferProgress) onProgress,
    int maxRetries = 3,
  }) async {
    var lastError = BundleTransferError(
      message: 'Unknown error',
      isRetryable: false,
    );

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _importBundleInternal(
          filePath,
          verificationSecrets: verificationSecrets,
          onProgress: onProgress,
          attempt: attempt,
          totalAttempts: maxRetries,
        );
      } on Exception catch (e) {
        final message = e.toString();
        final isRetryable = message.contains('I/O') ||
            message.contains('network') ||
            message.contains('timeout') ||
            message.contains('temporarily');

        lastError = BundleTransferError(
          message: message,
          isRetryable: isRetryable,
          attemptedRetries: attempt,
          originalError: e,
        );

        if (!isRetryable || attempt == maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw Exception('Import failed after $maxRetries attempts: ${lastError.message}');
  }

  Future<BundleImportResult> _importBundleInternal(
    String filePath, {
    required List<String> verificationSecrets,
    required void Function(BundleTransferProgress) onProgress,
    required int attempt,
    required int totalAttempts,
  }) async {
    final secrets =
        verificationSecrets.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (secrets.isEmpty) {
      throw Exception('Shared secret is required to verify signed bundles.');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Bundle file not found.');
    }

    onProgress(BundleTransferProgress(
      current: 0,
      total: 3,
      operation: 'importing',
    ));

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = decoded['manifest'] as Map<String, dynamic>?;
    final payload = decoded['payload'] as Map<String, dynamic>?;

    if (manifest == null || payload == null) {
      throw Exception('Invalid bundle format (attempt $attempt/$totalAttempts).');
    }

    onProgress(BundleTransferProgress(
      current: 1,
      total: 3,
      operation: 'importing',
    ));

    final payloadJson = jsonEncode(payload);
    final actualHash = sha256.convert(utf8.encode(payloadJson)).toString();
    final expectedHash = manifest['payloadHash'] as String? ?? '';
    final expectedSignature = manifest['payloadSignature'] as String? ?? '';
    final signatureAlgo = (manifest['signatureAlgo'] as String? ?? '').toLowerCase();

    if (expectedHash.isEmpty || actualHash != expectedHash) {
      throw Exception(
          'Bundle integrity check failed - hash mismatch (attempt $attempt/$totalAttempts).');
    }
    if (signatureAlgo != 'hmac-sha256' || expectedSignature.isEmpty) {
      throw Exception(
          'Bundle authenticity check failed - signature invalid (attempt $attempt/$totalAttempts).');
    }

    final signatureMatched = secrets.any((secret) {
      final actualSignature = Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode(payloadJson))
          .toString();
      return actualSignature == expectedSignature;
    });
    if (!signatureMatched) {
      throw Exception(
          'Bundle authenticity check failed - signature mismatch (attempt $attempt/$totalAttempts).');
    }

    final chapterId = payload['chapterId'] as String?;
    final chapterTitle = payload['chapterTitle'] as String?;
    final rawChunks = payload['chunks'] as List<dynamic>?;

    if (chapterId == null || chapterTitle == null || rawChunks == null) {
      throw Exception('Bundle payload missing required fields.');
    }

    var importedCount = 0;
    for (final (index, rawChunk) in rawChunks.indexed) {
      final chunk = rawChunk as Map<String, dynamic>;
      final content = (chunk['content'] as String? ?? '').trim();
      final sourceTitle =
          (chunk['sourceTitle'] as String? ?? 'Imported Bundle').trim();
      if (content.isEmpty) {
        continue;
      }

      await _ragRepository.ingestChapterNotes(
        chapterId: chapterId,
        sourceTitle: sourceTitle,
        rawText: content,
      );
      importedCount += 1;

      onProgress(BundleTransferProgress(
        current: 2 + (index / rawChunks.length).round(),
        total: 3,
        operation: 'importing',
      ));
    }

    onProgress(BundleTransferProgress(
      current: 3,
      total: 3,
      operation: 'importing',
    ));

    return BundleImportResult(
      chapterId: chapterId,
      importedChunkCount: importedCount,
      manifestVersion: manifest['version'] as int? ?? 0,
    );
  }

  Future<Directory> _getExportDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(base.path, 'p2p_exports'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
