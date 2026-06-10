# Runtime-Aware Builder Rules Certification Report

Generated: 2026-06-10

## Scope

This report certifies Sprint 18: Runtime-Aware Rule Authoring.

Goal:

```text
Every runtime rule capability must be authorable from the Builder UI.
```

Implemented in this sprint:

- First-class `BuilderRule.trigger`.
- First-class `BuilderRule.actions`.
- Compatibility `BuilderRule.action` getter for older call sites.
- Rule trigger dropdown.
- Structured condition editor.
- Multi-action editor with add, delete, and reorder controls.
- Centralized builder rule action registry.
- Builder validation for trigger, condition, action targets, and action parameters.
- Rule dependency graph widget.
- Runtime execution preview rule summary.
- Runtime Inspector `Rule Runtime` section.
- Runtime analytics for builder rule health.
- Built-in builder templates migrated away from `trigger: any`.

Out of scope:

- Compound AND/OR condition authoring.
- Rule groups.
- Expression language authoring.
- Backend schema migration.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| BuilderRule model extended | PASS | `lib/features/experiment/builder/models/builder_rule.dart` |
| Trigger persisted | PASS | `trigger` emitted in `BuilderRule.toJson()` |
| Action list persisted | PASS | `actions` emitted in `BuilderRule.toJson()` |
| Runtime config preserved | PASS | `runtimeConfig.trigger`, `runtimeConfig.condition`, `runtimeConfig.actions` |
| Trigger dropdown added | PASS | `RuleTriggerDropdown` |
| Structured condition editor | PASS | `ConditionBuilderEditor` |
| Multi-action editor | PASS | `ActionBuilderEditor` |
| Add/delete/reorder actions | PASS | Action editor controls |
| Rule action registry | PASS | `lib/features/experiment/builder/domain/rule_action_registry.dart` |
| Builder validation upgraded | PASS | `BuilderValidator` |
| Dependency graph added | PASS | `rule_dependency_graph.dart` |
| Execution preview upgraded | PASS | `BuilderExecutionPreviewPanel` |
| Runtime Inspector upgraded | PASS | `ExperimentPlayerScreen` |
| Runtime analytics upgraded | PASS | `RuntimeAnalytics` |
| Builder templates use registered triggers/actions | PASS | `experiment_templates.dart` |

## Certified Runtime Rule Format

```json
{
  "ruleId": "rule_temp",
  "name": "Temperature Warning",
  "type": "runtime",
  "trigger": "thresholdCrossed",
  "condition": {
    "variableId": "var_temp",
    "operator": ">",
    "value": 80
  },
  "actions": [
    {
      "type": "show_warning",
      "message": "Temperature too high"
    },
    {
      "type": "hide_object",
      "objectId": "obj_heater"
    }
  ],
  "runtimeConfig": {
    "trigger": "thresholdCrossed",
    "condition": {},
    "actions": []
  }
}
```

The legacy single `action` field is still emitted for compatibility and points to the first action.

## Trigger Authoring

Certified trigger values:

- `variableChanged`
- `thresholdCrossed`
- `buttonPressed`
- `toggleChanged`
- `intervalTriggered`
- `countdownFinished`
- `experimentStarted`
- `experimentPaused`
- `experimentCompleted`

## Action Authoring

Certified action types:

- `show_warning`
- `hide_object`
- `show_object`
- `set_variable`
- `toggle_variable`

`set_variable` and `toggle_variable` support both `variableId` and Sprint 18 `targetVariable` payloads.

## Validation Certified

Builder validation now rejects:

- Unknown trigger.
- Missing condition variable.
- Missing condition operator.
- Missing condition value.
- Unknown action type.
- Empty warning message.
- Missing hide/show object target.
- Missing set-variable target.
- Missing set-variable value.
- Missing toggle-variable target.
- Toggle action targeting a non-boolean variable.

## Dependency Graph

Certified output shape:

```text
Temperature
  ↓
Runtime Rule
  ↓
show_warning -> Too hot
```

## Runtime Inspector

Runtime Inspector now displays:

```text
Rule Runtime
Rule Name
Trigger
Condition
Actions
Fired count
Last fired/evaluated time
```

## Analytics Certified

Added counters:

- `builderRulesLoaded`
- `builderRulesValidated`
- `builderRuleValidationFailures`
- `builderActionsConfigured`

## Automated Tests

Automated test file:

```text
test/experiment/runtime_aware_builder_rules_test.dart
```

Certified cases:

| Test | Result |
| --- | --- |
| Draft persistence preserves runtime rule config | PASS |
| Trigger persistence survives manifest and runtime load | PASS |
| Manifest generation preserves multi-action rules | PASS |
| Validation detects missing variable and object references | PASS |
| Validation accepts valid multi-action rule | PASS |
| Validation rejects unknown trigger and missing set value | PASS |
| Dependency graph produces variable/rule/action chain | PASS |
| Validation rejects toggle_variable for non-boolean variable | PASS |
| Runtime launch fires multi-action rule correctly | PASS |

## Verification Commands

```text
dart format
```

Result: PASS.

```text
flutter analyze lib/features/experiment/builder/models/builder_rule.dart lib/features/experiment/builder/domain/rule_action_registry.dart lib/features/experiment/builder/widgets/rule_runtime_config_editors.dart lib/features/experiment/builder/widgets/rule_dependency_graph.dart lib/features/experiment/builder/wizards/rule_wizard_dialog.dart lib/features/experiment/builder/widgets/rule_editor.dart lib/features/experiment/builder/validation/builder_validator.dart lib/features/experiment/builder/widgets/builder_execution_preview_panel.dart lib/features/experiment/builder/controllers/experiment_builder_controller.dart lib/features/experiment/runtime/runtime_analytics.dart lib/features/experiment/runtime/rules/runtime_rule.dart lib/features/experiment/runtime/rules/runtime_rule_engine.dart lib/features/experiment/runtime/rules/runtime_action_dispatcher.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart test/experiment/runtime_aware_builder_rules_test.dart
```

Result: PASS, no issues found.

Focused analyze was also rerun with `experiment_templates.dart` included.

```text
flutter test test/experiment/runtime_aware_builder_rules_test.dart
```

Result: PASS, 9 tests passed.

```text
flutter test test/experiment/runtime_aware_builder_rules_test.dart test/experiment/runtime_aware_builder_variables_test.dart test/experiment/runtime_aware_builder_objects_test.dart test/experiment/runtime_rule_system_test.dart
```

Result: PASS, 25 tests passed.

## Known Limitations

- Conditions remain single-condition rules.
- `thresholdCrossed`, `intervalTriggered`, and `countdownFinished` are authored exactly and map onto existing runtime variable-change evaluation.
- `buttonPressed` is authored exactly and maps onto existing runtime object-interaction evaluation.
- Experiment lifecycle triggers are persisted and visible, but lifecycle-trigger dispatch is still limited by existing runtime event support.

## Certification Decision

PASS.

Builder ↔ Runtime parity for rule authoring is certified.
