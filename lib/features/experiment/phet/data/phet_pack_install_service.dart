import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../content_packs/application/content_pack_archive_service.dart';
import '../../../content_packs/data/local/content_pack_repository.dart';
import '../../../network/domain/runtime_backend_url.dart';
import 'phet_catalog_service.dart';

class PhetPackInstallService {
  PhetPackInstallService({
    ContentPackArchiveService? archiveService,
    ContentPackRepository? repository,
  }) : _archiveService = archiveService ?? ContentPackArchiveService(),
       _repository = repository ?? ContentPackRepository();

  final ContentPackArchiveService _archiveService;
  final ContentPackRepository _repository;

  Future<bool> isInstalled() async {
    final pack = await _repository.getPackById(PhetCatalogService.packId);
    if (pack == null || pack.rootPath.isEmpty) {
      return false;
    }
    final root = Directory(pack.rootPath);
    if (!await root.exists()) {
      return false;
    }
    return root
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .any((file) => p.basename(file.path) == 'catalog.json');
  }

  Future<int?> _installedVersion() async {
    final pack = await _repository.getPackById(PhetCatalogService.packId);
    return pack?.version;
  }

  Future<int?> _remoteVersion() async {
    final url =
        '${RuntimeBackendUrl().current}/packs/${PhetCatalogService.packId}/manifest';
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(await utf8.decodeStream(response));
      if (decoded is Map<String, dynamic>) {
        final directVersion = _parseVersion(decoded['version']);
        if (directVersion != null) {
          return directVersion;
        }

        final nestedManifest = decoded['manifest'];
        if (nestedManifest is Map<String, dynamic>) {
          return _parseVersion(nestedManifest['version']);
        }
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  int? _parseVersion(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final major = value.trim().split('.').first.trim();
      return int.tryParse(major);
    }
    return null;
  }

  Future<void> install({
    void Function(String message, double? progress)? onProgress,
  }) async {
    final existingRecord = await _repository.getPackById(
      PhetCatalogService.packId,
    );
    final localVersion = existingRecord?.version ?? await _installedVersion();
    final remoteVersion = await _remoteVersion();

    if (localVersion != null && remoteVersion != null) {
      if (remoteVersion <= localVersion && await isInstalled()) {
        onProgress?.call('PhET pack is already up to date.', 1);
        return;
      }
    } else if (await isInstalled()) {
      onProgress?.call('PhET pack is already installed.', 1);
      return;
    }

    final tempDirectory = await getTemporaryDirectory();
    final archive = File(
      p.join(tempDirectory.path, '${PhetCatalogService.packId}.tar.gz'),
    );
      final base = RuntimeBackendUrl().current;
    final url = '$base/packs/${PhetCatalogService.packId}/download';
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final resolvedBackend = RuntimeBackendUrl().current;
      debugPrint('[PHET][INSTALL] backend=$resolvedBackend');
      final expectedManifestUrl = '$base/packs/${PhetCatalogService.packId}/manifest';
      debugPrint('[PHET][INSTALL] manifestUrl=$expectedManifestUrl (expected: /packs/{id}/manifest)');
      debugPrint('[PHET][INSTALL] downloadUrl=$url (expected: /packs/{id}/download)');

      onProgress?.call('Downloading PhET simulations...', 0);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        // Read a small body for diagnostics.
        String bodySnippet = '';
        try {
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
            if (bytes.length >= 4096) break;
          }
          bodySnippet = utf8.decode(bytes, allowMalformed: true);
          if (bodySnippet.length > 512) {
            bodySnippet = bodySnippet.substring(0, 512);
          }
        } catch (_) {}

        debugPrint(
          '[PHET][INSTALL] download failed status=$status bodySnippet=${bodySnippet.isEmpty ? '<empty>' : bodySnippet.replaceAll('\n', ' ')}',
        );

        throw HttpException(
          'PhET pack download failed with HTTP $status. $bodySnippet',
        );
      }
      final total = response.contentLength;
      var received = 0;
      final sink = archive.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(
          'Downloading PhET simulations...',
          total > 0 ? received / total : null,
        );
      }
      await sink.close();


      onProgress?.call('Installing simulations...', null);
      await _archiveService.importPackArchive(
        archive.path,
        allowReplaceSameOrOlder: false,
        onProgress: (message) => onProgress?.call(message, null),
      );
      onProgress?.call('PhET simulations are ready offline.', 1);
    } finally {
      client.close(force: true);
      if (await archive.exists()) {
        await archive.delete();
      }
    }
  }
}
