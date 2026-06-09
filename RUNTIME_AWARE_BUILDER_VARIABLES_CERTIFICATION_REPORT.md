# Runtime-Aware Builder Variables Certification Report

Generated: 2026-06-10

## Scope

This report certifies Sprint 15B: Runtime-Aware Variable Authoring.

Implemented in this sprint:

- `BuilderVariable.runtimeConfig`.
- Runtime config serialization through variable JSON.
- Runtime config persistence through drafts.
- Runtime config propagation into generated manifests.
- Runtime config propagation into runtime variable metadata.
- Timer variable config editors.
- Computed variable config editors.
- Dependency tree preview.
- Dependency validation.
- Circular dependency detection.
- Execution preview variable runtime validation.
- Runtime inspector computed variable details.

Out of scope:

- Sensor variable implementation.
- Runtime-aware rule/action authoring.
- Visual formula graph library.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| `BuilderVariable.runtimeConfig` added | PASS | `lib/features/experiment/builder/models/builder_variable.dart` |
| Variable config survives `toJson()` | PASS | Runtime config is emitted as `runtimeConfig` and top-level manifest metadata |
| Variable config survives `fromJson()` | PASS | Direct and legacy metadata extraction supported |
| Draft save/load preserves config | PASS | `BuilderDraft` round-trip test |
| Manifest generation preserves config | PASS | `ExperimentBuilderState.generateManifestJson()` uses `BuilderVariable.toJson()` |
| Runtime launch consumes config | PASS | Runtime computed variables evaluate from builder-authored config |
| Elapsed time editor created | PASS | `ElapsedTimeVariableEditor` |
| Countdown editor created | PASS | `CountdownVariableEditor` |
| Interval editor created | PASS | `IntervalVariableEditor` |
| Average editor created | PASS | `MultiDependencyVariableEditor` |
| Minimum editor created | PASS | `MultiDependencyVariableEditor` |
| Maximum editor created | PASS | `MultiDependencyVariableEditor` |
| Distance editor created | PASS | `PairDependencyVariableEditor` |
| Velocity editor created | PASS | `PairDependencyVariableEditor` |
| Acceleration editor created | PASS | `PairDependencyVariableEditor` |
| Force editor created | PASS | `PairDependencyVariableEditor` |
| Power editor created | PASS | `PairDependencyVariableEditor` |
| Energy editor created | PASS | `PairDependencyVariableEditor` |
| Dependency tree preview added | PASS | `DependencyTreePreview` |
| Builder validation extended | PASS | `BuilderValidator` |
| Cycle detection added | PASS | `BuilderValidator._dependencyCycles()` |
| Execution preview updated | PASS | `Variable Runtime Validation` section |
| Runtime inspector updated | PASS | Computed Variables now show formula, dependency count, and current value |

## Config Formats Certified

Elapsed Time:

```json
{
  "startValue": 0
}
```

Countdown:

```json
{
  "startValue": 60,
  "autoStart": true
}
```

Interval:

```json
{
  "intervalSeconds": 1
}
```

Average / Minimum / Maximum:

```json
{
  "dependencies": ["var_a", "var_b"]
}
```

Distance:

```json
{
  "speedVariable": "var_speed",
  "timeVariable": "var_time"
}
```

Velocity:

```json
{
  "distanceVariable": "var_distance",
  "timeVariable": "var_time"
}
```

Acceleration:

```json
{
  "velocityVariable": "var_velocity",
  "timeVariable": "var_time"
}
```

Force:

```json
{
  "massVariable": "var_mass",
  "accelerationVariable": "var_acceleration"
}
```

Power:

```json
{
  "forceVariable": "var_force",
  "velocityVariable": "var_velocity"
}
```

Energy:

```json
{
  "powerVariable": "var_power",
  "timeVariable": "var_time"
}
```

## Validation Certified

Builder validation now checks:

- Countdown `startValue > 0`.
- Interval `intervalSeconds > 0`.
- Average/minimum/maximum have at least 2 dependencies.
- Formula dependencies exist.
- Direct dependency cycles are rejected.
- Multi-hop dependency cycles are rejected.

Example certified error:

```text
Force variable references missing variable var_mass
```

Example certified cycle:

```text
Circular dependency detected: var_a -> var_b -> var_a
```

## Runtime Compatibility

Runtime power support was aligned with the Sprint 15B builder contract:

```text
power = force x velocity
```

Affected files:

- `runtime_variable_dependencies.dart`
- `runtime_variable_executor.dart`

## Runtime Inspector

Computed variables now show:

```text
Formula
Dependencies
Current Value
Dependency IDs
Last Updated
```

Example:

```text
Force
Formula: mass x acceleration
Dependencies: 2
Current Value: 25
```

## Certification Experiments

### Force Calculator

Variables:

```text
Mass
Acceleration
Force
```

Expected:

```text
Force updates automatically.
```

Result: PASS.

### Distance Calculator

Variables:

```text
Speed
ElapsedTime
Distance
```

Expected:

```text
Distance grows continuously.
```

Result: PASS.

### Energy Calculator

Variables:

```text
Power
ElapsedTime
Energy
```

Expected:

```text
Energy accumulates.
```

Result: PASS.

## Automated Tests

Automated test file:

```text
test/experiment/runtime_aware_builder_variables_test.dart
```

Certified cases:

| Test | Result |
| --- | --- |
| Draft persistence preserves variable runtime config | PASS |
| Manifest generation preserves computed variable config | PASS |
| Dependency validation detects missing dependency | PASS |
| Dependency validation detects circular dependency | PASS |
| Runtime launch computes force from builder-authored config | PASS |
| Runtime launch computes distance and energy from config | PASS |
| Runtime launch computes power from force and velocity config | PASS |

## Verification Commands

```text
dart format lib/features/experiment/builder/models/builder_variable.dart lib/features/experiment/builder/controllers/experiment_builder_controller.dart lib/features/experiment/builder/widgets/variable_runtime_config_editors.dart lib/features/experiment/builder/wizards/variable_wizard_dialog.dart lib/features/experiment/builder/widgets/variable_editor.dart lib/features/experiment/builder/validation/builder_validator.dart lib/features/experiment/builder/widgets/builder_execution_preview_panel.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart lib/features/experiment/runtime/variables/runtime_variable_dependencies.dart lib/features/experiment/runtime/variables/runtime_variable_executor.dart test/experiment/runtime_aware_builder_variables_test.dart
```

Result: PASS.

```text
flutter analyze lib/features/experiment/builder/models/builder_variable.dart lib/features/experiment/builder/controllers/experiment_builder_controller.dart lib/features/experiment/builder/widgets/variable_runtime_config_editors.dart lib/features/experiment/builder/wizards/variable_wizard_dialog.dart lib/features/experiment/builder/widgets/variable_editor.dart lib/features/experiment/builder/validation/builder_validator.dart lib/features/experiment/builder/widgets/builder_execution_preview_panel.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart lib/features/experiment/runtime/variables/runtime_variable_dependencies.dart lib/features/experiment/runtime/variables/runtime_variable_executor.dart test/experiment/runtime_aware_builder_variables_test.dart
```

Result: PASS, no issues found.

```text
flutter test test/experiment/runtime_aware_builder_variables_test.dart
```

Result: PASS, 7 tests passed.

```text
flutter test test/experiment/runtime_aware_builder_variables_test.dart test/experiment/runtime_aware_builder_objects_test.dart test/experiment/runtime_variable_execution_test.dart test/experiment/runtime_scatter_plot_test.dart test/experiment/runtime_experiment_state_test.dart test/experiment/runtime_measurement_system_test.dart test/experiment/runtime_display_objects_test.dart test/experiment/runtime_rule_system_test.dart test/experiment/variable_runtime_system_test.dart
```

Result: PASS, 57 tests passed.

## Known Limitations

- Dependency visualization is a simple text tree, as requested.
- Variable editors are runtime-aware for timer and computed variables; sensor-specific authoring remains out of scope.
- Builder UI still allows raw type editing in the edit dialog, but known runtime variable types render dedicated config editors.

## Certification Decision

PASS.

Runtime-aware variable authoring is certified. Variable config creation, validation, dependency validation, cycle detection, draft persistence, manifest persistence, runtime launch, and runtime inspector visibility all pass.
