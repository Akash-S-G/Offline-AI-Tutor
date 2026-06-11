# Builder Scroll Audit Report

Generated: 2026-06-10

## Scope

Audited the Experiment Builder scroll architecture for:

- `ExperimentBuilderScreen`
- `DesignWorkspacePanel`
- `VariableEditor`
- `ObjectEditor`
- `RuleEditor`
- `TabBarView` hierarchy
- parent `SingleChildScrollView` usage
- nested `Column`, `Expanded`, and fixed-height constraints

## Widget Tree Trace

### Variables

```text
ExperimentBuilderScreen
└─ Scaffold
   └─ body: LayoutBuilder
      └─ mobile: Column
         ├─ Expanded
         │  └─ _buildWorkspaceForStep(design)
         │     └─ DesignWorkspacePanel
         │        └─ mobile: DefaultTabController(length: 4)
         │           └─ Column
         │              ├─ TabBar
         │              └─ Expanded
         │                 └─ TabBarView(physics: NeverScrollableScrollPhysics)
         │                    └─ VariableEditor
         │                       └─ Column
         │                          ├─ header Row
         │                          ├─ BuilderSearchBar
         │                          ├─ Divider
         │                          └─ Expanded
         │                             └─ ListView.builder
         └─ BottomNavigationBar
```

Scrollable widgets in path:

- `TabBar` horizontal scroll on mobile design tabs.
- `TabBarView` page view, horizontal gestures disabled on mobile.
- `VariableEditor` `ListView.builder`, vertical scroll.

Constrained-height widgets:

- `ExperimentBuilderScreen` workspace `Expanded`.
- `DesignWorkspacePanel` mobile `TabBarView` `Expanded`.
- `VariableEditor` list region `Expanded`.

Nested scroll conflict:

- Previously used `ListView.builder(primary: true)` without a local controller.
- This let the list participate in the inherited `PrimaryScrollController` from the route.

Status:

- Variables already behaved correctly in the app, but the same fragile scroll ownership pattern existed.

### Objects

```text
ExperimentBuilderScreen
└─ Scaffold
   └─ body: LayoutBuilder
      └─ mobile: Column
         ├─ Expanded
         │  └─ _buildWorkspaceForStep(design)
         │     └─ DesignWorkspacePanel
         │        └─ mobile: DefaultTabController(length: 4)
         │           └─ Column
         │              ├─ TabBar(isScrollable: true)
         │              └─ Expanded
         │                 └─ TabBarView(physics: NeverScrollableScrollPhysics)
         │                    └─ ObjectEditor
         │                       └─ Column
         │                          ├─ header Row
         │                          ├─ BuilderSearchBar
         │                          ├─ Divider
         │                          └─ Expanded
         │                             └─ ListView.builder
         └─ BottomNavigationBar
```

Scrollable widgets in path:

- Mobile design `TabBar`, horizontal.
- Mobile design `TabBarView`, horizontal page view with swipe disabled.
- `ObjectEditor` `ListView.builder`, vertical.

Constrained-height widgets:

- `ExperimentBuilderScreen` workspace `Expanded`.
- `DesignWorkspacePanel` `TabBarView` `Expanded`.
- `ObjectEditor` list `Expanded`.

Nested scroll conflict:

- `ObjectEditor` used `ListView.builder(primary: true)` inside a `TabBarView` page.
- The object list did not own a dedicated `ScrollController`.
- This made gesture/controller ownership ambiguous in the real app hierarchy, especially with sibling tab pages and route-level primary scroll behavior.

Exact faulty widget:

- `ObjectEditor` `ListView.builder(primary: true)` in the list region.

### Rules

```text
ExperimentBuilderScreen
└─ Scaffold
   └─ body: LayoutBuilder
      └─ mobile: Column
         ├─ Expanded
         │  └─ _buildWorkspaceForStep(logic)
         │     └─ RuleEditor
         │        └─ Column
         │           ├─ header Row
         │           ├─ BuilderSearchBar
         │           ├─ Divider
         │           └─ Expanded
         │              └─ ListView.builder
         └─ BottomNavigationBar
```

Scrollable widgets in path:

- `RuleEditor` `ListView.builder`, vertical.

Constrained-height widgets:

- `ExperimentBuilderScreen` workspace `Expanded`.
- `RuleEditor` list `Expanded`.

Nested scroll conflict:

- `RuleEditor` used `ListView.builder(primary: true)` without a local controller.
- The list was directly under the logic step, so the issue was not caused by the design `TabBarView`.
- The weak point was still inherited primary scroll ownership instead of editor-owned scroll state.

Exact faulty widget:

- `RuleEditor` `ListView.builder(primary: true)` in the list region.

## Root Cause

The editors relied on implicit primary scroll behavior:

```dart
ListView.builder(
  physics: AlwaysScrollableScrollPhysics(),
  primary: true,
)
```

That is fragile inside a multi-step builder shell where editors are placed under `TabBarView`, `Expanded`, bottom navigation, and route-level primary scroll context. Objects and Rules needed deterministic, editor-owned scroll controllers.

## Why The Previous UX-1 Fix Did Not Solve It

The previous UX-1 fix removed the global summary/readiness chrome from every builder step. That fixed the visible split-screen layout, but it did not change the list scroll ownership inside `VariableEditor`, `ObjectEditor`, or `RuleEditor`.

In other words:

```text
UX-1 fix:
removed extra parent height consumption

Remaining bug:
lists still used inherited primary scroll behavior
```

## Screenshot Evidence

No fresh device screenshot was captured from this environment. Verification evidence is from focused Flutter widget stress tests that create 100 Variables, 100 Objects, and 100 Rules and assert that the final item is reachable through the relevant scrollable.

## Fix Applied

Applied explicit scroll ownership to all three editors:

- `VariableEditor`
- `ObjectEditor`
- `RuleEditor`

Each list now has:

- local `ScrollController`
- `dispose()`
- stable `PageStorageKey`
- `primary: false`

## Verification

Automated stress tests added in:

```text
test/builder/builder_usability_sprint_test.dart
```

Cases:

- 100 Variables: reaches `Variable 100`
- 100 Objects through `DesignWorkspacePanel` mobile tab hierarchy: reaches `Object 100`
- 100 Rules: reaches `Rule 100`

Result:

```text
flutter test test/builder/builder_usability_sprint_test.dart
PASS

flutter analyze focused builder scroll files
PASS
```
