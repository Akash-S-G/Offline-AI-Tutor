# Object Runtime Dependencies

Generated: 2026-06-09

## Scope

This document defines dependencies required to implement object runtime behavior after the Sprint 2.5 audit.

No runtime features were implemented for this sprint.

## Current Runtime Layers

```text
Manifest Object
-> ObjectRegistry metadata
-> RuntimeObjectState
-> RuntimeBindingEngine
-> ObjectUpdatedFromBinding event
-> Renderer currently still reads old object metadata / variable store
```

## Required Object Runtime Architecture

Future object support should use this shape:

```text
RuntimeObjectBehavior
  -> consumes RuntimeObjectState
  -> validates object-specific state
  -> handles object-specific actions/events

RuntimeObjectRenderer
  -> renders RuntimeObjectState
  -> does not read variables directly

RuntimeObjectStateSchema
  -> declares allowed fields
  -> default values
  -> validation rules

RuntimeObjectController/Interaction Adapter
  -> only for interactive objects
  -> emits interaction events
  -> updates variables through VariableStore when needed
```

## Shared Dependencies

| Dependency | Required By | Purpose | Current Status |
| --- | --- | --- | --- |
| `RuntimeObjectState` | All objects | Canonical object state | Exists, generic |
| `RuntimeBindingEngine` | All bound objects | Variable-to-state sync | Exists, one-way |
| `RuntimeEventBus` | All objects | Object/binding/interaction events | Exists |
| `RuntimeAnalytics` | All objects | Counts object updates and events | Partial |
| Object state schema registry | All objects | Validate expected fields and defaults | Missing |
| Object behavior registry | All objects | Object-specific update behavior | Missing |
| Object renderer registry | All rendered objects | Dedicated renderers by object type | Missing |
| Interaction event adapter | Interactive objects | Button/slider/toggle event production | Missing |
| Formatting utilities | Display objects | Units, precision, labels | Missing |
| History buffer | Visualization/scientific objects | Time-series storage | Missing |

## Object Dependencies By Category

### DISPLAY_OBJECT

Objects:

- `textDisplay`
- `numericDisplay`
- `gauge`
- `counter`
- `progressBar`
- `table`

Required shared dependencies:

- Object state schema registry
- Display behavior base class
- Formatter for value/unit/precision/text
- Dedicated display renderers
- Visibility/action support for future action dispatcher

Object-specific dependencies:

| Object | Dependencies |
| --- | --- |
| textDisplay | text formatting, multiline layout, optional static text |
| numericDisplay | numeric formatting, unit support, precision config |
| gauge | min/max normalization, needle/arc renderer, threshold state |
| counter | count semantics, increment/decrement/reset actions |
| progressBar | min/max normalization, clamp policy, progress renderer |
| table | row/column schema, row append policy, data collection integration |

### INTERACTIVE_OBJECT

Objects:

- `button`
- `slider`
- `toggle`

Required shared dependencies:

- Interaction event adapter
- Object-to-variable update path
- Input validation
- Enabled/disabled state handling
- Future rule dispatcher integration

Object-specific dependencies:

| Object | Dependencies |
| --- | --- |
| button | press/tap event producer, press count state, label renderer |
| slider | min/max/step config, drag/update control, numeric variable updates |
| toggle | boolean validation, on/off labels, boolean variable updates |

### VISUALIZATION_OBJECT

Objects:

- `lineGraph`
- `barChart`
- `scatterPlot`

Required shared dependencies:

- History/sample buffer
- Sampling policy
- Axis/scale model
- Multi-series binding support
- Dedicated chart renderers
- Optional data collection integration

Object-specific dependencies:

| Object | Dependencies |
| --- | --- |
| lineGraph | time-series buffer, axis model, line renderer, downsampling |
| barChart | category/value schema, bar scale, labels |
| scatterPlot | x/y binding schema, point buffer, correlation/trend options |

### SCIENTIFIC_OBJECT

Objects:

- `oscilloscope`
- `spectrumAnalyzer`
- `vectorVisualizer`

Required shared dependencies:

- High-frequency sample handling
- Scientific scale/units
- Dedicated scientific renderers
- Sensor/signal input pipeline in future sprints

Object-specific dependencies:

| Object | Dependencies |
| --- | --- |
| oscilloscope | waveform buffer, time window, amplitude scale, sample rate |
| spectrumAnalyzer | FFT/spectrum pipeline, frequency bins, amplitude normalization |
| vectorVisualizer | vector component mapping, magnitude/direction calculation, projection renderer |

## Binding Dependencies

Current binding discovery supports:

- `variableId -> value`
- `valueVariable -> value`
- `sourceVariable -> source`
- `boundVariable -> value`
- `linkedVariable -> value`
- `linked_variable -> value`
- `*_var -> *`

Missing binding dependencies:

- Multi-variable binding schemas.
- Required/optional binding validation by object type.
- Binding aliases by object type.
- Type validation between variable and object property.
- Initial default state generation by object type.

## Renderer Dependencies

Current renderer support:

- All builder object types can be rendered by fallback rectangle.
- `gauge` gets orange circle placeholder.

Missing renderer dependencies:

- Dedicated renderer classes for all P0 objects.
- Renderer registry keyed by `objectType`.
- Renderers should consume `RuntimeObjectState`, not raw variable store values.
- Layout/position/size model for object placement.
- Mobile-safe visual bounds and text fitting.

## Behavior Dependencies

Missing behavior dependencies:

- `LineGraphBehavior`
- `TextDisplayBehavior`
- `NumericDisplayBehavior`
- `ButtonBehavior`
- `SliderBehavior`
- `GaugeBehavior`
- `ProgressBarBehavior`
- Category behavior bases:
  - `DisplayObjectBehavior`
  - `InteractiveObjectBehavior`
  - `VisualizationObjectBehavior`
  - `ScientificObjectBehavior`

## Builder Dependencies To Address Later

Builder currently configures only object name and one variable. Full object behavior will eventually need builder configuration for:

- display labels
- units
- min/max
- precision
- axis labels
- chart series
- button labels
- slider ranges
- toggle labels
- table columns
- scientific sample windows

These builder changes are not part of this sprint.

