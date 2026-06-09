# Experiment Runtime Specification V1

Generated: 2026-06-09

This document is the V1 runtime contract for the IDP Experiment Engine. It defines how declared builder and template capabilities should behave at runtime before new runtime code is implemented.

Source documents:

- `EXPERIMENT_RUNTIME_AUDIT.md`
- `RUNTIME_CAPABILITY_MATRIX.md`
- `RUNTIME_DEPENDENCY_GRAPH.md`

Scope rule: this is a specification only. It does not change runtime, builder, or UI code.

## 1. Runtime Architecture

### RuntimeWorld

RuntimeWorld is the root execution container for one experiment session. It owns the variable store, object registry, rule engine, event bus, simulation clock, analytics, and renderer-facing runtime state.

Responsibilities:

- Load a validated manifest into runtime state.
- Maintain one active session lifecycle: prepared, running, paused, stopped, failed, completed.
- Advance the simulation on every tick while running.
- Coordinate rule evaluation, object updates, event dispatch, and rendering.
- Preserve deterministic behavior when the same manifest and inputs are replayed.

### VariableStore

VariableStore is the canonical runtime storage for variable values.

Responsibilities:

- Store every manifest variable by stable variable ID.
- Preserve variable metadata: name, type, unit, category, source, validation constraints, and dependencies.
- Emit `variableChanged` events when a value changes.
- Reject updates that violate type, mutability, range, permission, or dependency rules.
- Provide read access to rules, objects, renderer components, and analytics.

### ObjectRegistry

ObjectRegistry is the canonical runtime storage for objects.

Responsibilities:

- Store every manifest object by stable object ID.
- Preserve object metadata: name, type, position, size, bindings, supported actions, visibility, and object-specific state.
- Resolve object-to-variable bindings before runtime starts.
- Apply action mutations such as hide, reset, force, impulse, or display updates.
- Emit object update events when object state changes.

### RuleEngine

RuleEngine evaluates rules and dispatches actions.

Responsibilities:

- Load every manifest rule by stable rule ID.
- Validate condition dependencies before runtime start.
- Evaluate rules according to trigger type and frequency.
- Emit `ruleExecuted` for every evaluated rule with result true or false.
- Dispatch actions only after a rule evaluates true.
- Report failures as runtime errors without crashing the session loop.

### EventBus

EventBus is the shared runtime event stream.

Responsibilities:

- Publish lifecycle, variable, measurement, warning, error, rule, interaction, and custom events.
- Preserve event order per tick.
- Attach timestamps using SimulationClock time and wall-clock time where needed.
- Support UI observability: runtime health, event feed, rule feed, error panel, counters, and analytics.

### SimulationClock

SimulationClock is the time authority for the session.

Responsibilities:

- Track elapsed simulation time.
- Support pause, resume, reset, and stop.
- Provide delta time to RuntimeWorld and RuleEngine.
- Drive timer variables and timer rules.
- Prevent paused time from changing timer-backed values.

### Object Renderer

Object Renderer converts ObjectRegistry state into visible simulation components.

Responsibilities:

- Render every V1 Required object with a meaningful visual representation.
- Render unsupported or future objects as explicit unsupported placeholders, not silent fake behavior.
- Keep visuals synchronized with variable bindings and object state.
- Emit render failure events if an object cannot be displayed.

### Sensor Layer

Sensor Layer binds device sensor providers to runtime variables.

Responsibilities:

- Start only the sensor providers required by manifest variables.
- Request permissions before runtime start where required.
- Degrade gracefully when a sensor is unavailable.
- Emit `measurementReceived`, `variableChanged`, `warning`, or `error` events based on sensor status.
- Stop providers when the session stops.

### Lifecycle Contract

```text
Manifest Load
-> Validation
-> Runtime Preparation
-> Runtime Start
-> Tick Loop
-> Rule Evaluation
-> Object Updates
-> Event Dispatch
-> Render
```

Manifest Load parses the manifest and extracts scene, variables, objects, and rules.

Validation rejects empty manifests, duplicate IDs, missing references, invalid bindings, unsupported required capabilities, and malformed rule/action payloads.

Runtime Preparation initializes VariableStore, ObjectRegistry, RuleEngine, EventBus, SimulationClock, Sensor Layer, and renderer components. Preparation must not start time.

Runtime Start begins the clock, starts required sensors, emits `sessionStarted`, and enters the tick loop.

Tick Loop advances time, updates timer/sensor/computed variables, evaluates rules, applies actions, emits events, and schedules render updates.

Pause freezes SimulationClock and timer variables. Sensor behavior is capability-specific: sensors may keep listening but must not mutate paused simulation variables unless marked as real-time monitoring.

Resume continues SimulationClock and normal updates.

Stop terminates sensor subscriptions, stops the clock, emits `sessionStopped`, and freezes final state.

Failure sets status to failed, emits `error`, preserves the latest error, and keeps the last known state inspectable.

## 2. Variable Specification

All variables share this base runtime model:

- Runtime State Model: `{ id, name, type, category, value, unit, source, mutable, dependencies, validation, lastUpdatedAt }`.
- Storage Type: JSON-compatible scalar, vector, map, list, or null, depending on type.
- Initialization: use manifest value if valid; otherwise use the type default or fail validation if no safe default exists.
- Update Mechanism: static assignment, user input, sensor stream, computed recalculation, or clock tick.
- Events Emitted: `variableChanged` on value change; `warning` for degraded behavior; `error` for invalid updates.
- Dependencies: referenced variables, sensors, clock, permissions, renderer controls, and rules.

### Sensor Variables

Sensor variables bind device measurements to VariableStore. Default update frequency is 10 Hz for motion sensors, 1 Hz for GPS, and provider-defined for future sensors. If a sensor is unavailable, the variable enters degraded state, emits `warning`, and uses its initial value. If permission fails, runtime preparation fails only when the experiment marks the sensor as required; otherwise it starts in degraded mode.

| Variable | Purpose | Runtime State Model | Storage Type | Initialization | Update Mechanism | Events Emitted | Dependencies | Educational Use Cases | Example Experiment | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| accelerometer | Measure device acceleration | latest x/y/z vector plus magnitude | map `{x,y,z,magnitude}` | `{0,0,0,0}` or manifest value | sensor stream at 10 Hz | measurementReceived, variableChanged, warning/error | `sensors_plus`, permission-free device sensor | free fall, motion, acceleration | Free Fall | V1 Required |
| gyroscope | Measure rotation rate | latest x/y/z angular velocity | map `{x,y,z}` | `{0,0,0}` | sensor stream at 10 Hz | measurementReceived, variableChanged | `sensors_plus` | angular motion, rotation | Pendulum comparison | V1 Optional |
| magnetometer | Measure magnetic field | latest x/y/z magnetic vector | map `{x,y,z}` | `{0,0,0}` | sensor stream at 5-10 Hz | measurementReceived, variableChanged | `sensors_plus` | compass, magnetic field | Field mapping | Future |
| gps | Measure location | latitude, longitude, altitude, speed, accuracy | map | null or manifest default | location stream at 1 Hz | measurementReceived, variableChanged, warning/error | `geolocator`, location permission | field studies, speed, mapping | Outdoor motion | Future |
| microphone | Measure sound signal | amplitude and optional frequency summary | map `{amplitude, frequency}` | unavailable state | future audio stream | warning/error | microphone permission, audio provider | sound, resonance | Oscilloscope | Future |
| lightSensor | Measure light intensity | lux or normalized value | number | unavailable state | future light provider | warning/error | light sensor provider | photosynthesis, inverse-square law | Plant Growth | Future |
| proximity | Detect nearby object | boolean or distance estimate | boolean/number | unavailable state | future proximity provider | warning/error | proximity provider | near/far interaction | Reaction trigger | Future |

### User Input Variables

User input variables render runtime controls when the experiment is running. Controls must be reachable in portrait and landscape layouts.

| Variable | Purpose | Runtime State Model | Storage Type | Initialization | Update Mechanism | Events Emitted | Dependencies | Educational Use Cases | Example Experiment | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| slider | Let learner change a numeric value | numeric value with min/max/step | number | manifest value or min | runtime slider control | variableChanged, interaction | Flutter control panel | change mass, angle, speed | Pendulum Motion | V1 Required |
| textInput | Let learner enter text | string with optional max length | string | manifest value or empty | runtime text field | variableChanged, interaction | Flutter control panel | labels, hypotheses | Lab notes | V1 Optional |
| numberInput | Let learner enter numeric data | number with range/unit | number | manifest value or 0 | runtime numeric input | variableChanged, interaction | Flutter control panel | temperature, pulse, angle | Heart Rate Monitor | V1 Required |
| dropdown | Let learner choose a category | selected option key | string | manifest value or first option | runtime dropdown | variableChanged, interaction | option list | material/category selection | Ohm's Law material choice | Future |
| toggle | Let learner switch boolean state | boolean | boolean | manifest value or false | runtime switch | variableChanged, interaction | Flutter control panel | on/off circuit, visibility | Water Cycle layer toggle | V1 Optional |

Validation rules: user input must match declared type, range, allowed options, and mutability. Invalid input must be rejected with a user-friendly error and no state mutation.

### Computed Variables

Computed variables are recalculated from dependencies. Formula storage model is `{ expression, dependencyIds, unit, precision, recalculationPolicy }`. Recalculation triggers whenever a dependency changes and once per tick for clock-dependent formulas.

| Variable | Purpose | Runtime State Model | Storage Type | Initialization | Update Mechanism | Events Emitted | Dependencies | Educational Use Cases | Example Experiment | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| average | Mean of samples or variables | value plus sample count/window | number | 0 or average of initial dependencies | dependency change/window update | variableChanged | source variables/history | smooth readings | Heart Rate average | V1 Optional |
| minimum | Lowest observed value | value plus source/time | number | first sample or manifest value | dependency/history update | variableChanged | source variables/history | minimum temperature/speed | Cooling experiment | V1 Optional |
| maximum | Highest observed value | value plus source/time | number | first sample or manifest value | dependency/history update | variableChanged | source variables/history | peak acceleration/pulse | Free Fall | V1 Optional |
| velocity | Change in position over time | numeric/vector velocity | number/map | 0 | formula from distance/time | variableChanged | distance, elapsedTime | motion | Free Fall | V1 Required |
| acceleration | Change in velocity over time | numeric/vector acceleration | number/map | 0 | formula from velocity/time or sensor | variableChanged | velocity, elapsedTime/sensor | Newton's laws | Free Fall | V1 Required |
| distance | Position/path length | numeric distance | number | 0 | formula or sensor/GPS integration | variableChanged | position/time/speed | motion tracking | Free Fall | V1 Required |
| force | Mass times acceleration | numeric/vector force | number/map | 0 | formula `mass * acceleration` | variableChanged | mass, acceleration | Newton's second law | Hooke's Law | V1 Optional |
| power | Energy per time | numeric power | number | 0 | formula `energy / time` | variableChanged | energy, elapsedTime | energy transfer | Electrical labs | Future |
| energy | Work/kinetic/potential energy | numeric energy | number | 0 | declared formula | variableChanged | mass, height, velocity, constants | potential/kinetic energy | Free Fall | V1 Optional |

Failure handling: missing dependencies fail validation. Division by zero, non-numeric dependencies, or formula parse errors emit `error` and keep the last valid value.

### Timer Variables

Timer variables integrate with SimulationClock. They update at least once per rendered second for UI displays and may update every tick for rules.

| Variable | Purpose | Runtime State Model | Storage Type | Initialization | Update Mechanism | Events Emitted | Dependencies | Educational Use Cases | Example Experiment | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elapsedTime | Time since session start | seconds elapsed | number | 0 | SimulationClock tick | variableChanged | SimulationClock | timing observations | Free Fall | V1 Required |
| countdown | Time remaining | seconds remaining plus completed flag | number | manifest duration | SimulationClock tick while running | variableChanged, warning/completed custom event | SimulationClock | timed challenges | Reaction timing | V1 Optional |
| interval | Periodic trigger counter | interval seconds and tick count | map/number | configured interval | SimulationClock scheduler | variableChanged, custom | SimulationClock | periodic sampling | Plant Growth sampling | V1 Optional |

Pause/resume behavior: paused sessions freeze timer values. Resume continues from the paused value.

### Constants

| Variable | Purpose | Runtime State Model | Storage Type | Initialization | Update Mechanism | Events Emitted | Dependencies | Educational Use Cases | Example Experiment | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| customConstant | Store immutable coefficient or threshold | immutable value plus unit | scalar/map | manifest value | none after preparation | none unless invalid update attempted | none | gravity, resistance, coefficients | Free Fall gravity constant | V1 Required |

Constants are immutable after runtime preparation. Attempts to change a constant emit `error`.

## 3. Object Specification

All objects share this base runtime model:

- Runtime State: `{ id, name, type, position, size, visible, bindings, properties, renderState, lastUpdatedAt }`.
- Supported Variable Bindings: object-specific map of property name to variable ID.
- Supported Events: objectCreated, objectUpdated, interaction, warning, error, custom.
- Update Behavior: refresh bound values after variable updates and before render.

### Visualization Objects

| Object | Purpose | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lineGraph | Plot continuous values over time | axes, line, labels, units | x variable, y variable, optional series | reset, start_recording, stop_recording | variableChanged, custom | append samples to bounded history at max 30 Hz | motion, growth, sensor trends | Free Fall, Plant Growth | V1 Required |
| barChart | Compare categorical or discrete values | bars, labels, scale | category/value series | reset | variableChanged | redraw on bound value change | compare groups | Ohm's Law readings | V1 Optional |
| scatterPlot | Show relationship between two variables | points, axes, trend optional | x variable, y variable | reset, start_recording, stop_recording | variableChanged | append pairs to bounded history | correlation | Hooke's Law | Future |

History storage: visualization objects keep bounded in-memory history per session. V1 Required history minimum is 300 samples per series. Rendering may downsample but must not corrupt stored values.

### Display Objects

| Object | Purpose | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| textDisplay | Show text or explanation | text label/panel | text variable or static text | hide_object, reset | objectUpdated | rerender on text/value change | instructions, labels | Water Cycle | V1 Optional |
| numericDisplay | Show a numeric reading | number with unit and label | numeric variable | hide_object, reset | variableChanged | format and rerender on value change | temperature, speed, pulse | Heart Rate Monitor | V1 Required |
| table | Show tabular observations | rows/columns | variables or recorded samples | reset, start_recording, stop_recording | custom | append rows on interval/rule event | lab notebooks | Boiling Water | Future |

### Interactive Objects

Interactive objects produce `interaction` events and may update variables directly.

| Object | Purpose | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| button | Trigger learner action | tappable button | optional target variable/rule | reset, hide_object | interaction, custom | emits event on press | start/stop, mark observation | Timer Events | V1 Required |
| slider | Manipulate numeric value | runtime slider | numeric variable | reset | interaction, variableChanged | updates variable on change | change parameters | Pendulum Motion | V1 Required |
| toggle | Manipulate boolean value | switch/toggle | boolean variable | reset | interaction, variableChanged | updates variable on change | layer on/off | Water Cycle | V1 Optional |

### Indicator Objects

| Object | Purpose | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gauge | Show current value in a range | arc/needle/value label | numeric variable, min, max | reset, hide_object | variableChanged, warning | update needle/value on change | temperature, heart rate, speed | Heart Rate Monitor, Boiling Water | V1 Required |
| counter | Count events or pulses | numeric counter with label | count variable or event source | reset | interaction, custom | increment on configured event | button presses, pulse counts | Heart Rate Monitor | V1 Optional |
| progressBar | Show progress toward target | horizontal/vertical bar | numeric variable, min, max | reset | variableChanged | fill based on normalized value | completion, growth, countdown | Plant Growth | V1 Optional |

Visual state model: indicators store `currentValue`, `normalizedValue`, `label`, `unit`, `thresholdState`, and `lastUpdatedAt`.

### Scientific Objects

| Object | Purpose | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| oscilloscope | Show waveform over time | scrolling waveform grid | signal/amplitude variable | reset, start_recording, stop_recording | measurementReceived | append waveform samples | sound, electricity | Microphone signal | Future |
| spectrumAnalyzer | Show frequency magnitude | frequency bars/spectrum | signal/frequency variables | reset | measurementReceived | update spectrum window | acoustics | Sound frequency | Future |
| vectorVisualizer | Show direction and magnitude | arrow/vector field | x/y/z or magnitude/angle variables | reset | variableChanged | redraw vector on change | force, velocity, acceleration | Free Fall forces | V1 Optional |

Educational simplification: scientific objects should prioritize readable classroom visuals over professional instrument fidelity.

### Runtime Objects

| Object | Purpose | Runtime State | Visual Representation | Supported Variable Bindings | Supported Actions | Supported Events | Update Behavior | Educational Use Cases | Example Experiments | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| physics_ball | Simulate body under gravity/forces | position, velocity, mass, radius, force accumulator | circle/body on physics canvas | mass, position, velocity, acceleration | applyForce, applyImpulse, reset | objectUpdated, collision custom | physics tick integration | free fall, collisions | Free Fall | V1 Required |
| pendulumSimulation | Simulate pendulum angle/length | angle, angular velocity, length, gravity | pivot, rod, bob | angle, length, gravity | reset | objectUpdated | tick physics or update from bound angle | periodic motion | Pendulum Motion | V1 Required |
| plantSimulation | Show simplified plant growth | growth stage, water, sunlight | plant stem/leaves/stage | water, sunlight, elapsedTime | reset | objectUpdated | recompute growth state on variable/timer change | biology, growth factors | Plant Growth | V1 Required |
| interactiveDiagram | Show labeled process diagram | nodes, arrows, active step | step/state variables | hide_object, reset | interaction, objectUpdated | highlight active phase | cycles/processes | Water Cycle | V1 Required |
| circle | Basic shape primitive | position, radius, color | circle | optional numeric/color bindings | hide_object, reset | objectUpdated | rerender on state change | simple markers | Geometry marker | V1 Optional |

## 4. Rule Specification

All rules share this base model:

- Trigger Conditions: rule-specific trigger plus optional enabled flag.
- Evaluation Frequency: continuous every tick, scheduled interval, or event-driven.
- Supported Conditions: map condition with variable refs, comparison operator, literal values, expressions, or event payload match.
- Supported Actions: V1 action dispatcher action map or string assignment.
- Failure Handling: emit `error`, mark rule evaluation failed, preserve session unless failure is fatal.
- Example Usage: educational scenario requiring automation or feedback.

| Rule Type | Trigger Conditions | Evaluation Frequency | Supported Conditions | Supported Actions | Failure Handling | Example Usage | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- | --- |
| threshold | variable crosses limit | every tick or on variable change | `>`, `>=`, `<`, `<=`, `==`, `!=` against literal | show_warning, set_variable, hide_object | missing variable fails validation; invalid type emits error | temperature > 100 shows warning | V1 Required |
| comparison | compare two variables/values | on dependency change | variable-to-variable or variable-to-literal comparison | show_warning, set_variable, hide_object | missing dependency fails validation | voltage/current relationship | V1 Required |
| timer | elapsed time or interval reached | SimulationClock schedule | elapsed, countdown, interval count | show_warning, set_variable, start_recording, stop_recording | invalid duration fails validation | record data every 5 seconds | V1 Required |
| sensorEvent | sensor payload matches pattern | on measurement event | sensor unavailable, threshold, spike, shake/drop pattern | show_warning, set_variable, start_recording | unavailable required sensor fails preparation | free fall acceleration spike | V1 Optional |
| buttonEvent | learner presses button | on interaction event | object ID and optional button state | set_variable, start_recording, stop_recording, reset | missing button object fails validation | start timer on button press | V1 Required |
| calculation | expression produces value | on dependency change or every tick | formula expression with dependencies | set_variable | parse error emits error and keeps previous value | compute velocity from distance/time | V1 Required |
| visibility | condition controls visibility | on dependency change | boolean or comparison | hide_object/show object equivalent | missing object fails validation | reveal explanation after threshold | V1 Optional |
| dataCollection | start/stop/save sample history | event-driven or timer-driven | recording state, interval, target variables | start_recording, stop_recording | missing target fails validation | collect boiling water temperature | V1 Optional |

Rule result payload must include `{ ruleId, ruleName, result, actionType, simulationTime, timestamp, error? }`.

## 5. Action Specification

All actions share this base model:

- Input Parameters: action type plus named parameters.
- Runtime Effects: mutation to variables, objects, recorder state, warning state, or physics state.
- Events Emitted: `ruleExecuted` first, then action-specific events.
- UI Impact: visible status, warning, object change, control change, feed entry, or none.
- Educational Use Cases: explicit learner feedback or simulation behavior.

| Action | Input Parameters | Runtime Effects | Events Emitted | UI Impact | Educational Use Cases | V1 Scope |
| --- | --- | --- | --- | --- | --- | --- |
| show_warning | message, severity, optional target object/variable | creates warning state; does not mutate variable | warning, custom | visible warning panel/feed entry | alert unsafe/high values | V1 Required |
| hide_object | objectId, hidden boolean default true | sets object visible false/true | objectUpdated, custom | object disappears/reappears | reveal/hide labels or explanations | V1 Optional |
| start_recording | target variable IDs, optional objectId, sample interval | recorder begins collecting samples | custom, variableChanged if recorder state variable exists | recording indicator/feed | data logging | V1 Optional |
| stop_recording | recorderId or target objectId | recorder stops collecting samples | custom | recording indicator stops; table/graph freezes | compare collected observations | V1 Optional |
| set_variable | variableId, value or expression | updates mutable variable | variableChanged, custom | bound controls/objects update | computed values, counters, state machines | V1 Required |
| applyForce | objectId, vector force, duration optional | adds force to physics object | objectUpdated, custom | physics body accelerates | Newton's laws | V1 Optional |
| applyImpulse | objectId, vector impulse | applies instant impulse to physics object | objectUpdated, custom | physics body velocity changes | momentum/collision | V1 Optional |
| reset | target object/session/recorder variable | restores target to initial state | objectUpdated, variableChanged, custom | visual state resets | repeat trials | V1 Required |

Action dispatch contract: unknown action types emit `error` and are shown in the Last Error panel. They must not be silently treated as successful.

## 6. Event Specification

All events use this base payload:

```text
{
  id,
  type,
  timestamp,
  simulationTime,
  source,
  message,
  payload
}
```

| Event | Producer | Payload Structure | Consumers | UI Representation | V1 Scope |
| --- | --- | --- | --- | --- | --- |
| sessionCreated | RuntimeWorld/Player controller | sessionId, manifestId, sceneName | health card, analytics | Runtime Health: Manifest Loaded | V1 Required |
| sessionStarted | RuntimeWorld | sessionId, startTime | status indicator, event feed | RUNNING status, Runtime Events | V1 Required |
| sessionPaused | RuntimeWorld | sessionId, elapsedTime | status indicator, event feed | PAUSED status | V1 Required |
| sessionResumed | RuntimeWorld | sessionId, elapsedTime | status indicator, event feed | RUNNING status | V1 Required |
| sessionStopped | RuntimeWorld | sessionId, elapsedTime, reason | status indicator, report | STOPPED/READY status | V1 Required |
| sessionCompleted | RuntimeWorld or rule/action | sessionId, result, elapsedTime | report, analytics | completed feed entry | V1 Optional |
| measurementReceived | Sensor Layer | sensorType, variableId, value, unit, quality | VariableStore, event monitor | Sensor Updates count/feed | V1 Required for accelerometer |
| warning | RuleEngine/Sensor Layer/Validator | message, severity, targetId | warning panel, event feed | warning card/feed row | V1 Required |
| error | any runtime component | message, userMessage, targetId, stack optional | Last Error panel, health card | FAILED state/error panel | V1 Required |
| variableChanged | VariableStore | variableId, name, oldValue, newValue, unit | objects, rules, monitor | Variable Monitor/Event Feed | V1 Required |
| ruleExecuted | RuleEngine | ruleId, name, result, action, error optional | rule feed, analytics | Rule Execution Feed row | V1 Required |
| interaction | interactive object/control | objectId/controlId, interactionType, value | RuleEngine, analytics | Button Presses/interaction feed | V1 Required |
| custom | any extension producer | name, payload | debug tools, analytics | Runtime Events feed | V1 Optional |

Runtime events must not require ADB logcat or backend logs to understand session state.

## 7. Educational Mapping

| Capability | Why It Exists Educationally | Example Uses |
| --- | --- | --- |
| Sensor variables | Connect real device measurements to scientific observation | acceleration, rotation, location, sound, light |
| User input variables | Let learners manipulate hypotheses and parameters | mass, angle, temperature, switch state |
| Computed variables | Teach relationships between measured quantities | velocity, force, energy, average |
| Timer variables | Support observation over time | reaction timing, growth, boiling curves |
| Constants | Represent fixed scientific values | gravity, resistance, coefficients |
| Gauge | Make a live scalar value easy to read | temperature, heart rate, speed |
| Graph | Show change and trend over time | motion, plant growth, electrical readings |
| Numeric display | Provide precise measurement value | pulse, angle, time |
| Button | Let the learner start/mark/trigger events | trial start, observation mark |
| Slider | Let learners explore parameter changes | pendulum length, mass, initial angle |
| Toggle | Represent binary states | light on/off, layer visible |
| Physics object | Make physical laws visible | falling body, force, impulse |
| Pendulum simulation | Demonstrate periodic motion | angle, length, gravity |
| Plant simulation | Demonstrate dependency of growth on conditions | water, sunlight, elapsed time |
| Interactive diagram | Explain process cycles and causal steps | water cycle, heart circulation |
| Threshold rule | Provide immediate feedback when a value crosses a limit | boiling point, high heart rate |
| Calculation rule | Turn observations into derived scientific quantities | velocity, acceleration, energy |
| Timer rule | Support periodic data collection and timed state changes | sample every 5 seconds |
| Event feed | Make invisible runtime behavior inspectable | timer tick, rule fired, sensor update |
| Error surface | Make failure understandable without developer tools | missing variable, sensor permission failure |

## 8. Reference Experiment Mapping

| Experiment | Variables | Objects | Rules | Actions | Events | Required Runtime Capabilities |
| --- | --- | --- | --- | --- | --- | --- |
| Free Fall | Acceleration, Velocity, Distance, Elapsed Time, Gravity constant | physics_ball, lineGraph, numericDisplay/vectorVisualizer | threshold, calculation, timer | set_variable, show_warning, reset | sessionStarted, variableChanged, measurementReceived, ruleExecuted, warning | accelerometer binding, clock, physics body, graph history |
| Pendulum Motion | Angle, Length, Elapsed Time, Gravity constant | pendulumSimulation, slider, lineGraph | comparison, timer, calculation | set_variable, reset | interaction, variableChanged, ruleExecuted | slider input, pendulum renderer, timer |
| Hooke's Law | Force, Distance/extension, Spring constant | lineGraph, scatterPlot, numericDisplay | calculation, comparison | set_variable, show_warning | variableChanged, ruleExecuted | formula engine, graph/scatter display |
| Ohm's Law | Voltage, Current, Resistance | numericDisplay, barChart, slider | calculation, comparison | set_variable, show_warning | interaction, variableChanged, ruleExecuted | numeric inputs, formula engine |
| Plant Growth | Water, Sunlight, Growth, Elapsed Time | plantSimulation, progressBar, lineGraph | timer, threshold, calculation | set_variable, show_warning, reset | variableChanged, ruleExecuted, warning | timer variables, plant renderer, growth formula |
| Water Cycle | Temperature, Phase, Step toggle | interactiveDiagram, textDisplay, toggle | threshold, visibility | set_variable, hide_object, show_warning | interaction, variableChanged, ruleExecuted | diagram state, toggle, visibility action |
| Heart Rate Monitor | Pulse, Average Pulse, Elapsed Time | gauge, counter, numericDisplay | threshold, timer, calculation | show_warning, set_variable, start_recording | variableChanged, ruleExecuted, warning | gauge, numeric display, average |
| Boiling Water | Temperature, Elapsed Time | gauge, numericDisplay, lineGraph, table | threshold, timer, dataCollection | show_warning, start_recording, stop_recording | variableChanged, ruleExecuted, warning, custom | timer, graph/table history, threshold warnings |

## 9. V1 Scope Definition

### V1 Required

Variables:

- accelerometer
- slider
- numberInput
- customConstant
- elapsedTime
- velocity
- acceleration
- distance

Objects:

- lineGraph
- numericDisplay
- button
- slider
- gauge
- physics_ball
- pendulumSimulation
- plantSimulation
- interactiveDiagram

Rules:

- threshold
- comparison
- timer
- buttonEvent
- calculation

Actions:

- show_warning
- set_variable
- reset

Events:

- sessionCreated
- sessionStarted
- sessionPaused
- sessionResumed
- sessionStopped
- measurementReceived
- warning
- error
- variableChanged
- ruleExecuted
- interaction

Reason: these capabilities are enough to certify Free Fall, Pendulum Motion, Plant Growth, Water Cycle, Heart Rate Monitor, Hooke's Law, Ohm's Law, and Boiling Water without implementing every advanced sensor or scientific visualization.

### V1 Optional

Variables:

- gyroscope
- textInput
- toggle
- average
- minimum
- maximum
- force
- energy
- countdown
- interval

Objects:

- barChart
- textDisplay
- toggle
- counter
- progressBar
- vectorVisualizer
- circle

Rules:

- sensorEvent
- visibility
- dataCollection

Actions:

- hide_object
- start_recording
- stop_recording
- applyForce
- applyImpulse

Events:

- sessionCompleted
- custom

Reason: these add useful learning value but are not required for the first runtime proof if V1 Required capabilities are complete.

### Future

Variables:

- magnetometer
- gps
- microphone
- lightSensor
- proximity
- dropdown
- power

Objects:

- scatterPlot
- table
- oscilloscope
- spectrumAnalyzer

Reason: these require additional provider, permission, recorder, or rendering systems and should wait until the V1 core runtime is proven.

## Implementation Dependency Summary

| Component | Required Dependencies | Notes |
| --- | --- | --- |
| RuntimeWorld | VariableStore, ObjectRegistry, RuleEngine, EventBus, SimulationClock | Root coordinator |
| VariableStore | manifest variables, validation, EventBus | Source of truth for values |
| ObjectRegistry | manifest objects, variable refs, EventBus | Source of truth for object state |
| RuleEngine | VariableStore, ObjectRegistry, EventBus, MathEvaluatorService, SimulationClock | Evaluates triggers and dispatches actions |
| Object Renderer | ObjectRegistry, VariableStore, Flame/Forge2D | Draws simulation state |
| Sensor Layer | SensorManager, providers, permissions, VariableStore, EventBus | Binds live device measurements |
| Recorder/History | EventBus, VariableStore, visualization objects | Needed for graphs, tables, data collection |
| Runtime UI Observability | EventBus, analytics, health status | Required to debug without logs |

## Validation Requirements

Runtime validation must reject:

- Empty manifest.
- Missing scene.
- Missing or duplicate variable IDs.
- Missing or duplicate object IDs.
- Missing or duplicate rule IDs.
- Object bindings to non-existent variables.
- Rule conditions referencing non-existent variables or objects.
- Actions referencing non-existent variables, objects, or recorders.
- V1 Required object/rule/action types without runtime support.
- Sensor variables marked required when the sensor or permission is unavailable.
- Computed variables with missing dependencies or invalid formulas.

Validation errors must be user-friendly. Example:

```text
Object "Manual Gauge" references missing variable "Temperature".
```

not:

```text
var_manual_5a1340c6...
```

## Runtime Observability Requirements

Every runtime session must expose:

- Runtime status: READY, RUNNING, PAUSED, FAILED, STOPPED, COMPLETED.
- Runtime health checklist: Manifest Loaded, Objects Loaded, Variables Loaded, Rules Loaded, Runtime Prepared, Simulation Running.
- Runtime summary: object count, variable count, rule count, event count, FPS.
- Last Error panel with user message, technical message, target ID/name, and timestamp.
- Rule Execution Feed with time, rule, result, and action.
- Event Feed with lifecycle, timer, sensor, rule, variable, interaction, warning, and error events.

No runtime failure should be diagnosable only through ADB logcat or backend logs.

## Acceptance Criteria For V1 Runtime Implementation

- All V1 Required variables initialize and update according to this spec.
- All V1 Required objects render meaningful visuals, not generic placeholders.
- All V1 Required rules evaluate at the specified trigger frequency.
- All V1 Required actions mutate runtime state or emit warnings as specified.
- All V1 Required events appear in the runtime UI observability layer.
- Built-in and reference experiments launch without unresolved references.
- Failed preparation produces visible, user-friendly errors.
- Pause/resume behavior is deterministic.
- Unsupported Future capabilities are clearly marked unavailable instead of silently pretending to work.
