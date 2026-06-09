# Runtime-Aware Builder Objects Certification Report

Generated: 2026-06-10

## Scope

This report certifies Sprint 15A: Runtime-Aware Object Authoring.

Implemented in this sprint:

- `BuilderObject.runtimeConfig`.
- Runtime config serialization through object JSON.
- Runtime config persistence through draft save/load payloads.
- Runtime config propagation into generated manifests.
- Runtime config propagation into runtime object state.
- Runtime-aware object config editor widgets.
- Builder validation for runtime object config.
- Execution preview object runtime validation.
- Runtime inspector object runtime config visibility.

Out of scope:

- New runtime object behavior.
- New graph/scientific runtime capability.
- Backend schema changes.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| `BuilderObject.runtimeConfig` added | PASS | `lib/features/experiment/builder/models/builder_object.dart` |
| `BuilderObject.toJson()` preserves config | PASS | `runtimeConfig`, merged `properties`, and `state` output |
| `BuilderObject.fromJson()` restores config | PASS | Supports direct `runtimeConfig`, nested `properties.runtimeConfig`, and legacy extraction |
| Draft save/load preserves config | PASS | `BuilderDraft.toJson()` / `BuilderDraft.fromJson()` test |
| Manifest generation preserves config | PASS | `ExperimentBuilderState.generateManifestJson()` uses `BuilderObject.toJson()` |
| Runtime launch receives config | PASS | Runtime object state contains config values |
| Numeric config editor created | PASS | `NumericDisplayConfigEditor` |
| Gauge config editor created | PASS | `GaugeConfigEditor` |
| Progress bar config editor created | PASS | `ProgressBarConfigEditor` |
| Line graph config editor created | PASS | `LineGraphConfigEditor` |
| Scatter plot config editor created | PASS | `ScatterPlotConfigEditor` |
| Table config editor created | PASS | `TableConfigEditor` |
| Generic runtime config editor created | PASS | `RuntimeObjectConfigEditor` |
| Object wizard uses runtime config | PASS | `ObjectWizardDialog` |
| Object editor can inspect/edit runtime config | PASS | `ObjectEditor` |
| Builder validation extended | PASS | `BuilderValidator` |
| Execution preview shows object runtime validation | PASS | `BuilderExecutionPreviewPanel` |
| Runtime inspector shows object runtime config | PASS | `ExperimentPlayerScreen` |

## Config Formats Certified

Numeric Display:

```json
{
  "label": "Velocity",
  "unit": "m/s",
  "precision": 2
}
```

Gauge:

```json
{
  "min": 0,
  "max": 100,
  "unit": "C",
  "warningThreshold": 80
}
```

Progress Bar:

```json
{
  "min": 0,
  "max": 100
}
```

Line Graph:

```json
{
  "variableId": "var_temp",
  "historyWindow": 100,
  "xAxis": "Time",
  "yAxis": "Temperature"
}
```

Scatter Plot:

```json
{
  "xVariable": "var_time",
  "yVariable": "var_distance"
}
```

Table:

```json
{
  "maxRows": 100,
  "autoRecord": true
}
```

## Validation Certified

Builder validation now checks:

- Numeric display precision must be `>= 0`.
- Gauge `min < max`.
- Gauge warning threshold must be inside range.
- Progress bar `min < max`.
- Line graph variable must exist.
- Scatter plot X variable must exist.
- Scatter plot Y variable must exist.
- Scatter plot X/Y variables must differ.
- Table `maxRows > 0`.

## Runtime Visibility

Runtime inspector now includes:

```text
Object Runtime Config
```

Example visible entries:

```text
Temperature Gauge
min: 0 | max: 100 | unit: C | warningThreshold: 80

Distance vs Time
xVariable: var_time | yVariable: var_distance
```

## Automated Tests

Automated test file:

```text
test/experiment/runtime_aware_builder_objects_test.dart
```

Certified cases:

| Test | Result |
| --- | --- |
| Gauge config survives save, load, manifest, and runtime | PASS |
| Scatter plot X/Y variables survive full pipeline | PASS |
| Draft persistence preserves `runtimeConfig` | PASS |
| Builder validator checks runtime config rules | PASS |
| Line graph runtime config variable is accepted by runtime | PASS |

## Verification Commands

```text
dart format lib/features/experiment/builder/models/builder_object.dart lib/features/experiment/builder/controllers/experiment_builder_controller.dart lib/features/experiment/builder/validation/builder_validator.dart lib/features/experiment/builder/widgets/object_runtime_config_editors.dart lib/features/experiment/builder/wizards/object_wizard_dialog.dart lib/features/experiment/builder/widgets/object_editor.dart lib/features/experiment/builder/widgets/builder_execution_preview_panel.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart lib/features/experiment/runtime/engine/display_object_components.dart test/experiment/runtime_aware_builder_objects_test.dart
```

Result: PASS.

```text
flutter analyze lib/features/experiment/builder/models/builder_object.dart lib/features/experiment/builder/controllers/experiment_builder_controller.dart lib/features/experiment/builder/validation/builder_validator.dart lib/features/experiment/builder/widgets/object_runtime_config_editors.dart lib/features/experiment/builder/wizards/object_wizard_dialog.dart lib/features/experiment/builder/widgets/object_editor.dart lib/features/experiment/builder/widgets/builder_execution_preview_panel.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart lib/features/experiment/runtime/engine/display_object_components.dart test/experiment/runtime_aware_builder_objects_test.dart
```

Result: PASS, no issues found.

```text
flutter test test/experiment/runtime_aware_builder_objects_test.dart
```

Result: PASS, 5 tests passed.

## Known Limitations

- Runtime config is mirrored into manifest `properties` and `state` for compatibility with the current runtime object system.
- Object editor still allows changing the raw object type string; runtime-specific config editors appear for known runtime object types.
- Axis labels and history window are persisted for line graph config, but the current renderer behavior still uses the existing fixed runtime graph behavior until Sprint 15B or a renderer-polish sprint consumes those labels visually.

## Certification Decision

PASS.

Runtime-aware object authoring is now available for the builder objects already implemented in runtime. Config creation, validation, draft persistence, manifest persistence, runtime launch, and runtime inspector visibility are certified.
