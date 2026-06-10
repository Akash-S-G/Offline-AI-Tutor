class BuilderAnalytics {
  final int templatesImported;
  final int builderLaunchAttempts;
  final int validationWarnings;
  final int validationErrors;
  final int builderEntitiesCreated;

  const BuilderAnalytics({
    this.templatesImported = 0,
    this.builderLaunchAttempts = 0,
    this.validationWarnings = 0,
    this.validationErrors = 0,
    this.builderEntitiesCreated = 0,
  });

  BuilderAnalytics copyWith({
    int? templatesImported,
    int? builderLaunchAttempts,
    int? validationWarnings,
    int? validationErrors,
    int? builderEntitiesCreated,
  }) {
    return BuilderAnalytics(
      templatesImported: templatesImported ?? this.templatesImported,
      builderLaunchAttempts:
          builderLaunchAttempts ?? this.builderLaunchAttempts,
      validationWarnings: validationWarnings ?? this.validationWarnings,
      validationErrors: validationErrors ?? this.validationErrors,
      builderEntitiesCreated:
          builderEntitiesCreated ?? this.builderEntitiesCreated,
    );
  }
}

class TemplateImportReport {
  final String templateName;
  final int variables;
  final int objects;
  final int rules;

  const TemplateImportReport({
    required this.templateName,
    required this.variables,
    required this.objects,
    required this.rules,
  });

  bool get populated => variables > 0 && objects > 0 && rules > 0;
}
