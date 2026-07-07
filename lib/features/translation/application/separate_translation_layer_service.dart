import 'dart:convert';
import 'dart:io';

import '../../chat/data/tutor_inference_gateway.dart';
import '../data/local/translation_engine_config_service.dart';
import '../data/local/translation_cache_repository.dart';
import '../domain/translation_engine_catalog.dart';

class TranslationResult {
  const TranslationResult({
    required this.translated,
    required this.engineUsed,
    required this.fallbackUsed,
  });

  final String translated;
  final TranslationEngineId engineUsed;
  final bool fallbackUsed;
}

class SeparateTranslationLayerService {
  SeparateTranslationLayerService({
    required TutorInferenceGateway gateway,
    TranslationCacheRepository? cacheRepository,
  })  : _gateway = gateway,
        _cacheRepository = cacheRepository ?? TranslationCacheRepository();

  final TutorInferenceGateway _gateway;
  final TranslationCacheRepository _cacheRepository;

  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    required TranslationEngineConfig config,
    String artifactType = 'generic',
    String? contentId,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || sourceLang == targetLang) {
      return TranslationResult(
        translated: text,
        engineUsed: config.engineId,
        fallbackUsed: false,
      );
    }

    final cached = await _cacheRepository.find(
      artifactType: artifactType,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      sourceText: clean,
      contentId: contentId,
    );
    if (cached != null) {
      return TranslationResult(
        translated: cached.translatedText,
        engineUsed: TranslationEngineCatalog.parseId(
          cached.engineId,
        ),
        fallbackUsed: cached.fallbackUsed,
      );
    }

    switch (config.engineId) {
      case TranslationEngineId.apertiumCli:
        final apertium = await _translateWithApertium(
          text: clean,
          sourceLang: sourceLang,
          targetLang: targetLang,
          executable: config.apertiumExecutablePath.trim().isEmpty
              ? 'apertium'
              : config.apertiumExecutablePath.trim(),
        );
        if (apertium != null && apertium.trim().isNotEmpty) {
          await _cacheRepository.upsert(
            artifactType: artifactType,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            sourceText: clean,
            translatedText: apertium.trim(),
            engineId: TranslationEngineId.apertiumCli.name,
            fallbackUsed: false,
            contentId: contentId,
          );
          return TranslationResult(
            translated: apertium.trim(),
            engineUsed: TranslationEngineId.apertiumCli,
            fallbackUsed: false,
          );
        }

        final llmFallback = await _translateWithPrompt(
          text: clean,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );
        await _cacheRepository.upsert(
          artifactType: artifactType,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          sourceText: clean,
          translatedText: llmFallback,
          engineId: TranslationEngineId.llmPromptTranslator.name,
          fallbackUsed: true,
          contentId: contentId,
        );
        return TranslationResult(
          translated: llmFallback,
          engineUsed: TranslationEngineId.llmPromptTranslator,
          fallbackUsed: true,
        );
      case TranslationEngineId.llmPromptTranslator:
        final llm = await _translateWithPrompt(
          text: clean,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );
        await _cacheRepository.upsert(
          artifactType: artifactType,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          sourceText: clean,
          translatedText: llm,
          engineId: TranslationEngineId.llmPromptTranslator.name,
          fallbackUsed: false,
          contentId: contentId,
        );
        return TranslationResult(
          translated: llm,
          engineUsed: TranslationEngineId.llmPromptTranslator,
          fallbackUsed: false,
        );
      case TranslationEngineId.argosTranslate:
      case TranslationEngineId.indicTrans2:
      case TranslationEngineId.nllb200Distilled600m:
      case TranslationEngineId.m2m100418m:
      case TranslationEngineId.opusMtEnKn:
      case TranslationEngineId.ai4bharatIndictrans2:
        final llmFallback = await _translateWithPrompt(
          text: clean,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );
        await _cacheRepository.upsert(
          artifactType: artifactType,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          sourceText: clean,
          translatedText: llmFallback,
          engineId: TranslationEngineId.llmPromptTranslator.name,
          fallbackUsed: true,
          contentId: contentId,
        );
        return TranslationResult(
          translated: llmFallback,
          engineUsed: TranslationEngineId.llmPromptTranslator,
          fallbackUsed: true,
        );
    }
  }

  Future<String?> _translateWithApertium({
    required String text,
    required String sourceLang,
    required String targetLang,
    required String executable,
  }) async {
    if (!Platform.isLinux) {
      return null;
    }

    final pair = _apertiumPair(sourceLang: sourceLang, targetLang: targetLang);
    if (pair == null) {
      return null;
    }

    try {
      final process = await Process.start(
        executable,
        <String>[pair],
        runInShell: true,
      );

      process.stdin.writeln(text);
      await process.stdin.flush();
      await process.stdin.close();

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      final out = await stdoutFuture;
      await stderrFuture;

      if (exitCode != 0) {
        return null;
      }

      if (out.trim().isNotEmpty) {
        return out;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String? _apertiumPair({
    required String sourceLang,
    required String targetLang,
  }) {
    final source = sourceLang.toLowerCase();
    final target = targetLang.toLowerCase();

    if (source == 'en' && target == 'kn') {
      return 'eng-kan';
    }
    if (source == 'kn' && target == 'en') {
      return 'kan-eng';
    }

    return null;
  }

  Future<String> _translateWithPrompt({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final prompt = '''
You are an offline translation engine.
Translate the text from ${_langName(sourceLang)} to ${_langName(targetLang)}.
Rules:
1. Keep meaning exact.
2. Preserve numbers, formulas, units, and symbols.
3. Return only translated text, no explanations.

Text:
$text
''';

    final buffer = StringBuffer();
    await for (final chunk in _gateway.streamResponse(prompt: prompt)) {
      final trimmed = chunk.trimLeft();
      if (trimmed.startsWith('{"type":"metrics"')) {
        continue;
      }
      buffer.write(chunk);
    }

    final translated = buffer.toString().trim();
    return translated.isEmpty ? text : translated;
  }

  String _langName(String code) {
    switch (code.toLowerCase()) {
      case 'kn':
        return 'Kannada';
      case 'en':
      default:
        return 'English';
    }
  }
}
