import '../../builder/templates/experiment_templates.dart';
import '../models/experiment_blueprint.dart';
import '../models/experiment_category.dart';
import '../models/experiment_objective.dart';
import '../models/experiment_observation_template.dart';
import '../models/experiment_parameter.dart';
import '../models/experiment_question.dart';

class BuiltInBlueprints {
  static List<ExperimentBlueprint> all() {
    return [
      _fromTemplate(
        ExperimentTemplates.freeFall,
        id: 'blueprint_free_fall',
        visualPreset: 'freeFall',
        topic: 'Gravity',
        objectives: const [
          ExperimentObjective(
            title: 'Observe acceleration',
            description: 'Identify how acceleration changes during free fall.',
          ),
        ],
        parameters: const [],
        questions: const [
          ExperimentQuestion(
            id: 'free_fall_prediction',
            type: QuestionType.prediction,
            question: 'What do you expect acceleration to do during a drop?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Time', 'Acceleration'],
          requiredRows: 3,
        ),
      ),
      _fromTemplate(
        ExperimentTemplates.pendulum,
        id: 'blueprint_pendulum',
        visualPreset: 'pendulum',
        topic: 'Periodic Motion',
        objectives: const [
          ExperimentObjective(
            title: 'Understand length and period',
            description: 'Explore how pendulum settings affect motion.',
          ),
        ],
        parameters: const [
          ExperimentParameter(
            id: 'param_angle',
            displayName: 'Angle',
            variableId: 'var_angle',
            unit: 'deg',
            minValue: 0,
            maxValue: 90,
            defaultValue: 45,
            description: 'Initial pendulum angle.',
          ),
        ],
        questions: const [
          ExperimentQuestion(
            id: 'pendulum_prediction',
            type: QuestionType.prediction,
            question:
                'If the angle increases, what do you predict will happen?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Angle', 'Observation'],
          requiredRows: 2,
        ),
      ),
      _fromTemplate(
        ExperimentTemplates.heartRate,
        id: 'blueprint_heart_rate',
        visualPreset: 'heartRate',
        topic: 'Human Body',
        objectives: const [
          ExperimentObjective(
            title: 'Measure pulse',
            description: 'Record and interpret pulse readings.',
          ),
        ],
        parameters: const [
          ExperimentParameter(
            id: 'param_pulse',
            displayName: 'Pulse',
            variableId: 'heart_rate',
            unit: 'bpm',
            minValue: 40,
            maxValue: 180,
            defaultValue: 70,
          ),
        ],
        questions: const [
          ExperimentQuestion(
            id: 'heart_rate_observation',
            type: QuestionType.observation,
            question: 'What pulse range did you observe?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Pulse', 'Condition'],
          requiredRows: 2,
        ),
      ),
      _fromTemplate(
        ExperimentTemplates.plantGrowth,
        id: 'blueprint_plant_growth',
        visualPreset: 'plantGrowth',
        topic: 'Plants',
        objectives: const [
          ExperimentObjective(
            title: 'Compare growth inputs',
            description: 'Explore how water and sunlight affect plant growth.',
          ),
        ],
        parameters: const [
          ExperimentParameter(
            id: 'param_water',
            displayName: 'Water',
            variableId: 'water',
            unit: '%',
            minValue: 0,
            maxValue: 100,
            defaultValue: 50,
          ),
          ExperimentParameter(
            id: 'param_sunlight',
            displayName: 'Sunlight',
            variableId: 'sunlight',
            unit: '%',
            minValue: 0,
            maxValue: 100,
            defaultValue: 50,
          ),
        ],
        questions: const [
          ExperimentQuestion(
            id: 'plant_prediction',
            type: QuestionType.prediction,
            question: 'Which input do you think affects growth most?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Water', 'Sunlight', 'Growth'],
          requiredRows: 3,
        ),
      ),
      _fromTemplate(
        ExperimentTemplates.waterCycle,
        id: 'blueprint_water_cycle',
        visualPreset: 'waterCycle',
        topic: 'Water Cycle',
        objectives: const [
          ExperimentObjective(
            title: 'Connect temperature to evaporation',
            description:
                'Observe how temperature changes water cycle behavior.',
          ),
        ],
        parameters: const [
          ExperimentParameter(
            id: 'param_temperature',
            displayName: 'Temperature',
            variableId: 'temperature',
            unit: 'C',
            minValue: 0,
            maxValue: 100,
            defaultValue: 25,
          ),
        ],
        questions: const [
          ExperimentQuestion(
            id: 'water_cycle_prediction',
            type: QuestionType.prediction,
            question: 'What happens to evaporation when temperature rises?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Temperature', 'Water Cycle Stage'],
          requiredRows: 2,
        ),
      ),
      _fromTemplate(
        ExperimentTemplates.circuit,
        id: 'blueprint_circuit',
        visualPreset: 'circuit',
        topic: 'Electricity',
        objectives: const [
          ExperimentObjective(
            title: 'Understand Ohm\'s Law',
            description: 'Explore the relationship between voltage, resistance, and current.',
          ),
        ],
        parameters: const [
          ExperimentParameter(
            id: 'param_voltage',
            displayName: 'Voltage',
            variableId: 'var_voltage',
            unit: 'V',
            minValue: 1,
            maxValue: 9,
            defaultValue: 1,
          ),
          ExperimentParameter(
            id: 'param_resistance',
            displayName: 'Resistance',
            variableId: 'var_resistance',
            unit: 'Ω',
            minValue: 10,
            maxValue: 50,
            defaultValue: 10,
          ),
        ],
        questions: const [
          ExperimentQuestion(
            id: 'circuit_prediction',
            type: QuestionType.prediction,
            question: 'What happens to the current when voltage increases?',
          ),
        ],
        observationTemplate: const ExperimentObservationTemplate(
          columns: ['Voltage', 'Resistance', 'Current'],
          requiredRows: 3,
        ),
      ),
    ];
  }

  static ExperimentBlueprint _fromTemplate(
    Map<String, dynamic> template, {
    required String id,
    required String visualPreset,
    required String topic,
    required List<ExperimentObjective> objectives,
    required List<ExperimentParameter> parameters,
    required List<ExperimentQuestion> questions,
    required ExperimentObservationTemplate observationTemplate,
  }) {
    final metadata = template['metadata'] as Map<String, dynamic>? ?? const {};
    final scene = template['scene'] as Map<String, dynamic>? ?? const {};
    return ExperimentBlueprint(
      id: id,
      name: scene['name']?.toString() ?? id,
      subject: metadata['subject']?.toString() ?? 'Science',
      topic: topic,
      description: scene['description']?.toString() ?? '',
      grade: metadata['grade']?.toString() ?? 'General',
      difficulty: metadata['difficulty']?.toString() ?? 'Medium',
      estimatedTime: metadata['estimatedTime']?.toString() ?? '15 mins',
      visualPreset: visualPreset,
      category: experimentCategoryFromString(metadata['category']?.toString()),
      objectives: objectives,
      parameters: parameters,
      questions: questions,
      observationTemplate: observationTemplate,
      manifest: Map<String, dynamic>.from(template),
    );
  }
}
