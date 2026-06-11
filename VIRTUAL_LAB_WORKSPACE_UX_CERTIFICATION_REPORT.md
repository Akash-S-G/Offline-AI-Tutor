# Virtual Laboratory Workspace UX Certification Report

Generated: 2026-06-11

## Scope

This report certifies UX-6: Virtual Laboratory Workspace.

The sprint replaces the student-facing experiment player surface with a lab-style workspace. Runtime and developer diagnostics remain available behind developer mode, but student mode avoids runtime vocabulary such as variables, objects, rules, bindings, and runtime state.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Workspace package created | PASS | `lib/features/experiment/experience/workspace/` |
| RuntimeLabWorkspace | PASS | `runtime_lab_workspace.dart` |
| Left panel | PASS | `lab_left_panel.dart` |
| Center canvas | PASS | `lab_center_canvas.dart` |
| Right panel | PASS | `lab_right_panel.dart` |
| Timeline widget | PASS | `experiment_timeline.dart` |
| Floating control dock | PASS | `floating_control_dock.dart` |
| Measurement capture FAB | PASS | `measurement_capture_fab.dart` |
| Focus mode overlay | PASS | `focus_mode_overlay.dart` |
| Workspace analytics | PASS | `lab_workspace_analytics.dart` |
| Portrait rotate screen | PASS | `RuntimeLabWorkspace` orientation handling |
| Student vocabulary | PASS | Readings, Visuals, Behavior, Notes, Experiment Status |
| Developer diagnostics preserved | PASS | Existing bug/developer panel remains separate |

## Student Workspace

Landscape layout:

```text
Left Panel | Simulation Canvas | Right Panel
```

Left panel shows:

- Experiment name
- Goal
- Progress
- Timeline
- Current task

Center panel shows:

- Simulation canvas as the primary surface
- Floating controls
- Measurement capture FAB
- Focus mode button

Right panel shows tabs:

- Readings
- Graphs
- Notes

## Focus Mode

Focus mode hides:

- Left panel
- Right panel
- Timeline side content

and expands the simulation canvas.

## Analytics

Added lab workspace counters:

- `focusModeUses`
- `measurementCaptures`
- `graphViews`
- `controlInteractions`
- `workspaceSessions`

## Automated Tests

Test files:

- `test/ui/virtual_lab_workspace_test.dart`
- `test/ui/focus_mode_test.dart`
- `test/ui/control_dock_test.dart`
- `test/ui/experiment_timeline_test.dart`

Covered:

- Landscape renders three-panel virtual lab workspace.
- Focus mode hides side panels and exposes canvas-focused view.
- Measurement FAB creates an observation.
- Floating control dock updates slider state.
- Timeline renders Predict / Run / Observe / Compare / Conclude.

## Verification

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/cache/dart-sdk/bin/dart analyze lib/features/experiment/experience/workspace lib/features/experiment/presentation/screens/experiment_player_screen.dart test/ui
```

Result: PASS.

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/flutter test test/ui
```

Result: PASS.

## Certification Status

PASS.

The student experiment player now presents a virtual laboratory workstation instead of a runtime dashboard.
