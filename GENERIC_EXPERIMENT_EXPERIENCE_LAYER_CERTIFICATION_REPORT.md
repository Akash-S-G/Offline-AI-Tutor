# Generic Experiment Experience Layer Certification Report

Generated: 2026-06-11

## Scope

This report certifies Sprint 20: Generic Experiment Experience Layer.

This sprint adds an educational experience layer above the runtime. Existing runtime systems remain intact and continue to provide variables, objects, rules, measurements, observations, sensors, graphs, scientific visuals, persistence, and simulation canvas behavior.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Experience package created | PASS | `lib/features/experiment/experience/` |
| RuntimeExperience model | PASS | `experience/models/runtime_experience.dart` |
| ExperimentStep model | PASS | `experience/models/experiment_step.dart` |
| StepType enum | PASS | `experience/models/step_type.dart` |
| Completion conditions | PASS | `experience/models/completion_condition.dart` |
| RuntimeExperienceState | PASS | `experience/models/runtime_experience_state.dart` |
| Progress calculator | PASS | `experience/services/experience_progress_calculator.dart` |
| Experience engine | PASS | `experience/engine/runtime_experience_engine.dart` |
| Experience events | PASS | `experience/engine/runtime_experience_events.dart` |
| Experience analytics | PASS | `experience/analytics/experience_analytics.dart` |
| Objective card | PASS | `experience/widgets/experiment_objective_card.dart` |
| Current task card | PASS | `experience/widgets/current_task_card.dart` |
| Control workspace | PASS | `experience/widgets/experiment_control_panel.dart` |
| Observation workspace | PASS | `experience/widgets/observation_workspace.dart` |
| Graph workspace | PASS | `experience/widgets/graph_workspace.dart` |
| Guidance overlay | PASS | `experience/overlays/guidance_overlay.dart` |
| Student label formatter | PASS | `experience/services/runtime_label_formatter.dart` |
| Manifest experience support | PASS | `RuntimeLoader` forwards `experience` metadata |
| Player integration | PASS | `ExperimentPlayerScreen` uses `RuntimeExperienceWorkspace` |

## Generic Completion Conditions

- `VariableCondition`
- `ObservationCondition`
- `GraphViewedCondition`
- `ControlUsedCondition`
- `SensorCondition`
- `QuestionAnsweredCondition`
- `CustomCondition`

## Runtime Event Sources

The experience engine reuses `RuntimeEventBus` and responds to:

- `VariableUpdated`
- `ObservationRecorded`
- `ButtonPressed`
- `SliderChanged`
- `ToggleChanged`
- `GraphUpdated`
- `SensorMeasurementReceived`
- `ExperimentCompleted`
- `ExperimentFailed`

No new event infrastructure was introduced.

## Default Experience Fallback

If manifest metadata has no `experience` object, the layer generates a default student flow:

```text
Observe
Use a Control
Record Observation
Analyze
Complete
```

The fallback is derived from available runtime controls, graphs, observations, and metadata.

## Student-Facing Layout

The player now presents:

- Objective
- Experiment controls
- Simulation canvas
- Current task
- Completion progress
- Observation workspace
- Graph workspace
- Guidance overlay

Developer diagnostics remain behind the existing developer panel.

## Automated Tests

Test file:

- `test/experience/runtime_experience_engine_test.dart`

Covered:

- Progress calculation: `0/5 -> 20% -> 40% -> 100%`
- `SliderChanged -> StepCompleted`
- `ObservationRecorded -> StepCompleted`
- All steps complete -> experience completed
- Runtime event integration for `VariableUpdated`, `ObservationRecorded`, and `GraphUpdated`
- Student labels remove `var_`, `obj_`, and `rule_` prefixes

## Verification

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/cache/dart-sdk/bin/dart analyze lib/features/experiment/experience lib/features/experiment/presentation/screens/experiment_player_screen.dart lib/features/experiment/runtime/runtime_loader.dart test/experience/runtime_experience_engine_test.dart
```

Result: PASS.

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/flutter test test/experience/runtime_experience_engine_test.dart
```

Result: PASS.

## Certification Status

PASS.

Sprint 20 converts the runtime surface from debugger-first to student-experience-first while reusing the existing runtime backend and the generic simulation canvas.
