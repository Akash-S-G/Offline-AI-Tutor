# Object Runtime Capability Matrix

Generated: 2026-06-09

## Scope

This document audits builder object types before object runtime behavior implementation begins.

No runtime features were implemented for this sprint.

Source files inspected:

- `lib/features/experiment/builder/domain/object_registry.dart`
- `lib/features/experiment/builder/wizards/object_wizard_dialog.dart`
- `lib/features/experiment/runtime/runtime_object_factory.dart`
- `lib/features/experiment/runtime/engine/flame_object_components.dart`
- `lib/features/experiment/runtime/models/runtime_object_state.dart`
- `lib/features/experiment/runtime/bindings/runtime_binding_engine.dart`
- `lib/features/experiment/builder/templates/experiment_templates.dart`

## Current Cross-Cutting Findings

- The builder registry declares 15 builder object types.
- The builder wizard can create every declared builder object type.
- The wizard currently configures only:
  - object name
  - one linked variable
- Builder objects serialize as:
  - `objectId`
  - `objectType`
  - `name`
  - `properties`
  - empty `state`
- The builder wizard writes the binding key `linked_variable`.
- Sprint 2 binding discovery maps `linked_variable` to runtime object state property `value`.
- `RuntimeObjectState` exists for all objects, but object-specific state schemas are not enforced yet.
- `RuntimeObjectFactory` does not register any of the 15 builder object types directly.
- Unregistered builder object types use `BuilderObjectComponent` fallback rendering.
- `BuilderObjectComponent` only has special visual cases for `pendulumSimulation`, `plantSimulation`, `gauge`, and `interactiveDiagram`.
- Among builder object types, only `gauge` has a semi-specific fallback visual, rendered as an orange circle.

## Status Legend

- **NONE**: no object-specific runtime behavior exists.
- **PARTIAL**: some generic state, binding, or placeholder rendering exists, but the object does not function according to its educational purpose.
- **COMPLETE**: object has dedicated behavior, state handling, and renderer. No builder object currently qualifies.

## Capability Matrix

| Object Type | Classification | Priority | Builder Support | Builder Properties | Expected RuntimeObjectState | Binding Support | Runtime Behavior | Renderer Support | Missing Components |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lineGraph | VISUALIZATION_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ value, series, history, xAxis, yAxis, unit, sampleCount }` | Yes via `linked_variable -> state.value`; no history binding | PARTIAL: state receives latest value only; no graph behavior | Fallback Renderer | LineGraphBehavior, LineGraphRenderer, bounded history buffer, axis config, sampling policy, series support |
| barChart | VISUALIZATION_OBJECT | P1 | Can be created and named; variable can be linked | `linked_variable` | `{ value, bars, categories, labels, scale }` | Yes via `linked_variable -> state.value` | PARTIAL: state receives latest value only; no bar aggregation | Fallback Renderer | BarChartBehavior, BarChartRenderer, category model, scale calculation, multi-value support |
| scatterPlot | VISUALIZATION_OBJECT | P2 | Can be created and named; variable can be linked | `linked_variable` | `{ x, y, points, xVariableId, yVariableId, sampleCount }` | Limited: one linked variable maps to `value`; no x/y pair binding | PARTIAL: generic state sync only | Fallback Renderer | ScatterPlotBehavior, ScatterPlotRenderer, x/y binding schema, point history, trend/axis support |
| textDisplay | DISPLAY_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ text, value, formattedText }` | Yes via `linked_variable -> state.value`; no dedicated text mapping | PARTIAL: state sync only; no text formatting behavior | Fallback Renderer | TextDisplayBehavior, TextDisplayRenderer, string formatting, static text support, multiline layout |
| numericDisplay | DISPLAY_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ value, unit, precision, formattedValue }` | Yes via `linked_variable -> state.value` | PARTIAL: state sync only; no numeric formatting behavior | Fallback Renderer | NumericDisplayBehavior, NumericDisplayRenderer, unit/precision config, invalid value handling |
| table | DISPLAY_OBJECT | P1 | Can be created and named; variable can be linked | `linked_variable` | `{ value, rows, columns, latestRow, maxRows }` | Yes via `linked_variable -> state.value`; no row append behavior | PARTIAL: state sync only | Fallback Renderer | TableBehavior, TableRenderer, row/column schema, append policy, data collection integration |
| button | INTERACTIVE_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ pressed, pressCount, label, enabled }` | Yes via `linked_variable -> state.value`, but semantically weak | NONE/PARTIAL: no runtime tap handling; only generic state sync if linked | Fallback Renderer | ButtonBehavior, ButtonRenderer, interaction event producer, enabled/label state, rule trigger integration |
| slider | INTERACTIVE_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ value, min, max, step, enabled }` | Yes via `linked_variable -> state.value`; no object-to-variable updates | PARTIAL: one-way variable-to-state only; no interactive control behavior | Fallback Renderer | SliderBehavior, SliderRenderer/control surface, object-to-variable update path, min/max/step config |
| toggle | INTERACTIVE_OBJECT | P1 | Can be created and named; variable can be linked | `linked_variable` | `{ value, enabled, onLabel, offLabel }` | Yes via `linked_variable -> state.value`; no object-to-variable updates | PARTIAL: one-way variable-to-state only | Fallback Renderer | ToggleBehavior, ToggleRenderer/control surface, boolean validation, object-to-variable update path |
| gauge | DISPLAY_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ value, min, max, unit, normalizedValue, warningThreshold }` | Yes via `linked_variable -> state.value` | PARTIAL: state sync plus orange-circle placeholder visual | Fallback/Semi-Specific Renderer | GaugeBehavior, GaugeRenderer, min/max handling, unit label, needle/arc rendering, threshold support |
| counter | DISPLAY_OBJECT | P1 | Can be created and named; variable can be linked | `linked_variable` | `{ count, value, incrementStep, lastIncrementAt }` | Yes via `linked_variable -> state.value`; no count semantics | PARTIAL: state sync only | Fallback Renderer | CounterBehavior, CounterRenderer, increment/decrement actions, event counting, reset behavior |
| progressBar | DISPLAY_OBJECT | P0 | Can be created and named; variable can be linked | `linked_variable` | `{ progress, value, min, max, normalizedValue }` | Yes via `linked_variable -> state.value`; no progress normalization | PARTIAL: state sync only | Fallback Renderer | ProgressBarBehavior, ProgressBarRenderer, min/max normalization, clamping, label support |
| oscilloscope | SCIENTIFIC_OBJECT | P2 | Can be created and named; variable can be linked | `linked_variable` | `{ value, waveform, sampleRate, timeWindow, amplitudeScale }` | Yes via `linked_variable -> state.value`; no waveform history | PARTIAL: state sync only | Fallback Renderer | OscilloscopeBehavior, OscilloscopeRenderer, waveform buffer, sampling frequency, scale controls |
| spectrumAnalyzer | SCIENTIFIC_OBJECT | P2 | Can be created and named; variable can be linked | `linked_variable` | `{ value, bins, frequencies, amplitudes, sampleWindow }` | Yes via `linked_variable -> state.value`; no spectrum model | PARTIAL: state sync only | Fallback Renderer | SpectrumAnalyzerBehavior, SpectrumAnalyzerRenderer, FFT/spectrum pipeline, bin config, microphone/signal input |
| vectorVisualizer | SCIENTIFIC_OBJECT | P1 | Can be created and named; variable can be linked | `linked_variable` | `{ value, x, y, z, magnitude, direction, unit }` | Yes via `linked_variable -> state.value`; no vector component mapping | PARTIAL: state sync only | Fallback Renderer | VectorVisualizerBehavior, VectorVisualizerRenderer, vector decomposition, magnitude/direction formatting, 2D/3D projection |

## Built-In Template Object Coverage

| Template | Object Type | Builder Registry Object? | Runtime State Binding | Renderer Status |
| --- | --- | --- | --- | --- |
| Free Fall | `lineGraph` | Yes | `linked_variable -> value` | Fallback rectangle |
| Heart Rate | `gauge` | Yes | `linked_variable -> value` | Orange circle placeholder |
| Pendulum Motion | `pendulumSimulation` | No, template/runtime-only | `linked_variable -> value` | Semi-specific pendulum drawing |
| Plant Growth | `plantSimulation` | No, template/runtime-only | `water_var -> water`, `sun_var -> sun` | Semi-specific plant drawing using hard-coded variable reads |
| Water Cycle | `interactiveDiagram` | No, template/runtime-only | `temp_var -> temp` | Orange circle placeholder |

## Current Runtime Support Summary

| Support Area | Current Status |
| --- | --- |
| Builder creation | COMPLETE for all 15 builder object types |
| Builder configuration | PARTIAL: name + one linked variable only |
| RuntimeObjectState creation | PARTIAL: generic state exists for all loaded objects |
| Binding support | PARTIAL: property-name based one-way variable-to-state sync |
| Object-specific behavior | NONE for all 15 builder object types |
| Dedicated renderer support | NONE for all 15 builder object types |
| Placeholder/fallback rendering | PARTIAL for all builder object types through `BuilderObjectComponent` |

