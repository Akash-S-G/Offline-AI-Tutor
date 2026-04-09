import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/translation_engine_catalog.dart';

class TranslationEngineConfig {
  const TranslationEngineConfig({
    required this.engineId,
    required this.apertiumExecutablePath,
    required this.showOriginalAlongside,
  });

  final TranslationEngineId engineId;
  final String apertiumExecutablePath;
  final bool showOriginalAlongside;

  bool get hasApertiumBinary => apertiumExecutablePath.trim().isNotEmpty;

  TranslationEngineConfig copyWith({
    TranslationEngineId? engineId,
    String? apertiumExecutablePath,
    bool? showOriginalAlongside,
  }) {
    return TranslationEngineConfig(
      engineId: engineId ?? this.engineId,
      apertiumExecutablePath: apertiumExecutablePath ?? this.apertiumExecutablePath,
      showOriginalAlongside: showOriginalAlongside ?? this.showOriginalAlongside,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'engineId': engineId.name,
      'apertiumExecutablePath': apertiumExecutablePath,
      'showOriginalAlongside': showOriginalAlongside,
    };
  }

  static TranslationEngineConfig fromJson(Map<String, dynamic> json) {
    return TranslationEngineConfig(
      engineId: TranslationEngineCatalog.parseId(
        (json['engineId'] as String?) ?? TranslationEngineId.apertiumCli.name,
      ),
      apertiumExecutablePath: (json['apertiumExecutablePath'] as String?) ?? '',
      showOriginalAlongside: (json['showOriginalAlongside'] as bool?) ?? false,
    );
  }

  static const TranslationEngineConfig defaults = TranslationEngineConfig(
    engineId: TranslationEngineId.apertiumCli,
    apertiumExecutablePath: 'apertium',
    showOriginalAlongside: false,
  );
}

class TranslationEngineConfigService {
  Future<TranslationEngineConfig> load() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) {
        return TranslationEngineConfig.defaults;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return TranslationEngineConfig.defaults;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return TranslationEngineConfig.defaults;
      }

      return TranslationEngineConfig.fromJson(decoded);
    } catch (_) {
      return TranslationEngineConfig.defaults;
    }
  }

  Future<TranslationEngineConfig> save(TranslationEngineConfig config) async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(config.toJson()));
    return config;
  }

  Future<TranslationEngineConfig> update({
    TranslationEngineId? engineId,
    String? apertiumExecutablePath,
    bool? showOriginalAlongside,
  }) async {
    final current = await load();
    final next = current.copyWith(
      engineId: engineId,
      apertiumExecutablePath: apertiumExecutablePath,
      showOriginalAlongside: showOriginalAlongside,
    );
    return save(next);
  }

  Future<File> _configFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/translation_engine_config.json');
  }
}
