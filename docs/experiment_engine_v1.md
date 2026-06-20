# Experiment Engine V1 — Architecture Specification

> **STATUS: FROZEN**  
> No new concepts, systems, or engines may be added to this document without explicit approval.  
> Every future experiment must be expressible using ONLY the primitives defined here.

---

## Philosophy

Every simulation is described entirely in **JSON**. The engine is generic. There are no experiment-specific classes (`PendulumEngine`, `CircuitEngine`, etc.). The engine reads a blueprint and executes it using the shared registry of behaviors, states, effects, and interactions.

---

## Core Concepts

### Scene
The visual container for the simulation. Defines the background, actors, and overall visual preset.

```json
{
  "sceneId": "pendulum_motion_lab",
  "name": "Pendulum Motion Laboratory",
  "visualPreset": "pendulum"
}
```

### Variables
Named numeric values that hold the simulation state. Variables are the single source of truth for everything rendered on screen.

```json
{ "id": "var_length", "name": "Length", "type": "number", "value": 1.0 }
```

### Computed Variables
Variables whose value is derived from a formula over other variables. Recalculated automatically whenever a dependency changes.

```json
{ "id": "var_period", "type": "computed", "formula": "2 * PI * sqrt(var_length / 9.81)", "dependencies": ["var_length"] }
```

### Rules
Event-driven logic. A rule triggers an action when a condition is satisfied.

```json
{ "trigger": "buttonClicked", "condition": { "variable": "btn_release", "operator": "==" , "value": true }, "action": { "type": "set_variable", "variable": "var_is_swinging", "value": true } }
```

### States
Named simulation phases that describe what the experiment looks like at a high level. States drive which effects and visual mappings are active.

```json
{ "states": ["idle", "swinging", "stopped"] }
{ "states": ["clear", "cloud_forming", "heavy_cloud", "rain", "collection"] }
```

### Behaviors
Reusable physics-like motion logic applied to a scene target. Behaviors are resolved by the `BehaviorRegistry` from a string type name.

```json
{ "behaviors": [{ "type": "oscillation", "target": "pendulum", "params": { "length_var": "var_length", "angle_var": "var_angle" } }] }
```

### Effects
Visual overlays drawn by the `SceneEffectController` using `CustomPainter`. Effects are data-driven and require no experiment-specific code.

```json
{ "effects": [{ "type": "motion_trail", "target": "pendulum" }, { "type": "velocity_vector", "target": "pendulum" }] }
```

### Interactions
User input events that map to variable changes or rule triggers. Resolved by the `SceneControlsOverlay`.

```json
{ "interactions": [{ "type": "drag", "target": "pendulum_bob", "updates": "var_angle" }, { "type": "release", "target": "pendulum_bob", "triggers": "rule_release" }] }
```

### Measurements
Rows in the observation table that are recorded per trial. Always bound to variables.

```json
{ "measurements": [{ "label": "Period (s)", "variable": "var_period" }] }
```

---

## Supported Behaviors V1

| Behavior          | Description                                         |
|-------------------|-----------------------------------------------------|
| `oscillation`     | Sinusoidal back-and-forth motion driven by physics  |
| `flow`            | Directional particle flow along a path              |
| `glow`            | Brightness / opacity pulse tied to a variable       |
| `pulse`           | Periodic scale expand/contract (heartbeat)          |
| `growth`          | Vertical scale increase over time                   |
| `orbit`           | Circular path motion around a pivot                 |
| `rotation`        | Continuous angular spin                             |
| `state_transition`| Changes scene state based on variable thresholds   |

---

## Supported Effects V1

| Effect            | Description                                              |
|-------------------|----------------------------------------------------------|
| `motion_trail`    | Faded arc trace behind a moving object                   |
| `current_flow`    | Animated dots flowing along a circuit wire               |
| `rain`            | Falling water droplets from top                          |
| `water_droplets`  | Rising or falling droplets for water/evaporation         |
| `pulse_ring`      | Expanding concentric rings from center (heartbeat)       |
| `velocity_vector` | Arrow indicating instantaneous speed and direction       |

---

## Supported Interactions V1

| Interaction | Description                                         |
|-------------|-----------------------------------------------------|
| `tap`       | Single touch triggers a rule or toggles a variable  |
| `drag`      | Pan gesture maps position to a variable value       |
| `release`   | End of drag gesture triggers a rule                 |
| `toggle`    | Switch between two states on each tap               |

---

## Experiment Blueprint Structure (Full)

```json
{
  "scene": {
    "sceneId": "...",
    "name": "...",
    "visualPreset": "...",
    "variables": [...],
    "states": [...],
    "behaviors": [...],
    "effects": [...],
    "interactions": [...],
    "rules": [...],
    "measurements": [...],
    "mission": { ... },
    "assessment": { ... }
  }
}
```

---

## What Is Explicitly Forbidden

- `PendulumEngine`, `CircuitEngine`, `WaterCycleEngine`, `PlantEngine`, or any experiment-specific runtime class
- Scene-specific `if/else` blocks in engine code (use registered type dispatch instead)
- Adding a new system when an existing behavior/effect/interaction can be reused

---

## Validation Test

Before implementing a new experiment, ask:

> Can this experiment be described using Scene + Variables + Behaviors + States + Effects + Interactions?

- **Yes** → JSON only. No new Dart classes.
- **No** → Add exactly ONE new reusable behavior or effect to the registry. Update this document.
