# Scatter Plot Runtime Certification Report

Generated: 2026-06-09

## Scope

This report certifies Sprint 14: Scatter Plot Runtime.

Implemented in this sprint:

- Scatter runtime package.
- Runtime scatter point model.
- Scatter plot state model.
- Scatter plot behavior with two-variable measurement pairing.
- Scatter plot renderer with axes, grid, and points.
- `scatterPlot` behavior, renderer, schema, and factory registration.
- Runtime display component integration.
- Runtime inspector scatter plot section.
- Scatter plot analytics.
- Scene-shaped manifest loader normalization.

Out of scope and not implemented:

- Trend lines.
- Regression/correlation statistics.
- Point selection.
- Custom marker styles.
- Configurable history window in the builder UI.
- Oscilloscope, spectrum analyzer, and vector visualizer runtime behavior.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Runtime scatter package created | PASS | `lib/features/experiment/runtime/scatter/` |
| RuntimeScatterPoint created | PASS | `runtime_scatter_point.dart` |
| ScatterPlotState created | PASS | `scatter_plot_state.dart` |
| ScatterPlotBehavior created | PASS | `scatter_plot_behavior.dart` |
| ScatterPlotRenderer created | PASS | `scatter_plot_renderer.dart` |
| X/Y variable support added | PASS | `xVariable`, `yVariable` properties |
| Both variables are validated | PASS | Runtime validator rejects missing `var_...` references |
| Latest 100-point window implemented | PASS | `ScatterPlotBehavior.pointWindow` |
| Auto scaling implemented | PASS | `minX`, `maxX`, `minY`, `maxY` from active points |
| Renderer draws real plot UI | PASS | Axes, grid, points, and point count |
| Runtime behavior registry updated | PASS | `RuntimeObjectBehaviorRegistry` |
| Runtime renderer registry updated | PASS | `RuntimeObjectRendererRegistry` |
| Runtime schema registry updated | PASS | `RuntimeObjectSchemaRegistry` |
| Runtime factory updated | PASS | `RuntimeObjectFactory` |
| Runtime inspector updated | PASS | `ExperimentPlayerScreen` shows Scatter Plots |
| Analytics updated | PASS | `scatterPlotsRendered`, `scatterPlotUpdates`, `scatterPointsProcessed` |
| Scene-shaped manifest launch fixed | PASS | `RuntimeLoader` normalizes direct scene payloads |

## Runtime Flow Certified

```text
VariableStore.updateVariable()
-> MeasurementCollected
-> RuntimeMeasurementStore
-> RuntimeDisplayObjectComponent
-> ScatterPlotBehavior
-> ScatterPlotState
-> ScatterPlotRenderer
-> ScatterPlotUpdated / ScatterPlotRendered
-> RuntimeAnalytics
```

## Multi-Variable Pairing

Supported object properties:

```json
{
  "xVariable": "var_time",
  "yVariable": "var_distance"
}
```

Also accepted:

```text
x_variable
xVariableId
y_variable
yVariableId
```

Pairing behavior:

```text
X measurements: 1, 2, 3
Y measurements: 5, 10, 15
```

Creates:

```text
(1, 5)
(2, 10)
(3, 15)
```

If histories are uneven, the latest complete X/Y pairs are used.

## Certification Experiments

### Experiment 1: Distance vs Time

Variables:

```text
ElapsedTime
Distance
```

Object:

```text
scatterPlot
xVariable = ElapsedTime
yVariable = Distance
```

Expected:

```text
Growing point cloud
```

Result: PASS.

### Experiment 2: Force vs Acceleration

Variables:

```text
Acceleration
Force
```

Object:

```text
scatterPlot
xVariable = Acceleration
yVariable = Force
```

Expected:

```text
Points plotted
```

Result: PASS.

### Experiment 3: Temperature vs Pressure

Variables:

```text
Temperature Slider
Pressure Slider
```

Object:

```text
scatterPlot
xVariable = Temperature
yVariable = Pressure
```

Expected:

```text
Points appear as sliders change
```

Result: PASS.

## Automated Tests

Automated test file:

```text
test/experiment/runtime_scatter_plot_test.dart
```

Certified cases:

| Test | Result |
| --- | --- |
| Paired measurements create scatter points | PASS |
| Auto scaling calculates x and y ranges | PASS |
| Latest 100 point history window is enforced | PASS |
| Uneven histories pair only complete X/Y samples | PASS |
| Renderer supports empty and plotted states | PASS |
| Registries and factory support `scatterPlot` | PASS |
| Validation rejects missing X/Y variable references | PASS |
| Runtime loader accepts scene-shaped payloads | PASS |
| Runtime component updates renderer and scatter analytics | PASS |

## Verification Commands

```text
dart format lib/features/experiment/runtime/scatter lib/features/experiment/runtime/engine/display_object_components.dart lib/features/experiment/runtime/objects/behavior/runtime_object_behavior_registry.dart lib/features/experiment/runtime/objects/renderers/runtime_object_renderer_registry.dart lib/features/experiment/runtime/objects/schema/runtime_object_schema_registry.dart lib/features/experiment/runtime/runtime_object_factory.dart lib/features/experiment/runtime/runtime_analytics.dart lib/features/experiment/runtime/experiment_state/runtime_experiment_state_manager.dart lib/features/experiment/runtime/runtime_loader.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart test/experiment/runtime_scatter_plot_test.dart
```

Result: PASS.

```text
flutter analyze lib/features/experiment/runtime/scatter lib/features/experiment/runtime/engine/display_object_components.dart lib/features/experiment/runtime/objects/behavior/runtime_object_behavior_registry.dart lib/features/experiment/runtime/objects/renderers/runtime_object_renderer_registry.dart lib/features/experiment/runtime/objects/schema/runtime_object_schema_registry.dart lib/features/experiment/runtime/runtime_object_factory.dart lib/features/experiment/runtime/runtime_analytics.dart lib/features/experiment/runtime/experiment_state/runtime_experiment_state_manager.dart lib/features/experiment/runtime/runtime_loader.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart test/experiment/runtime_scatter_plot_test.dart
```

Result: PASS, no issues found.

```text
flutter test test/experiment/runtime_scatter_plot_test.dart
```

Result: PASS, 9 tests passed.

```text
flutter test test/experiment/runtime_scatter_plot_test.dart test/experiment/runtime_experiment_state_test.dart test/experiment/runtime_observation_table_test.dart test/experiment/runtime_line_graph_test.dart test/experiment/runtime_measurement_system_test.dart test/experiment/runtime_variable_execution_test.dart test/experiment/runtime_display_objects_test.dart test/experiment/runtime_rule_system_test.dart test/experiment/interactive_object_runtime_test.dart test/experiment/runtime_binding_engine_test.dart test/experiment/runtime_object_foundation_test.dart test/experiment/variable_runtime_system_test.dart
```

Result: PASS, 68 tests passed.

```text
flutter build apk --debug
```

Result: PASS, built `build/app/outputs/flutter-apk/app-debug.apk`.

## Known Limitations

- Scatter plot points are paired by latest complete sample index, not timestamp interpolation.
- The history window is fixed at 100 points for now.
- Renderer draws points only; no trend line or regression calculation is implemented.
- Builder UI may still need richer scatter-specific configuration controls beyond `xVariable` and `yVariable`.

## Certification Decision

PASS.

Scatter Plot is no longer a placeholder. It now supports two-variable runtime visualization, validates multi-variable references, generates scatter points from measurement history, renders axes and points, reports inspector state, and emits analytics.
