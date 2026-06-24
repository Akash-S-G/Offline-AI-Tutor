import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../content_packs/data/local/content_pack_repository.dart';
import '../../../network/domain/runtime_backend_url.dart';
import '../models/experiment_descriptor.dart';

final phetCatalogServiceProvider = Provider((ref) => PhetCatalogService());

class PhetCatalogService {
  PhetCatalogService({ContentPackRepository? packRepository})
    : _packRepository = packRepository ?? ContentPackRepository();

  static const packId = 'phet_simulations_v1';
  static const fallbackAsset = 'assets/phet/simulations/placeholder.html';

  final ContentPackRepository _packRepository;

  Future<PhetCatalogSnapshot> loadCatalog() async {
    final installed = await _loadInstalledCatalog();
    if (installed != null && installed.experiments.isNotEmpty) {
      return installed;
    }

    final remote = await _loadGatewayCatalog();
    if (remote != null && remote.experiments.isNotEmpty) {
      return remote;
    }

    return _loadBundledFallback();
  }

  Future<bool> isPackInstalled() async {
    final pack = await _packRepository.getPackById(packId);
    if (pack == null || pack.rootPath.isEmpty) {
      return false;
    }
    return _findCatalogFile(Directory(pack.rootPath)) != null;
  }

  Future<PhetCatalogSnapshot?> _loadInstalledCatalog() async {
    final pack = await _packRepository.getPackById(packId);
    if (pack == null || pack.rootPath.isEmpty) {
      return null;
    }

    final catalogFile = _findCatalogFile(Directory(pack.rootPath));
    if (catalogFile == null) {
      return null;
    }
    final decoded = jsonDecode(await catalogFile.readAsString());
    final simulations = _simulationList(decoded);
    final experiments = <ExperimentDescriptor>[];

    for (final simulation in simulations) {
      final slug = simulation['slug']?.toString().trim() ?? '';
      if (slug.isEmpty) continue;
      final localFile = _findSimulationIndex(
        root: Directory(pack.rootPath),
        catalogDirectory: catalogFile.parent,
        slug: slug,
      );
      if (localFile == null) continue;
      experiments.add(
        ExperimentDescriptor.fromPhetCatalog(
          json: simulation,
          launchLocation: localFile.path,
          launchSource: ExperimentLaunchSource.installedPack,
        ),
      );
    }

    return PhetCatalogSnapshot(
      experiments: experiments,
      source: ExperimentLaunchSource.installedPack,
      packInstalled: true,
      message: 'Loaded from the installed offline PhET pack.',
    );
  }

  Future<PhetCatalogSnapshot?> _loadGatewayCatalog() async {
    HttpClient? client;
    try {
      final baseUrl = RuntimeBackendUrl().current;
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client
          .getUrl(Uri.parse('$baseUrl/experiments/catalog'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(await utf8.decodeStream(response));
      final experiments = parseGatewayCatalog(decoded, baseUrl: baseUrl);

      return PhetCatalogSnapshot(
        experiments: experiments,
        source: ExperimentLaunchSource.classroomGateway,
        packInstalled: await isPackInstalled(),
        message: 'Loaded from the connected PiHub classroom.',
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<PhetCatalogSnapshot> _loadBundledFallback() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/phet/catalog.json',
      );
      final decoded = jsonDecode(jsonString);
      final list = decoded is List ? decoded : const <dynamic>[];
      final experiments = list
          .whereType<Map<String, dynamic>>()
          .map(ExperimentDescriptor.fromLegacyJson)
          .toList();
      return PhetCatalogSnapshot(
        experiments: experiments,
        source: ExperimentLaunchSource.bundledFallback,
        packInstalled: false,
        message: 'PiHub is unavailable. Showing bundled preview entries only.',
      );
    } catch (_) {
      return const PhetCatalogSnapshot(
        experiments: [],
        source: ExperimentLaunchSource.bundledFallback,
        packInstalled: false,
        message: 'No PhET catalog is available.',
      );
    }
  }

  List<Map<String, dynamic>> _simulationList(Object? decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      final simulations = decoded['simulations'];
      if (simulations is List) {
        return simulations.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  List<ExperimentDescriptor> parseGatewayCatalog(
    Object? decoded, {
    required String baseUrl,
  }) {
    return _simulationList(decoded)
        .map((simulation) {
          final localUrl = simulation['local_url']?.toString().trim() ?? '';
          final publicUrl = simulation['url']?.toString().trim() ?? '';
          final launchUri = localUrl.isNotEmpty
              ? Uri.parse(baseUrl).resolve(localUrl)
              : Uri.tryParse(publicUrl);
          return ExperimentDescriptor.fromPhetCatalog(
            json: simulation,
            launchLocation: launchUri?.toString() ?? '',
            launchSource: ExperimentLaunchSource.classroomGateway,
          );
        })
        .where((item) => item.launchLocation.isNotEmpty)
        .toList();
  }

  File? _findCatalogFile(Directory root) {
    if (!root.existsSync()) return null;
    final directCandidates = <String>[
      p.join(root.path, 'catalog.json'),
      p.join(root.path, 'phet', 'catalog.json'),
      p.join(root.path, 'simulations', 'catalog.json'),
    ];
    for (final path in directCandidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == 'catalog.json') {
        return entity;
      }
    }
    return null;
  }

  File? _findSimulationIndex({
    required Directory root,
    required Directory catalogDirectory,
    required String slug,
  }) {
    final candidates = <String>[
      p.join(root.path, 'simulations', slug, 'index.html'),
      p.join(catalogDirectory.path, 'simulations', slug, 'index.html'),
      p.join(catalogDirectory.path, slug, 'index.html'),
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }
}
