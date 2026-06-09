# Variable Runtime Migration Notes

Generated: 2026-06-09

## Scope

This migration changes runtime variables from passive `Map<String, dynamic>` values into first-class `RuntimeVariable` entities.

Out of scope:

- Builder workflow changes
- Template changes
- New sensors
- Binding engine
- Rule dispatcher
- Action dispatcher
- Object runtime changes

## Existing Variable Flow Audit

### 1. VariableStore

File: `lib/features/experiment/runtime/variable_store.dart`

Previous behavior:

- Stored variables as `Map<String, dynamic>`.
- Exposed `get(id)`, `set(id, value)`, and `allVariables`.
- Not aware of variable source, update strategy, metadata, initialization, or lifecycle events.

New behavior:

- Stores variables as `Map<String, RuntimeVariable>`.
- Exposes first-class APIs:
  - `getVariable(String id)`
  - `getValue(String id)`
  - `registerVariable(RuntimeVariable variable)`
  - `updateVariable(String id, dynamic value)`
  - `removeVariable(String id)`
  - `getAllVariables()`
  - `containsVariable(String id)`
- Preserves compatibility APIs:
  - `get(String id)`
  - `set(String id, dynamic value)`
  - `allVariables`

Migration risk:

- Existing code expects raw values. Compatibility wrappers keep those paths working.
- New code should prefer `getVariable()` when metadata is needed.

### 2. RuntimeLoader

File: `lib/features/experiment/runtime/runtime_loader.dart`

Current flow:

```text
manifest.scene.variables
-> RuntimeWorld.initialize()
-> VariableStore.initialize()
-> RuntimeVariable.fromJson()
```

Migration risk:

- Loader does not need direct changes because `VariableStore.initialize()` now performs manifest-to-runtime mapping.
- If future loaders bypass `VariableStore.initialize()`, they must register `RuntimeVariable` objects explicitly.

### 3. RuntimeWorld

File: `lib/features/experiment/runtime/runtime_world.dart`

Current flow:

- Creates one shared `RuntimeEventBus`.
- Creates `VariableStore(eventBus: eventBus)`.
- Initializes variables before objects and rules.

Migration risk:

- Variable lifecycle events are emitted during initialization. Runtime UI consumers should tolerate `VariableRegistered` and `VariableInitialized` events before session start.

### 4. RuleEngine

File: `lib/features/experiment/runtime/rule_engine.dart`

Current variable access:

- `_variableStore.allVariables`
- `_variableStore.get(varId)`
- `_variableStore.set(targetVar, value)`

Compatibility:

- These paths still work.
- RuleEngine continues to see raw values through compatibility APIs.

Migration risk:

- RuleEngine still emits its older `VariableChanged` custom event for string assignment actions.
- Future rule modernization should use `updateVariable()` and remove duplicate rule-owned variable event emission.

### 5. Runtime Inspector

File: `lib/features/experiment/presentation/screens/experiment_player_screen.dart`

Previous behavior:

- Displayed only variable ID/value pairs.

New behavior:

- Displays variable name, ID, type, current value, source, update strategy, last updated timestamp, and initialized state.
- Displays analytics counters for variables registered, updated, and removed.

Migration risk:

- Large variable lists may need future virtualization, but current built-in templates are small.

### 6. ExperimentFlameGame

File: `lib/features/experiment/runtime/engine/experiment_flame_game.dart`

Current variable access:

- `runtimeWorld.variables.get('gravity')`

Compatibility:

- `get()` still returns raw values, so Flame gravity behavior remains unchanged.

Migration risk:

- Renderer does not yet subscribe to variable lifecycle events. That belongs to future binding/object-runtime sprints.

### 7. Runtime Analytics

File: `lib/features/experiment/runtime/runtime_analytics.dart`

Previous behavior:

- Counted rule executions and variable updates from event messages.

New behavior:

- Counts:
  - `variablesRegistered`
  - `variableUpdates`
  - `variablesRemoved`
- Avoids double-counting compatibility `VariableChanged` events that are emitted after `VariableUpdated`.

Migration risk:

- Analytics remains message-based. Future standardization may replace string matching with typed runtime events.

## Access Points Found

| File | Access Pattern | Compatibility Status |
| --- | --- | --- |
| `runtime_serializer.dart` | `world.variables.allVariables`, `world.variables.set()` | Compatible |
| `runtime_certification_service.dart` | `world.variables.allVariables` | Compatible |
| `experiment_flame_game.dart` | `runtimeWorld.variables.get('gravity')` | Compatible |
| `rule_engine.dart` | `_variableStore.allVariables`, `get()`, `set()` | Compatible |
| `flame_object_components.dart` | `world.variables.get(...)` | Compatible |
| `experiment_player_screen.dart` | `allVariables`, `allRuntimeVariables` | Compatible and upgraded |

## Compatibility Concerns

- Existing code should continue using raw-value wrappers until migrated.
- New runtime features should not read `allVariables` if source, strategy, or lifecycle state is required.
- `VariableStore.initialize()` emits lifecycle events for each variable. Consumers that count events must account for startup events.
- Removing variables at runtime is now supported by `removeVariable()`, but builder/runtime reference cleanup is outside this sprint.

## Migration Guidance

For old code:

```dart
final value = world.variables.get(variableId);
world.variables.set(variableId, nextValue);
```

For new code:

```dart
final variable = world.variables.getVariable(variableId);
world.variables.updateVariable(variableId, nextValue, source: 'runtime');
```

For metadata-aware UI:

```dart
for (final variable in world.variables.getAllVariables()) {
  variable.source;
  variable.updateStrategy;
  variable.lastUpdated;
}
```

## Current Limitations

- Variable metadata exists, but sensor/timer/computed behavior is not implemented in this sprint.
- Subscriptions notify variable lifecycle changes, but no binding engine consumes them yet.
- RuleEngine still owns legacy rule action execution.
- Object rendering still reads values through compatibility APIs.

