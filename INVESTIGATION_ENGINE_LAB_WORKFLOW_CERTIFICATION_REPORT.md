# Investigation Engine & Lab Workflow Certification Report

Generated: 2026-06-11

## Scope

This report certifies Sprint 24: Investigation Engine & Lab Workflow.

The sprint adds an investigation workflow above the runtime so experiments can follow a lab pattern:

```text
Predict
-> Run Trial
-> Observe
-> Measure
-> Compare
-> Conclude
```

Existing runtime systems remain unchanged.

## Implementation Results

| Requirement | Result | Evidence |
| --- | --- | --- |
| Investigation package created | PASS | `lib/features/experiment/investigation/` |
| ExperimentTrial model | PASS | `models/experiment_trial.dart` |
| TrialSnapshot model | PASS | `models/trial_snapshot.dart` |
| ExperimentTrialManager | PASS | `trials/experiment_trial_manager.dart` |
| PredictionEntry model | PASS | `models/prediction_entry.dart` |
| Prediction storage | PASS | `predictions/prediction_store.dart` |
| TrialComparison model | PASS | `models/trial_comparison.dart` |
| TrialComparator | PASS | `comparison/trial_comparator.dart` |
| InvestigationTimeline | PASS | `engine/investigation_timeline.dart` |
| Run / pause / reset workflow | PASS | `ExperimentTrialManager.startTrial()`, `stopTrial()`, `resetTrial()` |
| Data snapshot capture | PASS | `TrialSnapshot.fromRuntimeSnapshot()` |
| ConclusionGenerator | PASS | `conclusions/conclusion_generator.dart` |
| Guided investigation steps | PASS | `models/investigation_step.dart` |
| Investigation workspace UI | PASS | `widgets/investigation_workspace.dart` |
| Runtime experience integration | PASS | `RuntimeExperienceWorkspace` accepts investigation services |
| Player integration | PASS | `ExperimentPlayerScreen` initializes investigation services |
| Investigation analytics | PASS | `analytics/investigation_analytics.dart` |

## Runtime Flow

```text
Run
-> ExperimentTrialManager.startTrial()
-> RuntimeWorld.start()
-> Runtime data changes
-> ExperimentTrialManager.stopTrial()
-> RuntimeWorld.createSnapshot()
-> ExperimentTrial saved
```

## Investigation Flow

```text
PredictionStore.submit()
-> Trial 1
-> Trial 2
-> TrialComparator.compare()
-> ConclusionGenerator.generate()
```

## Automated Tests

Test file:

- `test/investigation/investigation_workflow_test.dart`

Covered by analyzer:

- Trial creation and save path.
- Prediction storage.
- Trial comparison.
- Conclusion generation.

## Verification

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/cache/dart-sdk/bin/dart analyze lib/features/experiment/investigation lib/features/experiment/experience/widgets/runtime_experience_workspace.dart lib/features/experiment/presentation/screens/experiment_player_screen.dart test/investigation
```

Result: PASS.

```text
env HOME=/tmp /home/akash/Downloads/flutter/bin/flutter test test/investigation
```

Result: BLOCKED by sandbox.

Reason:

```text
/home/akash/Downloads/flutter/bin/internal/update_engine_version.sh: line 64:
/home/akash/Downloads/flutter/bin/cache/engine.stamp: Read-only file system
```

Escalated approval was requested twice, but the approval reviewer timed out both times.

## Certification Status

PARTIAL PASS.

Implementation and focused analyzer verification passed. Focused Flutter tests are present but could not be executed in this turn because Flutter needed to write to its SDK cache outside the workspace sandbox.
