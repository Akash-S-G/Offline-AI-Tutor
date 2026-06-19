# Visualization-First Experiment Runtime Certification Report

Generated: 2026-06-11

## Scope

Sprint 27 adds an additive visualization-first layer for the experiment runtime.

Constraint followed:

- New files only.
- No existing runtime, preset, builder, graph, particle, canvas, or player files modified.
- No new physics engine.
- No experiment-specific runtime.

## Goal

Every experiment should be capable of feeling alive within 3 seconds by defining:

- Idle motion
- Parameter-driven animation response
- Animated graph behavior
- Generic particle systems
- Lightweight background environments
- Cause/effect feedback contracts
- Rule-based visual narration
- Task focus requests

## Files Added

### Core Models

- `lib/features/experiment/visualization_first/models/visual_motion_spec.dart`
- `lib/features/experiment/visualization_first/models/visual_parameter_response.dart`
- `lib/features/experiment/visualization_first/models/visualization_first_profile.dart`

### Preset Profiles

- `lib/features/experiment/visualization_first/registry/animation_first_preset_registry.dart`

Certified profiles:

- Free Fall
- Pendulum
- Plant Growth
- Water Cycle
- Heart Rate

### Generic Visual Systems

- `lib/features/experiment/visualization_first/particles/generic_particle_library.dart`
- `lib/features/experiment/visualization_first/particles/particle_system_profile.dart`
- `lib/features/experiment/visualization_first/environments/visual_environment_library.dart`
- `lib/features/experiment/visualization_first/environments/visual_environment_profile.dart`

### Animated Graph Contracts

- `lib/features/experiment/visualization_first/graphs/animated_graph_profile.dart`
- `lib/features/experiment/visualization_first/graphs/animated_graph_profile_registry.dart`

### Interaction Feedback

- `lib/features/experiment/visualization_first/interactions/visual_cause_effect_event.dart`
- `lib/features/experiment/visualization_first/interactions/visual_feedback_profile.dart`
- `lib/features/experiment/visualization_first/interactions/visual_feedback_registry.dart`

### Narration and Focus

- `lib/features/experiment/visualization_first/narration/visual_event_narrator.dart`
- `lib/features/experiment/visualization_first/focus/visual_focus_request.dart`
- `lib/features/experiment/visualization_first/focus/visual_focus_policy.dart`

### Certification

- `lib/features/experiment/visualization_first/validation/visualization_first_certification.dart`
- `lib/features/experiment/visualization_first/visualization_first.dart`
- `test/experiment/visualization_first_runtime_test.dart`

## Certification Matrix

| Requirement | Result | Evidence |
| --- | --- | --- |
| Animation-first presets | PASS | `AnimationFirstPresetRegistry.all` defines five profiles. |
| Idle animation within 3 seconds | PASS | `VisualMotionSpec.satisfiesAliveRequirement`. |
| Parameter-driven animation | PASS | `VisualParameterResponse` entries for each profile. |
| Animated graphs | PASS | `AnimatedGraphProfileRegistry`. |
| Particle expansion | PASS | Flow, heat, water, spark, motion trail profiles. |
| Background environments | PASS | Laboratory, nature, space, physics room, chemistry bench. |
| Animated cause/effect | PASS | `VisualCauseEffectEvent` and `VisualFeedbackRegistry`. |
| Narrated visual events | PASS | `VisualEventNarrator`. |
| Visual focus system | PASS | `VisualFocusPolicy`. |
| Mobile optimization | PASS | Particle limits and graph animation durations are capped. |

## Built-In Preset Motion

| Preset | Idle Motion | Parameter Response | Environment |
| --- | --- | --- | --- |
| Pendulum | Oscillating rod, fading trail | Length and angle affect motion | Physics Room |
| Heart Rate | Pulse | BPM affects pulse speed | Laboratory |
| Plant Growth | Breathing plant scale | Water and sunlight affect growth | Nature |
| Water Cycle | Flow particles, cloud drift | Temperature affects particle speed | Nature |
| Free Fall | Looping fall preview, trail | Height and velocity affect path/trail | Physics Room |

## Generic Particle Systems

- Flow particles
- Heat particles
- Water particles
- Spark particles
- Motion trails

All are generic and mobile-safe by profile constraints.

## Animated Graph Behavior

- Line graph: draw line from start, pulse latest point.
- Scatter plot: scale points into place, pulse new point.
- Bar chart: grow bars from zero, animate bar height.
- Oscilloscope: waveform sweep and live scroll.

## Sprint 27.5 Integration

Generated: 2026-06-11

The visualization-first layer is now integrated into the active runtime.

### Runtime Integration Files

- `lib/features/experiment/visualization_first/runtime/runtime_visualization_state.dart`
- `lib/features/experiment/visualization_first/runtime/visualization_profile_resolver.dart`
- `lib/features/experiment/visualization_first/runtime/visualization_animation_injector.dart`
- `lib/features/experiment/visualization_first/runtime/visualization_particle_controller.dart`
- `lib/features/experiment/visualization_first/runtime/visualization_parameter_controller.dart`
- `lib/features/experiment/visualization_first/runtime/visualization_runtime_coordinator.dart`
- `lib/features/experiment/visualization_first/runtime/graph_animation_adapter.dart`

### Active Runtime Changes

- `RuntimeWorld` now owns `visualizationRuntime` and `visualizationState`.
- `RuntimeLoader` infers `visualPreset` for built-in templates when missing.
- `RuntimeWorld.initialize()` resolves and attaches the visualization profile.
- Idle animations are injected into the existing `RuntimeAnimationEngine`.
- Generic particles are attached as existing `particle` actors.
- `RuntimeLabWorkspace` ticks the existing animation engine immediately, before Run is pressed.
- `SimulationEnvironment` supports visualization-first environment IDs.
- Existing narrator and cause/effect overlays consume visualization events.
- Developer panel shows a `Visualization Runtime` diagnostics section.

### Integrated Flow

```text
Template / Blueprint
↓
RuntimeLoader
↓
VisualPreset inferred or read from metadata
↓
RuntimeWorld
↓
VisualizationProfileResolver
↓
VisualizationRuntimeCoordinator
↓
RuntimeAnimationEngine + particle actors + environment state
↓
RuntimeLabWorkspace
↓
Student sees motion within 3 seconds
```

### Analytics Added

- `visualizationProfilesLoaded`
- `idleAnimationsStarted`
- `particlesSpawned`
- `environmentsRendered`
- `visualResponsesTriggered`
- `narrationEventsShown`
- `focusEventsTriggered`

### Integration Tests

Added:

- `test/experiment/visualization_first_runtime_integration_test.dart`

Verified:

- Built-in templates attach the expected active visualization profile.
- Idle animation changes visible actor state before Run is pressed.
- Visual response and narration events emit from parameter changes.

## Verification

Focused tests:

```text
flutter test test/experiment/visualization_first_runtime_test.dart test/experiment/visualization_first_runtime_integration_test.dart
```

Result:

```text
PASS
```

## Result

Sprint 27 and Sprint 27.5 are certified.

The active runtime now attaches visualization-first profiles, environments, idle animations, particle actors, visual response events, narration events, analytics, and developer diagnostics.

## UX-10 Immersive Laboratory Runtime Redesign

Generated: 2026-06-11

### Goal

Move the active runtime from:

```text
Canvas + controls + overlays
```

to:

```text
Experiment Stage + Instruments + Investigation
```

### Active Layout Changes

- Compact header is capped at `48px`.
- Main experiment stage fills the area between header and lab dock.
- Stage now contains scene structure, preset-specific anchors, environment, canvas, visual effects, and live graph dock.
- Bottom controls moved into a compact `LaboratoryDock` with icon actions.
- Investigation drawer remains collapsed above the dock until opened.
- Graphs are visible by default through the live graph dock instead of being fully hidden.
- Old floating tool cluster and heavy floating control panel were removed from the active workspace.

### Files Added

- `lib/features/experiment/experience/lab_v2/stage/scene_definition.dart`
- `lib/features/experiment/experience/lab_v2/stage/scene_definition_resolver.dart`
- `lib/features/experiment/experience/lab_v2/stage/experiment_stage.dart`
- `lib/features/experiment/experience/lab_v2/stage/live_graph_dock.dart`
- `lib/features/experiment/experience/lab_v2/widgets/laboratory_dock.dart`

### Files Updated

- `lib/features/experiment/experience/workspace/runtime_lab_workspace.dart`
- `lib/features/experiment/experience/lab_v2/widgets/experiment_hud.dart`
- `lib/features/experiment/experience/lab_v2/widgets/floating_lab_sheet.dart`
- `lib/features/experiment/experience/workspace/lab_right_panel.dart`

### Preset Scene Identity

- Water Cycle: sky, sun, cloud, rain zone, water body.
- Free Fall: physics grid, height scale, drop zone, ground.
- Pendulum: support point, swing zone, measurement zone.
- Plant Growth: nature base, sun, plant, soil, water zone.
- Heart Rate: medical monitor, heart, pulse ring, ECG zone.

### Verification

Focused analysis:

```text
flutter analyze --no-fatal-infos lib/features/experiment/experience/lab_v2/stage lib/features/experiment/experience/lab_v2/widgets/laboratory_dock.dart lib/features/experiment/experience/lab_v2/widgets/floating_lab_sheet.dart lib/features/experiment/experience/lab_v2/widgets/experiment_hud.dart lib/features/experiment/experience/workspace/runtime_lab_workspace.dart lib/features/experiment/experience/workspace/lab_right_panel.dart
```

Result:

```text
PASS
```

Focused runtime smoke tests:

```text
flutter test test/experiment/visualization_first_runtime_test.dart test/experiment/visualization_first_runtime_integration_test.dart
```

Result:

```text
PASS
```
## UX-13 Experiment-First Runtime Redesign

Status: IMPLEMENTED

### Integration Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| ExperimentTheatre created | PASS | `lib/features/experiment/experience/lab_v2/stage/experiment_theatre.dart` |
| ExperimentIntroOverlay created | PASS | `lib/features/experiment/experience/lab_v2/widgets/experiment_intro_overlay.dart` |
| ExperimentAssetRegistry created | PASS | `lib/features/experiment/experience/lab_v2/stage/experiment_asset_registry.dart` |
| CauseEffectCard created | PASS | `lib/features/experiment/experience/lab_v2/interactions/cause_effect_card.dart` |
| FindingsPanel created | PASS | `lib/features/experiment/experience/lab_v2/widgets/findings_panel.dart` |
| SpotlightController created | PASS | `lib/features/experiment/experience/lab_v2/interactions/spotlight_controller.dart` |
| RuntimeLabWorkspace uses intro and findings-first sheet | PASS | `lib/features/experiment/experience/workspace/runtime_lab_workspace.dart` |
| ExperimentStage delegates scene ownership to ExperimentTheatre | PASS | `lib/features/experiment/experience/lab_v2/stage/experiment_stage.dart` |
| Built-in scenes expose anchors and assets | PASS | `SceneDefinitionResolver` plus `assets/experiment_scenes/` |
| SVG assets organized by experiment folder | PASS | `assets/experiment_scenes/water_cycle/`, `free_fall/`, `pendulum/`, `heart_rate/`, `plant_growth/` |
| Theatre no longer relies on visible anchor labels | PASS | `ExperimentTheatre` paints recognizable scene actors directly |

### Active Screen Behavior

The active runtime route still enters `ExperimentPlayerScreen`, but the visible student
experience is owned by `RuntimeLabWorkspace`. The runtime now launches with:

- a full experiment theatre/stage,
- compact top HUD,
- collapsed investigation sheet,
- icon-only laboratory dock,
- live graph dock,
- contextual cause/effect card,
- contextual spotlight,
- findings-first investigation panel.

The stricter UX-13 pass also moves visual assets into the required
per-experiment SVG folders and removes visible anchor labels from the theatre.
Water Cycle, Free Fall, Pendulum, Plant Growth, and Heart Rate now have
folder-based scene assets certified by the focused test.

### Certification Tests

Automated test file:

- `test/experiment/experiment_first_runtime_redesign_test.dart`

Coverage:

- built-in templates resolve to recognizable scene definitions,
- each scene has primary object, variable, outcome,
- Water Cycle, Pendulum, Free Fall, Plant Growth, and Heart Rate expose expected anchors,
- every scene asset ID resolves through `ExperimentAssetRegistry`.
- every resolved scene asset uses the required foldered SVG path shape.
