enum TranslationEngineId {
  apertiumCli,
  llmPromptTranslator,
  argosTranslate,
  indicTrans2,
  nllb200Distilled600m,
  m2m100418m,
  opusMtEnKn,
  ai4bharatIndictrans2,
}

class TranslationEngineOption {
  const TranslationEngineOption({
    required this.id,
    required this.label,
    required this.description,
    required this.supportsKannada,
    required this.offlineCapable,
    required this.implementedInApp,
  });

  final TranslationEngineId id;
  final String label;
  final String description;
  final bool supportsKannada;
  final bool offlineCapable;
  final bool implementedInApp;
}

class TranslationEngineCatalog {
  static const List<TranslationEngineOption> all = <TranslationEngineOption>[
    TranslationEngineOption(
      id: TranslationEngineId.apertiumCli,
      label: 'Apertium CLI',
      description: 'Rule-based local engine via system binary (fast, low power).',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: true,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.llmPromptTranslator,
      label: 'LLM Prompt Translator',
      description: 'Uses tutor model as translation backend (fallback path).',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: true,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.argosTranslate,
      label: 'Argos Translate',
      description: 'Offline NMT using installed Argos package files.',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.indicTrans2,
      label: 'IndicTrans2',
      description: 'High-quality Indian language NMT (CTranslate2 runtime).',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.nllb200Distilled600m,
      label: 'NLLB-200 Distilled 600M',
      description: 'Meta multilingual model for en<->kn translation.',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.m2m100418m,
      label: 'M2M100 418M',
      description: 'Multilingual translation model for many language pairs.',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.opusMtEnKn,
      label: 'OPUS-MT en-kn',
      description: 'Pair-specific Marian/OPUS model for English-Kannada.',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
    TranslationEngineOption(
      id: TranslationEngineId.ai4bharatIndictrans2,
      label: 'AI4Bharat IndicTrans2',
      description: 'Indian language focused model family (research-grade quality).',
      supportsKannada: true,
      offlineCapable: true,
      implementedInApp: false,
    ),
  ];

  static List<TranslationEngineOption> kannadaEngines() {
    return all.where((engine) => engine.supportsKannada).toList(growable: false);
  }

  static TranslationEngineOption byId(TranslationEngineId id) {
    return all.firstWhere((item) => item.id == id);
  }

  static TranslationEngineId parseId(String value) {
    for (final option in all) {
      if (option.id.name == value) {
        return option.id;
      }
    }
    return TranslationEngineId.apertiumCli;
  }
}
