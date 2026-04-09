import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../data/local/content_pack_repository.dart';
import '../domain/content_pack_models.dart';

class PackArchiveExportResult {
  const PackArchiveExportResult({
    required this.archivePath,
    required this.packId,
    required this.itemCount,
    required this.sizeBytes,
  });

  final String archivePath;
  final String packId;
  final int itemCount;
  final int sizeBytes;
}

class PackArchiveImportResult {
  const PackArchiveImportResult({
    required this.packId,
    required this.itemCount,
    required this.installedRoot,
  });

  final String packId;
  final int itemCount;
  final String installedRoot;
}

class PackVersionConflictException implements Exception {
  const PackVersionConflictException({
    required this.packId,
    required this.incomingVersion,
    required this.installedVersion,
  });

  final String packId;
  final int incomingVersion;
  final int installedVersion;

  @override
  String toString() {
    return 'Incoming pack version $incomingVersion is not newer than installed version '
        '$installedVersion for $packId';
  }
}

class ContentPackArchiveService {
  ContentPackArchiveService({ContentPackRepository? repository})
      : _repository = repository ?? ContentPackRepository();

  final ContentPackRepository _repository;

  Future<PackArchiveExportResult> exportPackArchive(String packId) async {
    final entry = await _repository.buildCatalogEntry(packId);
    final items = await _repository.listItemsForPack(packId);

    final exportRoot = await _repository.packRootDirectory;
    final exportDir = Directory(p.join(exportRoot.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final archiveName = '${entry.manifest.packId}_v${entry.manifest.version}_$now.otpack';
    final archivePath = p.join(exportDir.path, archiveName);

    final tempDir = await Directory.systemTemp.createTemp('pack_export_');
    try {
      final manifestMap = _buildArchiveManifest(entry.manifest, items);
      final manifestFile = File(p.join(tempDir.path, 'pack_manifest.json'));
      await manifestFile.writeAsString(jsonEncode(manifestMap));

      final encoder = ZipFileEncoder();
      encoder.create(archivePath);
      encoder.addFile(manifestFile, 'pack_manifest.json');

      for (final item in items) {
        final source = File(item.absolutePath);
        if (!await source.exists()) {
          continue;
        }
        final relative = _normalizeRelative(item.relativePath);
        encoder.addFile(source, p.join('content', relative));
      }

      encoder.close();

      final archiveFile = File(archivePath);
      final stat = await archiveFile.stat();
      return PackArchiveExportResult(
        archivePath: archivePath,
        packId: packId,
        itemCount: items.length,
        sizeBytes: stat.size,
      );
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<PackArchiveImportResult> importPackArchive(
    String archivePath, {
    bool allowReplaceSameOrOlder = false,
  }) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw Exception('Pack archive not found: $archivePath');
    }

    final root = await _repository.packRootDirectory;
    final unpackDir = Directory(
      p.join(root.path, 'installed', 'incoming_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await unpackDir.create(recursive: true);

    File? tempZipAlias;
    try {
      var extractionInputPath = archivePath;
      if (archivePath.toLowerCase().endsWith('.otpack')) {
        tempZipAlias = File(
          p.join(
            Directory.systemTemp.path,
            'pack_${DateTime.now().millisecondsSinceEpoch}.zip',
          ),
        );
        await archiveFile.copy(tempZipAlias.path);
        extractionInputPath = tempZipAlias.path;
      }

      extractFileToDisk(extractionInputPath, unpackDir.path);
    } finally {
      if (tempZipAlias != null && await tempZipAlias.exists()) {
        await tempZipAlias.delete();
      }
    }

    final manifestFile = File(p.join(unpackDir.path, 'pack_manifest.json'));
    if (!await manifestFile.exists()) {
      throw Exception('Invalid pack archive: missing pack_manifest.json');
    }

    final raw = await manifestFile.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = decoded['manifest'] as Map<String, dynamic>?;
    final items = decoded['items'] as List<dynamic>?;
    if (manifest == null || items == null) {
      throw Exception('Invalid pack archive: missing manifest/items section');
    }

    final packId = manifest['packId'] as String?;
    if (packId == null || packId.trim().isEmpty) {
      throw Exception('Invalid pack archive: packId missing');
    }
    final incomingVersion = manifest['version'] as int? ?? 1;
    final existingPack = await _repository.getPackById(packId);
    if (!allowReplaceSameOrOlder &&
        existingPack != null &&
        incomingVersion <= existingPack.version) {
      throw PackVersionConflictException(
        packId: packId,
        incomingVersion: incomingVersion,
        installedVersion: existingPack.version,
      );
    }

    final contentDir = Directory(p.join(unpackDir.path, 'content'));
    if (!await contentDir.exists()) {
      throw Exception('Invalid pack archive: content directory missing');
    }

    final packItems = <ContentPackItem>[];
    var totalSize = 0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      final relative = _normalizeRelative(item['relativePath'] as String? ?? '');
      if (relative.isEmpty) {
        continue;
      }
      final absolute = p.join(contentDir.path, relative);
      final file = File(absolute);
      if (!await file.exists()) {
        continue;
      }
      final stat = await file.stat();
      totalSize += stat.size;
      packItems.add(
        ContentPackItem(
          packId: packId,
          kind: (item['kind'] as String? ?? 'other').toLowerCase(),
          title: item['title'] as String? ?? p.basename(relative),
          relativePath: relative,
          absolutePath: absolute,
          grade: item['grade'] as int?,
          subject: item['subject'] as String?,
          medium: item['medium'] as String?,
          chapterId: item['chapterId'] as String?,
          languageCode: item['languageCode'] as String?,
          orderIndex: item['orderIndex'] as int? ?? i,
          sizeBytes: stat.size,
          metadataJson: item['metadataJson'] as String?,
        ),
      );
    }

    final installedAt = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$packId:$installedAt:$totalSize:${packItems.length}')).toString();

    final packManifest = ContentPackManifest(
      packId: packId,
      title: manifest['title'] as String? ?? packId,
      medium: manifest['medium'] as String? ?? 'Mixed',
      subject: manifest['subject'] as String? ?? 'All Subjects',
      gradeMin: manifest['gradeMin'] as int? ?? 1,
      gradeMax: manifest['gradeMax'] as int? ?? 10,
      version: incomingVersion,
      manifestPath: manifestFile.path,
      rootPath: contentDir.path,
      contentHash: hash,
      contentSizeBytes: totalSize,
      installedAt: installedAt,
      status: 'installed',
    );

    await _repository.upsertPack(manifest: packManifest, items: packItems);

    return PackArchiveImportResult(
      packId: packId,
      itemCount: packItems.length,
      installedRoot: contentDir.path,
    );
  }

  Map<String, dynamic> _buildArchiveManifest(
    ContentPackManifest manifest,
    List<ContentPackItem> items,
  ) {
    return <String, dynamic>{
      'manifest': <String, dynamic>{
        'packId': manifest.packId,
        'title': manifest.title,
        'medium': manifest.medium,
        'subject': manifest.subject,
        'gradeMin': manifest.gradeMin,
        'gradeMax': manifest.gradeMax,
        'version': manifest.version,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'items': items
          .map(
            (item) => <String, dynamic>{
              'kind': item.kind,
              'title': item.title,
              'relativePath': _normalizeRelative(item.relativePath),
              'grade': item.grade,
              'subject': item.subject,
              'medium': item.medium,
              'chapterId': item.chapterId,
              'languageCode': item.languageCode,
              'orderIndex': item.orderIndex,
              'metadataJson': item.metadataJson,
            },
          )
          .toList(),
    };
  }

  String _normalizeRelative(String value) {
    var normalized = value.replaceAll('\\\\', '/').replaceAll('\\', '/');
    normalized = normalized.replaceAll(RegExp(r'^/+'), '');
    return normalized;
  }
}
