import '../builder/templates/experiment_templates.dart';
import '../runtime/runtime_loader.dart';
import '../runtime/runtime_world.dart';

class RuntimeTemplateCertification {
  final String templateName;
  final bool manifestLoaded;
  final bool objectsCreated;
  final bool variablesCreated;
  final bool rulesLoaded;
  final bool runtimeStarted;
  final bool simulationVisible;
  final bool eventsReceived;
  final bool noRuntimeExceptions;
  final int objectCount;
  final int variableCount;
  final int ruleCount;
  final int eventCount;
  final String? failureReason;

  const RuntimeTemplateCertification({
    required this.templateName,
    required this.manifestLoaded,
    required this.objectsCreated,
    required this.variablesCreated,
    required this.rulesLoaded,
    required this.runtimeStarted,
    required this.simulationVisible,
    required this.eventsReceived,
    required this.noRuntimeExceptions,
    required this.objectCount,
    required this.variableCount,
    required this.ruleCount,
    required this.eventCount,
    this.failureReason,
  });

  bool get passed =>
      manifestLoaded &&
      objectsCreated &&
      variablesCreated &&
      rulesLoaded &&
      runtimeStarted &&
      simulationVisible &&
      noRuntimeExceptions;
}

class RuntimeCertificationService {
  const RuntimeCertificationService();

  List<RuntimeTemplateCertification> certifyBuiltInTemplates() {
    return ExperimentTemplates.allTemplates.map(certifyTemplate).toList();
  }

  RuntimeTemplateCertification certifyTemplate(Map<String, dynamic> template) {
    final scene = template['scene'] as Map<String, dynamic>? ?? {};
    final templateName = scene['name']?.toString() ?? 'Untitled Template';

    RuntimeWorld? world;
    try {
      world = RuntimeLoader.loadFromManifest(template);
      world.clock.start();
      world.tick(1 / 60);
      final eventCount =
          world.analytics.ruleExecutions +
          world.analytics.variableUpdates +
          world.analytics.launches;

      return RuntimeTemplateCertification(
        templateName: templateName,
        manifestLoaded: template.containsKey('scene'),
        objectsCreated: world.objects.allObjects.isNotEmpty,
        variablesCreated: world.variables.allVariables.isNotEmpty,
        rulesLoaded: world.rules.allRules.isNotEmpty,
        runtimeStarted: world.clock.isRunning,
        simulationVisible: world.objects.allObjects.isNotEmpty,
        eventsReceived: eventCount > 0,
        noRuntimeExceptions: true,
        objectCount: world.objects.allObjects.length,
        variableCount: world.variables.allVariables.length,
        ruleCount: world.rules.allRules.length,
        eventCount: eventCount,
      );
    } catch (error) {
      return RuntimeTemplateCertification(
        templateName: templateName,
        manifestLoaded: template.containsKey('scene'),
        objectsCreated: false,
        variablesCreated: false,
        rulesLoaded: false,
        runtimeStarted: false,
        simulationVisible: false,
        eventsReceived: false,
        noRuntimeExceptions: false,
        objectCount: 0,
        variableCount: 0,
        ruleCount: 0,
        eventCount: 0,
        failureReason: error.toString(),
      );
    } finally {
      world?.dispose();
    }
  }
}
