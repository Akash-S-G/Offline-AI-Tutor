import '../../experiment/domain/models/experiment_models.dart';
import '../../experiment/domain/enums/experiment_enums.dart';
import '../../experiment/builder/templates/experiment_templates.dart';
import 'curriculum_models.dart';

class CurriculumExperimentMapper {
  static List<Map<String, dynamic>> getExperimentsForChapter(CurriculumChapter chapter, CurriculumSubject subject) {
    final title = chapter.title.toLowerCase();
    
    // Exact or keyword matching
    if (title.contains('force') || title.contains('pressure') || title.contains('gravity')) {
      return [ExperimentTemplates.freeFall];
    }
    if (title.contains('motion') || title.contains('harmonic') || title.contains('oscillation')) {
      return [ExperimentTemplates.pendulum];
    }
    if (title.contains('plant') || title.contains('botany')) {
      return [ExperimentTemplates.plantGrowth];
    }
    if (title.contains('water') || title.contains('cycle') || title.contains('environment')) {
      return [ExperimentTemplates.waterCycle];
    }

    // Default or empty
    return [];
  }

  static ExperimentManifest mapTemplateToManifest(Map<String, dynamic> template, {String chapterId = 'general'}) {
    final metadata = template['metadata'] as Map<String, dynamic>? ?? {};
    final scene = template['scene'] as Map<String, dynamic>? ?? {};
    
    final category = metadata['category'] ?? 'general';
    final difficultyStr = metadata['difficulty'] ?? 'Medium';
    
    ExperimentDifficulty difficulty = ExperimentDifficulty.medium;
    if (difficultyStr.toString().toLowerCase() == 'easy') difficulty = ExperimentDifficulty.easy;
    if (difficultyStr.toString().toLowerCase() == 'hard') difficulty = ExperimentDifficulty.hard;

    return ExperimentManifest(
      id: scene['sceneId'] ?? 'unknown_id',
      title: scene['name'] ?? 'Untitled Experiment',
      description: scene['description'] ?? 'No description provided.',
      subject: metadata['subject'] ?? category.toString().toUpperCase(),
      grade: metadata['grade'] ?? 'General',
      chapter: chapterId,
      topic: category,
      difficulty: difficulty,
      requiredSensors: [], // We could parse from objects if needed
      supportedModes: [ExperimentExecutionMode.simulation],
      steps: [], // No explicit steps in templates yet
      visualizations: [],
      estimatedDurationMinutes: int.tryParse(metadata['estimatedTime']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '15') ?? 15,
      supportsSimulation: true,
      supportsSensorExecution: false,
      supportsObservationMode: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
