# Investigation & Multi-Trial System Certification Report

Generated: 2026-06-11

## Scope

This report certifies Sprint 25: Investigation & Multi-Trial System.

The sprint extends the existing investigation package. It does not add a new graph, physics, observation, or measurement engine.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Rich trial model | PASS | `lib/features/experiment/investigation/models/experiment_trial.dart` |
| Trial status | PASS | `lib/features/experiment/investigation/models/trial_status.dart` |
| Trial snapshot system | PASS | `lib/features/experiment/investigation/models/trial_snapshot.dart` |
| Trial manager save/load/delete/reset | PASS | `lib/features/experiment/investigation/trials/experiment_trial_manager.dart` |
| Trial repository abstraction | PASS | `lib/features/experiment/investigation/storage/trial_repository.dart` |
| Comparison result rows | PASS | `lib/features/experiment/investigation/models/comparison_result.dart` |
| Comparison engine | PASS | `lib/features/experiment/investigation/comparison/trial_comparison_engine.dart` |
| Trend detection | PASS | `lib/features/experiment/investigation/comparison/trend_detector.dart` |
| Observation comparison | PASS | `lib/features/experiment/investigation/comparison/observation_comparator.dart` |
| Deterministic conclusion engine | PASS | `lib/features/experiment/investigation/conclusions/conclusion_engine.dart` |
| Trials tab | PASS | `lib/features/experiment/investigation/widgets/trial_history_panel.dart` |
| Investigation progress panel | PASS | `lib/features/experiment/investigation/widgets/investigation_progress_panel.dart` |
| Current trial banner | PASS | `lib/features/experiment/investigation/widgets/current_trial_banner.dart` |
| Guided runtime trial conditions | PASS | `TrialCompletedCondition`, `ComparisonCompletedCondition`, `ConclusionGeneratedCondition` |
| Blueprint investigation metadata | PASS | `ExperimentBlueprint.investigation`, `BlueprintRuntimeConverter`, `RuntimeLoader` |

## Runtime Flow

```text
Run Trial
-> ExperimentTrialManager.startTrial()
-> RuntimeWorld starts
-> Save Trial
-> TrialSnapshot captures variables, measurements, observations, graphs
-> TrialComparisonEngine compares trials
-> TrendDetector classifies trend
-> ConclusionEngine generates deterministic conclusion
```

## UI Certification

The virtual lab workspace now includes:

- Right panel `Trials` tab.
- Trial run/save controls.
- Trial history list.
- Snapshot inspection.
- Comparison output.
- Deterministic conclusion output.
- Left panel investigation progress.
- Center canvas current trial banner.

## Guided Mission Support

New task conditions:

- `trialCompleted`
- `comparisonCompleted`
- `conclusionGenerated`

These allow missions to require multiple trials before completion.

## Automated Tests

- `test/investigation/trial_manager_test.dart`
- `test/investigation/trial_snapshot_test.dart`
- `test/investigation/comparison_engine_test.dart`
- `test/investigation/trend_detector_test.dart`
- `test/investigation/conclusion_engine_test.dart`
- Existing `test/investigation/investigation_workflow_test.dart`

## Certification Status

PASS.

## Verification

- PASS: `dart format` completed for Sprint 25 Dart files.
- PASS: `flutter analyze` completed for focused Sprint 25 files with no issues.
- PASS: `flutter test test/investigation`.
