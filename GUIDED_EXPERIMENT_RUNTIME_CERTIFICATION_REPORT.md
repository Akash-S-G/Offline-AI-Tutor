# Guided Experiment Runtime Certification Report

Generated: 2026-06-11

## Scope

This report certifies Sprint 24: Guided Experiment Runtime.

The sprint adds a guidance layer on top of the existing runtime. It does not add a new physics, rendering, graph, measurement, or observation engine.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Mission model | PASS | `lib/features/experiment/guided_runtime/models/experiment_mission.dart` |
| Task model | PASS | `lib/features/experiment/guided_runtime/models/experiment_task.dart` |
| Question model | PASS | `lib/features/experiment/guided_runtime/models/experiment_question.dart` |
| Completion conditions | PASS | `lib/features/experiment/guided_runtime/conditions/task_completion_condition.dart` |
| Task validator | PASS | `lib/features/experiment/guided_runtime/engine/task_validator.dart` |
| Guided engine | PASS | `lib/features/experiment/guided_runtime/engine/guided_experiment_engine.dart` |
| Runtime event integration | PASS | Guided engine listens to existing `RuntimeEventBus` |
| Left panel mission UI | PASS | `MissionCard`, `TaskProgressWidget`, `CurrentTaskCard` |
| Canvas guided overlay | PASS | `GuidedOverlay` in `LabCenterCanvas` |
| Questions tab | PASS | `ExperimentQuestionPanel` in `LabRightPanel` |
| Completion feedback | PASS | `TaskCompletionBanner` in `RuntimeLabWorkspace` |
| Blueprint mission metadata | PASS | `ExperimentBlueprint.mission`, `BlueprintRuntimeConverter`, `RuntimeLoader` |

## Runtime Flow

```text
RuntimeEventBus
-> GuidedExperimentEngine
-> TaskValidator
-> GuidedRuntimeState
-> Mission / Task / Question UI
```

## Supported Conditions

- Variable reached value
- Control used
- Observation created
- Measurement captured
- Graph viewed
- Question answered
- Timer elapsed

## Certification Tests

Automated tests:

- `test/guided_runtime/guided_experiment_engine_test.dart`
- `test/guided_runtime/task_validator_test.dart`
- `test/guided_runtime/question_runtime_test.dart`
- `test/guided_runtime/mission_progress_test.dart`

Certified behavior:

- Task 1 completion activates Task 2.
- Variable condition completes when the runtime variable reaches the target.
- Observation condition completes from existing observation storage.
- Question answers are stored and validated.
- All tasks complete the mission.
- Progress is calculated from completed tasks over total tasks.

## User Experience Result

The runtime workspace now presents:

- Mission objective
- Current task
- Mission progress
- Timeline
- Guided canvas overlay
- Questions tab
- Task completion feedback

The student now enters a mission/task/action/feedback loop instead of a passive experiment screen.

## Known Limitations

- Default missions are generated from existing experience steps when manifests do not include explicit mission metadata.
- Question completion is local to the guided engine state and is not persisted as a runtime session field yet.
- Timer conditions validate against current runtime clock elapsed time but do not create a visible countdown widget.

## Verification

- PASS: `dart format` completed for Dart sprint files.
- PASS: `flutter analyze` completed for focused sprint files with no issues.
- PASS: `flutter test test/guided_runtime`.

## Certification Status

PASS.
