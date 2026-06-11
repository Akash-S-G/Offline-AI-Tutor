# Builder Scroll Fix Report

Generated: 2026-06-10

## Problem

Variables scrolled correctly, but Objects and Rules could not reliably scroll to the end of large collections in the real Experiment Builder UI.

The rejected UX-1 certification was correct: the previous verification only proved Variables, and it did not exercise Objects or Rules through their actual parent hierarchy.

## Files Changed

```text
lib/features/experiment/builder/widgets/variable_editor.dart
lib/features/experiment/builder/widgets/object_editor.dart
lib/features/experiment/builder/widgets/rule_editor.dart
test/builder/builder_usability_sprint_test.dart
```

## Fix

Each editor list now owns its own scroll state.

Before:

```dart
ListView.builder(
  physics: const AlwaysScrollableScrollPhysics(),
  primary: true,
)
```

After:

```dart
final ScrollController _scrollController = ScrollController();

ListView.builder(
  key: const PageStorageKey<String>('builder_objects_list'),
  controller: _scrollController,
  physics: const AlwaysScrollableScrollPhysics(),
  primary: false,
)
```

Applied equivalent keys/controllers:

- `builder_variables_list`
- `builder_objects_list`
- `builder_rules_list`

## Why This Fix Works

The editors no longer depend on an inherited route-level `PrimaryScrollController`.

This matters because the real builder is layered:

```text
Scaffold
→ responsive builder shell
→ bottom navigation / workflow sidebar
→ TabBarView
→ editor Column
→ Expanded list
```

With explicit controllers, vertical drag gestures and scroll offsets belong to the active editor list instead of an implicit parent scroll context.

## Stress Test Data

Automated test data now creates:

- 100 Variables
- 100 Objects
- 100 Rules

## Reachability Tests

Added widget tests that fail if the last item cannot be reached:

```text
large variable list can reach the last item
large object list can reach the last item in Design tabs
large rule list can reach the last item
```

The Object test specifically uses `DesignWorkspacePanel` at mobile width so it exercises:

```text
DesignWorkspacePanel
→ mobile DefaultTabController
→ mobile TabBarView
→ ObjectEditor
→ Object list
```

## Verification Commands

```text
dart format
flutter analyze lib/features/experiment/builder/widgets/variable_editor.dart lib/features/experiment/builder/widgets/object_editor.dart lib/features/experiment/builder/widgets/rule_editor.dart lib/features/experiment/builder/widgets/design_workspace_panel.dart test/builder/builder_usability_sprint_test.dart
flutter test test/builder/builder_usability_sprint_test.dart
```

## Results

```text
dart format
PASS

focused flutter analyze
PASS

flutter test test/builder/builder_usability_sprint_test.dart
PASS
```

## Manual Verification Status

Manual on-device dragging cannot be performed from this execution environment. The implemented proof is a deterministic Flutter widget stress test that scrolls each production list to its final item.

Required app-side manual checklist for the next phone run:

- Open Experiment Builder.
- Add/import at least 100 Variables and confirm the last variable is reachable.
- Open Design → Objects and confirm the last object is reachable.
- Open Logic and confirm the last rule is reachable.

## Certification Decision

UX-1 scrolling certification is now supported by automated reachability tests for Variables, Objects, and Rules. Final on-device manual certification should be marked complete after the phone checklist above is performed.
