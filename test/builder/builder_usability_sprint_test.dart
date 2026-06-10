import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_tutor_app/features/experiment/builder/controllers/experiment_builder_controller.dart';
import 'package:offline_tutor_app/features/experiment/builder/data/api/experiment_manifest_api_service.dart';
import 'package:offline_tutor_app/features/experiment/builder/data/repositories/experiment_manifest_repository.dart';
import 'package:offline_tutor_app/features/experiment/builder/models/builder_rule.dart';
import 'package:offline_tutor_app/features/experiment/builder/models/builder_scene.dart';
import 'package:offline_tutor_app/features/experiment/builder/models/builder_variable.dart';
import 'package:offline_tutor_app/features/experiment/builder/models/experiment_builder_state.dart';
import 'package:offline_tutor_app/features/experiment/builder/storage/builder_draft.dart';
import 'package:offline_tutor_app/features/experiment/builder/storage/builder_draft_manager.dart';
import 'package:offline_tutor_app/features/experiment/builder/storage/builder_draft_repository.dart';
import 'package:offline_tutor_app/features/experiment/builder/templates/experiment_templates.dart';
import 'package:offline_tutor_app/features/experiment/builder/validation/builder_validator.dart';
import 'package:offline_tutor_app/features/experiment/builder/widgets/builder_search_bar.dart';
import 'package:offline_tutor_app/features/experiment/builder/widgets/experiment_summary_card.dart';
import 'package:offline_tutor_app/features/experiment/builder/widgets/launch_readiness_card.dart';
import 'package:offline_tutor_app/features/experiment/builder/widgets/variable_editor.dart';
import 'package:offline_tutor_app/features/network/domain/backend_config.dart';

void main() {
  group('builder usability sprint', () {
    test('template import populates builder state and report', () {
      final controller = _controller();

      for (final template in ExperimentTemplates.allTemplates) {
        controller.importTemplate(template);

        expect(controller.state.variables.length, greaterThan(0));
        expect(controller.state.objects.length, greaterThan(0));
        expect(controller.state.rules.length, greaterThan(0));
        expect(controller.lastTemplateImportReport?.populated, isTrue);
      }
      expect(
        controller.analytics.templatesImported,
        ExperimentTemplates.allTemplates.length,
      );

      controller.dispose();
    });

    test('summary card model updates from state', () {
      final summary = ExperimentSummaryCard.summarize(
        _state(
          variables: [
            _variable('var_accel_1', 'Accelerometer', 'accelerometer', {}),
            _variable('var_temp', 'Temperature', 'numberInput', 25),
          ],
          rules: [_rule('rule_1', 'var_temp')],
        ),
      );

      expect(summary.variables, 2);
      expect(summary.rules, 1);
      expect(summary.sensors, 1);
    });

    test('readiness card reflects validation state', () {
      final ready = LaunchReadinessCard.fromValidation(
        BuilderValidator().validate(
          _state(
            variables: [
              _variable('var_temp', 'Temperature', 'numberInput', 25),
            ],
            rules: [_rule('rule_1', 'var_temp')],
          ),
        ),
      );
      final warning = LaunchReadinessCard.fromValidation(
        BuilderValidator().validate(
          _state(
            variables: [
              _variable('var_temp', 'Temperature', 'numberInput', 25),
            ],
            rules: [_rule('rule_1', 'var_missing')],
          ),
        ),
      );

      expect(ready.level, LaunchReadinessLevel.ready);
      expect(warning.level, LaunchReadinessLevel.warning);
    });

    test('search filtering works for variables and rules', () {
      final variables = [
        _variable('var_temp', 'Temperature', 'numberInput', 25),
        _variable('var_speed', 'Speed', 'numberInput', 1),
      ];
      final rules = [
        _rule('rule_temp', 'var_temp', name: 'Temperature Warning'),
        _rule('rule_speed', 'var_speed', name: 'Speed Warning'),
      ];

      final filteredVariables = BuilderSearchBar.filter(
        variables,
        'temp',
        (variable) => [variable.name, variable.id, variable.type],
      );
      final filteredRules = BuilderSearchBar.filter(
        rules,
        'speed',
        (rule) => [rule.name, rule.id, rule.trigger],
      );

      expect(filteredVariables.single.id, 'var_temp');
      expect(filteredRules.single.id, 'rule_speed');
    });

    testWidgets('large variable list remains scrollable', (tester) async {
      final controller = _controller();
      for (var i = 1; i <= 50; i++) {
        controller.addVariable(
          _variable('var_$i', 'Variable $i', 'numberInput', i),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 640,
              child: VariableEditor(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Variable 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Variable 50'),
        500,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Variable 50'), findsOneWidget);

      controller.dispose();
    });
  });
}

ExperimentBuilderController _controller() {
  final config = BackendConfig(baseUrl: 'http://localhost', apiKey: 'test');
  return ExperimentBuilderController(
    draftManager: BuilderDraftManager(_MemoryDraftRepository()),
    manifestRepository: ExperimentManifestRepositoryImpl(
      ExperimentManifestApiService(config),
    ),
  );
}

ExperimentBuilderState _state({
  required List<BuilderVariable> variables,
  List<BuilderRule> rules = const [],
}) {
  return ExperimentBuilderState(
    scene: BuilderScene(
      id: 'ux_scene',
      name: 'UX Scene',
      description: 'Builder UX test scene',
      tags: const ['ux'],
    ),
    variables: variables,
    objects: const [],
    rules: rules,
  );
}

BuilderVariable _variable(String id, String name, String type, dynamic value) {
  return BuilderVariable(
    id: id,
    name: name,
    type: type,
    defaultValue: value,
    description: name,
  );
}

BuilderRule _rule(String id, String variableId, {String name = 'Rule'}) {
  return BuilderRule(
    id: id,
    name: name,
    trigger: 'thresholdCrossed',
    condition: {'variableId': variableId, 'operator': '>', 'value': 10},
    actions: [
      {'type': 'show_warning', 'message': 'Warning'},
    ],
  );
}

class _MemoryDraftRepository implements BuilderDraftRepository {
  final List<BuilderDraft> _drafts = [];

  @override
  Future<void> deleteDraft(String draftId) async {
    _drafts.removeWhere((draft) => draft.draftId == draftId);
  }

  @override
  Future<List<BuilderDraft>> getDrafts() async => List.of(_drafts);

  @override
  Future<void> saveDraft(BuilderDraft draft) async {
    final index = _drafts.indexWhere((item) => item.draftId == draft.draftId);
    if (index >= 0) {
      _drafts[index] = draft;
    } else {
      _drafts.add(draft);
    }
  }
}
