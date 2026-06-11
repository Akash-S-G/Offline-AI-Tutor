import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../network/domain/runtime_backend_url.dart';

class PdfInstallResult {
  const PdfInstallResult({
    required this.chapterId,
    required this.pdfDownloaded,
    required this.pdfReused,
    required this.pdfSize,
    required this.installSuccess,
    this.bookId,
    this.failureReason,
  });

  final String chapterId;
  final bool pdfDownloaded;
  final bool pdfReused;
  final int pdfSize;
  final bool installSuccess;
  final String? bookId;
  final String? failureReason;

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'bookId': bookId,
      'pdfDownloaded': pdfDownloaded,
      'pdfReused': pdfReused,
      'pdfSize': pdfSize,
      'installSuccess': installSuccess,
      'failureReason': failureReason,
    };
  }
}

class PdfInstallService {
  PdfInstallService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<PdfInstallResult> installChapterPdf({
    required String chapterRootPath,
    required String chapterId,
    required int grade,
    required String subject,
    required String chapter,
    String? medium,
    String? language,
    void Function(String message)? onProgress,
  }) async {
    final sourcePdf = File(p.join(chapterRootPath, 'source.pdf'));
    if (await _isNonEmptyFile(sourcePdf)) {
      final stat = await sourcePdf.stat();
      return PdfInstallResult(
        chapterId: chapterId,
        pdfDownloaded: false,
        pdfReused: true,
        pdfSize: stat.size,
        installSuccess: true,
      );
    }

    onProgress?.call('Downloading PDF...');
    try {
      final resolved = await _withRetry(
        () => _resolvePdf(
          grade: grade,
          subject: subject,
          chapter: chapter,
          medium: medium,
          language: language,
        ),
      );
      final bookId = _readBookId(resolved);
      if (bookId == null || bookId.trim().isEmpty) {
        throw StateError('PDF resolve response did not include book_id.');
      }

      final bytes = await _withRetry(() => _downloadPdf(bookId));
      if (bytes.isEmpty) {
        throw StateError('Downloaded PDF was empty.');
      }

      onProgress?.call('Saving PDF...');
      await sourcePdf.parent.create(recursive: true);
      final tempFile = File('${sourcePdf.path}.download');
      await tempFile.writeAsBytes(bytes, flush: true);
      if (await sourcePdf.exists()) {
        await tempFile.delete();
      } else {
        await tempFile.rename(sourcePdf.path);
      }

      onProgress?.call('Finalizing Chapter...');
      if (!await _isNonEmptyFile(sourcePdf)) {
        throw StateError('PDF validation failed after save.');
      }
      final stat = await sourcePdf.stat();
      return PdfInstallResult(
        chapterId: chapterId,
        bookId: bookId,
        pdfDownloaded: true,
        pdfReused: false,
        pdfSize: stat.size,
        installSuccess: true,
      );
    } catch (error) {
      return PdfInstallResult(
        chapterId: chapterId,
        pdfDownloaded: false,
        pdfReused: false,
        pdfSize: 0,
        installSuccess: false,
        failureReason: error.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _resolvePdf({
    required int grade,
    required String subject,
    required String chapter,
    String? medium,
    String? language,
  }) async {
    final uri = _apiUri('/api/v1/pdf/resolve').replace(
      queryParameters: {
        'grade': '$grade',
        'subject': subject,
        'chapter': chapter,
        if (medium != null && medium.trim().isNotEmpty) 'medium': medium,
        if (language != null && language.trim().isNotEmpty)
          'language': language,
      },
    );
    final response = await _get(uri, accept: 'application/json');
    final body = await utf8.decodeStream(response);
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('PDF resolve response was not a JSON object.');
  }

  Future<List<int>> _downloadPdf(String bookId) async {
    final encodedBookId = Uri.encodeComponent(bookId);
    final response = await _get(
      _apiUri('/api/v1/pdf/file/$encodedBookId'),
      accept: 'application/pdf',
    );
    final chunks = <int>[];
    await for (final chunk in response) {
      chunks.addAll(chunk);
    }
    return chunks;
  }

  Future<HttpClientResponse> _get(Uri uri, {required String accept}) async {
    final request = await _httpClient
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.acceptHeader, accept);
    final response = await request.close().timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    return response;
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        if (attempt == 3) break;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    throw lastError ?? StateError('PDF install operation failed.');
  }

  Uri _apiUri(String path) {
    final base = RuntimeBackendUrl().current;
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return Uri.parse('$normalizedBase$path');
  }

  String? _readBookId(Map<String, dynamic> resolved) {
    final candidates = [
      resolved['book_id'],
      resolved['bookId'],
      resolved['id'],
      if (resolved['data'] is Map) (resolved['data'] as Map)['book_id'],
      if (resolved['data'] is Map) (resolved['data'] as Map)['bookId'],
      if (resolved['pdf'] is Map) (resolved['pdf'] as Map)['book_id'],
      if (resolved['pdf'] is Map) (resolved['pdf'] as Map)['bookId'],
      if (resolved['book'] is Map) (resolved['book'] as Map)['id'],
      if (resolved['book'] is Map) (resolved['book'] as Map)['book_id'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<bool> _isNonEmptyFile(File file) async {
    if (!await file.exists()) return false;
    final stat = await file.stat();
    return stat.size > 0;
  }
}
