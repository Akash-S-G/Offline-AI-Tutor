import 'dart:io';

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

  Future<void> install({
    void Function(String message, double? progress)? onProgress,
  }) async {
    if (await isInstalled()) {
      onProgress?.call('PhET pack is already installed.', 1);
      return;
    }
    final existingRecord = await _repository.getPackById(
      PhetCatalogService.packId,
    );

    final tempDirectory = await getTemporaryDirectory();
    final archive = File(
      p.join(tempDirectory.path, '${PhetCatalogService.packId}.tar.gz'),
    );
    final url =
        '${RuntimeBackendUrl().current}/packs/${PhetCatalogService.packId}/download';
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      onProgress?.call('Downloading PhET simulations...', 0);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'PhET pack download failed with HTTP ${response.statusCode}',
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
        allowReplaceSameOrOlder: existingRecord != null,
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
