# Frontend Dead Code Report

**Generated:** 2026-06-09

---

## Unused Screens

| Screen | Path | Status | Confidence | Notes |
|--------|------|--------|------------|-------|
| `GradeSyncScreen` | `lib/features/onboarding/presentation/grade_sync_screen.dart` | Likely Unused | **80%** | Not referenced in `main.dart` or any route definitions. Only class definition found in file tree. |
| `BuilderDraftsScreen` | `lib/features/experiment/builder/widgets/builder_drafts_screen.dart` | Potentially Unused as Screen | **65%** | Defined as a widget, but not confirmed as a top-level screen. May be used as a dialog or panel. |

## Unused Routes

| Route | Status | Confidence | Notes |
|-------|--------|------------|-------|
| Named routes (e.g., `'/home'`) | Not Implemented | **FACT** | `main.dart` uses only `home: AppShell` and programmatic `Navigator.push`. Deep-linking is not supported. |

## Unused Services

| Service | Path | Status | Confidence | Notes |
|---------|------|--------|------------|-------|
| `RuntimeCertificationService` | `lib/features/experiment/runtime/runtime_certification_service.dart` | Likely Unused | **75%** | File exists in tree but not imported in any grep results. May be a planned feature. |
| `OfflineTutorService` | `lib/features/educational/application/offline_tutor_service.dart` | Potentially Legacy | **60%** | Master service file found, but active consumers directly use `LocalSearchService` and `ChatScreen` components. |
| `RuntimeMode` | `lib/bootstrap/runtime_mode.dart` | Check Needed | **50%** | Utility for `CriticalBootstrap`; exact usage not fully verified. |

## Unused Repositories

| Repository | Path | Status | Confidence | Notes |
|------------|------|--------|------------|-------|
| `ExperimentProgressRepository` | `lib/features/experiment/domain/experiment_progress_repository.dart` | Check Needed | **50%** | Interface exists. Concrete implementation may be in another file or used via injection. |
| `ExperimentTemplateRepository` | `lib/features/experiment/domain/repositories/experiment_template_repository.dart` | Check Needed | **50%** | Interface exists. Concrete implementation not confirmed in immediate search. |
| `AiExperimentRepository` | `lib/features/experiment/builder/ai/repositories/ai_experiment_repository.dart` | Check Needed | **50%** | Used by `AiGeneratorController` (LIKELY used). |

## Deprecated Components

| Component | Path | Status | Confidence | Notes |
|-----------|------|--------|------------|-------|
| `_LegacyClassification` | `lib/features/network/application/query_classifier.dart` | Deprecated | **90%** | Class name explicitly includes "Legacy". |
| `course_tree.dart` models | `lib/features/course/domain/course_tree.dart` | Overlapping with curriculum_models | **80%** | `Course`, `Subject`, `Chapter` defined here and also in `curriculum_models.dart`. Potential duplication. |
| `_empty_state.dart` reference | `lib/features/shared/presentation/widgets/` | Check Needed | **50%** | Design system widget that may be unused in current builds. |

## Recommendations

1. **Named Routes**: If deep-linking is desired, migrate from programmatic `Navigator.push` to `GoRouter` or `MaterialApp.routes`.
2. **Dead Screens**: Verify `GradeSyncScreen` and `BuilderDraftsScreen` with product requirements. If truly unused, mark for deletion to reduce binary size and maintenance overhead.
3. **Legacy Models**: Audit `course_tree.dart` and `curriculum_models.dart` for duplication. Unify into a single source of truth if possible.
4. **Service Cleanup**: Investigate `RuntimeCertificationService`. If it is part of a roadmap, leave it; otherwise, remove it.
