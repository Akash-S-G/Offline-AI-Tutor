# Experiment Runtime Audit

Generated: 2026-06-09

## Executive Summary

The current Experiment Engine has a useful manifest pipeline and a visible runtime player, but the builder capability surface is significantly broader than the implemented runtime behavior.

The engine can currently:

- Build manifests with scene metadata, variables, objects, and rules.
- Validate missing variable/object references before launch.
- Load manifests into `RuntimeWorld`.
- Render a Flame canvas.
- Store manifest variables by ID.
- Store manifest objects by object ID.
- Render a small set of hard-coded/generic object visuals.
- Start/pause/resume/stop runtime lifecycle.
- Emit lifecycle and generic rule events.
- Provide a builder preview engine separate from the main runtime.

The engine cannot yet fully:

- Convert every builder variable type into live runtime behavior.
- Convert every builder object type into a meaningful visual component.
- Execute all rule types.
- Execute named action types such as `show_warning`, `hide_object`, or `start_recording`.
- Automatically bind sensor streams into runtime variables during builder-launched experiments.
- Continuously evaluate builder-created rules, because builder rules serialize as `trigger: any` while the main rule loop evaluates only `continuous` and `always`.

## Source Areas Audited

| Area | Files |
| --- | --- |
| Builder variable registry | `lib/features/experiment/builder/domain/variable_registry.dart` |
| Builder object registry | `lib/features/experiment/builder/domain/object_registry.dart` |
| Builder rule registry | `lib/features/experiment/builder/domain/rule_registry.dart` |
| Builder wizards/editors | `builder/wizards/*`, `builder/widgets/*_editor.dart` |
| Manifest models | `builder/models/*` |
| Builder validation | `builder/validation/builder_validator.dart` |
| Runtime loading | `runtime/runtime_loader.dart`, `runtime/runtime_validator.dart` |
| Runtime world | `runtime/runtime_world.dart`, `variable_store.dart`, `object_registry.dart`, `rule_engine.dart` |
| Runtime rendering | `runtime/engine/experiment_flame_game.dart`, `flame_object_components.dart`, `runtime_object_factory.dart` |
| Runtime events | `runtime/runtime_event.dart`, `runtime_event_bus.dart`, `runtime_analytics.dart` |
| Sensors | `runtime/sensors/*` |
| Preview engine | `runtime/playground/*`, `application/execution_definition_mapper.dart`, `builder/widgets/runtime_preview_panel.dart` |
| Runtime UI observability | `presentation/screens/experiment_player_screen.dart`, `presentation/runtime_visualization/*` |

## Builder Support Overview

### Variables

The builder exposes 24 variable types across five categories:

- Sensor: accelerometer, gyroscope, magnetometer, gps, microphone, lightSensor, proximity.
- User input: slider, textInput, numberInput, dropdown, toggle.
- Computed: average, minimum, maximum, velocity, acceleration, distance, force, power, energy.
- Timer: elapsedTime, countdown, interval.
- Constant: customConstant.

Builder support is registry-based and wizard-based. It creates `BuilderVariable` records with `id`, `name`, `type`, `value`, and `description`.

Runtime support is mostly value storage. `VariableStore` stores values by variable ID, but most variable types have no dedicated runtime semantics.

### Objects

The builder exposes 15 object types:

- Visualization: lineGraph, barChart, scatterPlot.
- Display: textDisplay, numericDisplay, table.
- Interactive: button, slider, toggle.
- Gauge/counter: gauge, counter, progressBar.
- Scientific: oscilloscope, spectrumAnalyzer, vectorVisualizer.

Runtime has only generic fallback rendering for most of these. Dedicated/semi-dedicated runtime behavior exists for:

- `pendulumSimulation` from templates.
- `plantSimulation` from templates.
- `gauge` as an orange circle placeholder.
- `interactiveDiagram` as an orange circle placeholder.
- `physics_ball` as a runtime-only Forge2D object not exposed by the builder registry.

### Rules

The builder registry exposes eight rule types, but the wizard only fully configures threshold rules. Other selected rule types fall back to generic condition/action payloads.

Main runtime rule evaluation is limited to:

- `trigger == continuous` or `trigger == always`.
- Map condition with `variableId`, `operator`, `value`.
- String assignment actions.
- Map actions that emit only a generic `RuleTriggered` event.

Builder rules serialize with `trigger: any`, so current builder-created threshold rules are loaded but not continuously evaluated by the main runtime loop.

### Actions

The builder exposes action labels:

- `show_warning`
- `hide_object`
- `start_recording`
- `stop_recording`

The runtime does not dispatch these action types to actual behavior. Map actions only emit `RuleTriggered`.

String assignment actions are partially implemented in `RuleEngine`, but not exposed by the current builder wizard.

### Events

Runtime events exist for lifecycle, measurement, warning, error, and custom events. The runtime player now emits lifecycle events for prepare/start/pause/resume/stop.

Rule execution currently appears as custom events with message `RuleTriggered`, not as a dedicated enum value.

The preview playground has a separate event enum and bus.

## Implementation Completeness By Layer

| Layer | Completeness | Notes |
| --- | --- | --- |
| Builder registries | High | Broad list of variables/objects/rules exists |
| Builder creation UI | Medium | Variables, objects, rules can be created; many rule types are generic |
| Builder edit/delete UI | Medium | Item view/edit/delete exists, but editing remains simple |
| Builder validation | Medium-high | Missing references are detected; semantic completeness is not deeply checked |
| Manifest generation | Medium-high | Produces scene manifest with variables/objects/rules |
| Runtime validation | Medium | Checks scene, object IDs, variable refs, rule IDs, rule condition refs |
| Runtime variable behavior | Low-medium | Values load, but live inputs/computed/timer bindings are incomplete |
| Runtime object rendering | Low | Most builder object types use fallback component |
| Runtime rule execution | Low-medium | Narrow rule/action support |
| Runtime actions | Low | Action labels mostly event-only |
| Runtime events/observability | Medium | Lifecycle/event/rule feeds exist, behavior depends on event producers |
| Sensor integration | Low-medium | Providers exist; builder-launched runtime does not auto-bind them |
| Template integrity | Medium | Templates load and references resolve; several use runtime-only object types |

## Built-In Template Audit

| Template | Variables | Objects | Rules | Reference Integrity | Runtime Notes |
| --- | ---: | ---: | ---: | --- | --- |
| Free Fall Experiment | 2 | 1 | 1 | Valid | Uses `lineGraph`, which falls back to generic rectangle; accelerometer variable is static unless sensor binding updates it |
| Heart Rate Monitor | 1 | 1 | 1 | Valid | Uses `gauge` placeholder circle; pulse is static number input |
| Pendulum Motion | 1 | 1 | 1 | Valid | Uses `pendulumSimulation`, rendered by `BuilderObjectComponent`; angle can affect component angle |
| Plant Growth | 2 | 1 | 1 | Valid | Uses `plantSimulation`; growth render reads hard-coded `var_water` and `var_sunlight` |
| Water Cycle | 1 | 1 | 1 | Valid | Uses `interactiveDiagram`, rendered as gauge-like orange circle placeholder |

## Key Gaps Before Adding More Capabilities

1. **Builder/runtime object type mismatch**

   The builder registry lists many object types that do not have dedicated runtime renderers.

2. **Rule trigger mismatch**

   Builder rules serialize as `trigger: any`, while main runtime continuous evaluation checks only `continuous` and `always`.

3. **Action dispatcher missing**

   Map actions are not executed by action type. They only produce a generic rule event.

4. **Sensor binding missing**

   Sensor providers exist, but sensor variables in a builder manifest do not automatically start providers or update `VariableStore`.

5. **Computed/timer variables are static**

   Computed and timer variables are selectable but not backed by runtime computation pipelines.

6. **Preview engine is separate from main runtime**

   `SimulationPlaygroundEngine` validates a builder scene, but it is not the same runtime as `ExperimentFlameGame`/`RuntimeWorld`.

7. **Object state model is minimal**

   `ObjectRegistry` stores objects, but most actions do not mutate object state or visual components.

## Recommended Specification Boundary

Before implementing additional runtime capabilities, define these contracts:

1. Runtime variable contract:
   - Static value.
   - Live input value.
   - Sensor-backed value.
   - Computed value.
   - Timer-backed value.

2. Runtime object contract:
   - Render data.
   - Linked variable refs.
   - Supported actions.
   - Supported events.
   - State update format.

3. Runtime rule contract:
   - Trigger dispatcher.
   - Condition evaluator.
   - Action dispatcher.
   - Error/warning behavior.

4. Builder compatibility contract:
   - Builder should only expose capabilities that runtime can execute, or clearly mark preview-only/future capability.

5. Event contract:
   - Runtime event enum and playground event enum should be reconciled or mapped explicitly.

## Related Documents

- `RUNTIME_CAPABILITY_MATRIX.md`
- `RUNTIME_DEPENDENCY_GRAPH.md`
- `EXPERIMENT_RUNTIME_CERTIFICATION_REPORT.md`

