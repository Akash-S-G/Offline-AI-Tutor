# Runtime Capability Matrix

Generated: 2026-06-09

Status legend:

- **Implemented**: usable in current runtime path.
- **Partial**: represented in builder/runtime data, but behavior is incomplete or generic.
- **Registry-only**: selectable or declared, but no dedicated runtime behavior.
- **Missing**: not represented in that layer.

## Variable Types

| Variable Type | Builder Support | Runtime Support | Completeness | Key Files | Dependencies | Educational Use Cases |
| --- | --- | --- | --- | --- | --- | --- |
| accelerometer | Implemented in registry/wizard | Partial provider exists; not automatically bound into `RuntimeWorld` variables | Sensor stream exists, runtime variable store only receives manifest defaults unless external integration updates it | `builder/domain/variable_registry.dart`, `runtime/sensors/providers/accelerometer_provider.dart`, `runtime/variable_store.dart` | `sensors_plus` | Free fall, acceleration, device motion |
| gyroscope | Implemented in registry/wizard | Partial provider exists; not automatically bound into runtime variables | Sensor stream exists; runtime data binding incomplete | `variable_registry.dart`, `gyroscope_provider.dart` | `sensors_plus` | Rotation, angular velocity |
| magnetometer | Implemented in registry/wizard | Partial provider exists; not automatically bound into runtime variables | Sensor stream exists; binding incomplete | `variable_registry.dart`, `magnetometer_provider.dart` | `sensors_plus` | Magnetic fields, compass activities |
| gps | Implemented in registry/wizard | Partial provider exists; permission dependent; not automatically bound into runtime variables | Provider can stream location, but runtime variable updates are not wired by builder launch | `variable_registry.dart`, `gps_provider.dart` | `geolocator`, device location services | Field mapping, speed/altitude experiments |
| microphone | Implemented in registry/wizard | Placeholder only | Provider reports unavailable; no audio capture | `variable_registry.dart`, `microphone_provider.dart` | none active | Sound amplitude/frequency, acoustics |
| lightSensor | Implemented in registry/wizard | Placeholder only | Provider reports unavailable | `variable_registry.dart`, `light_provider.dart` | none active | Light intensity, photosynthesis |
| proximity | Implemented in registry/wizard | Missing | Builder option has no `SensorType` or provider | `variable_registry.dart`, `sensor_type.dart` | none | Distance/proximity activities |
| slider | Implemented in registry/wizard | Registry-only in runtime | Stored as manifest value; no live UI control in runtime player | `variable_registry.dart`, `variable_store.dart` | Flutter UI only | Manual parameter control |
| textInput | Implemented in registry/wizard | Registry-only in runtime | Stored as value; no runtime input control | `variable_registry.dart`, `variable_store.dart` | Flutter UI only | Labels, observations |
| numberInput | Implemented in registry/wizard/templates | Partial | Works as static numeric manifest value; no runtime input UI | `variable_registry.dart`, `variable_store.dart`, `experiment_templates.dart` | none | Temperature, pulse, angle |
| dropdown | Implemented in registry/wizard | Registry-only | Stored as value; no runtime dropdown control | `variable_registry.dart` | Flutter UI only | Categorical choices |
| toggle | Implemented in registry/wizard | Registry-only | Stored as value; no runtime toggle control | `variable_registry.dart` | Flutter UI only | Switch-based experiments |
| average | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart`, `rule_engine.dart` | none | Mean sensor value |
| minimum | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Lowest reading |
| maximum | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Highest reading |
| velocity | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Motion analysis |
| acceleration | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Force/motion labs |
| distance | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Travel/path length |
| force | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Newton's laws |
| power | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Energy transfer rate |
| energy | Implemented in registry/wizard | Missing dedicated computation | Stored as value only | `variable_registry.dart` | none | Kinetic/potential energy |
| elapsedTime | Implemented in registry/wizard/templates | Partial | Runtime clock exists, but elapsed time is not automatically written into variable store | `variable_registry.dart`, `simulation_clock.dart`, `runtime_world.dart` | Flutter timer/game loop | Timing experiments |
| countdown | Implemented in registry/wizard | Missing dedicated timer behavior | Stored as value only | `variable_registry.dart` | none | Countdown activities |
| interval | Implemented in registry/wizard | Missing dedicated timer behavior | Stored as value only | `variable_registry.dart` | none | Periodic sampling |
| customConstant | Implemented in registry/wizard | Implemented as static value | Stored as manifest value in variable store | `variable_registry.dart`, `variable_store.dart` | none | Constants, coefficients |

## Object Types

| Object Type | Builder Support | Runtime Support | Completeness | Key Files | Dependencies | Educational Use Cases |
| --- | --- | --- | --- | --- | --- | --- |
| lineGraph | Implemented in registry/wizard/templates | Generic fallback component | No actual line graph rendering; drawn as default rectangle | `object_registry.dart`, `runtime_object_factory.dart`, `flame_object_components.dart` | Flame | Sensor/time plotting |
| barChart | Implemented in registry/wizard | Generic fallback | No bar chart rendering | same as above | Flame | Category comparison |
| scatterPlot | Implemented in registry/wizard | Generic fallback | No scatter plot rendering | same as above | Flame | Correlation labs |
| textDisplay | Implemented in registry/wizard | Generic fallback | No text display rendering | same as above | Flame | Labels/instructions |
| numericDisplay | Implemented in registry/wizard | Generic fallback | No numeric display rendering | same as above | Flame | Live readings |
| table | Implemented in registry/wizard | Generic fallback | No table rendering | same as above | Flame | Data tables |
| button | Implemented in registry/wizard | Generic fallback | No runtime tap/action handling | same as above | Flame | Trigger experiments |
| slider | Implemented in registry/wizard | Generic fallback | No runtime slider control | same as above | Flame | Manual controls |
| toggle | Implemented in registry/wizard | Generic fallback | No runtime switch control | same as above | Flame | Boolean controls |
| gauge | Implemented in registry/wizard/templates | Partial generic drawing | Renders orange circle; no needle/value display | `object_registry.dart`, `flame_object_components.dart` | Flame | Pulse/temperature gauge |
| counter | Implemented in registry/wizard | Generic fallback | No counter behavior | `object_registry.dart` | Flame | Counts/events |
| progressBar | Implemented in registry/wizard | Generic fallback | No progress bar behavior | `object_registry.dart` | Flame | Completion/percent |
| oscilloscope | Implemented in registry/wizard | Generic fallback | No waveform rendering | `object_registry.dart` | Flame | Signals |
| spectrumAnalyzer | Implemented in registry/wizard | Generic fallback | No frequency-domain rendering | `object_registry.dart` | Flame | Sound/frequency |
| vectorVisualizer | Implemented in registry/wizard | Generic fallback | No vector rendering | `object_registry.dart` | Flame | Forces/3D motion |
| physics_ball | Missing from builder registry | Implemented in runtime factory | Runtime-only capability; builder cannot currently create it | `runtime_object_factory.dart`, `flame_object_components.dart` | `flame_forge2d` | Gravity/collision physics |
| pendulumSimulation | Template/runtime-only; not in builder registry | Partial implemented | Draws pendulum; linked numeric variable changes angle | `experiment_templates.dart`, `runtime_object_factory.dart`, `flame_object_components.dart` | Flame | Pendulum motion |
| plantSimulation | Template/runtime-only; not in builder registry | Partial implemented | Draws plant growth from hard-coded `var_water`/`var_sunlight` IDs | same | Flame | Plant growth |
| interactiveDiagram | Template-only; not in builder registry | Partial generic drawing | Renders orange circle as diagram placeholder | `experiment_templates.dart`, `flame_object_components.dart` | Flame | Water cycle |
| circle | Runtime-only capability | Partial implemented by generic component | Runtime factory declares it; builder cannot create it | `runtime_object_factory.dart` | Flame | Geometry/shape primitive |

## Rule Types

| Rule Type | Builder Support | Runtime Support | Completeness | Key Files | Dependencies | Educational Use Cases |
| --- | --- | --- | --- | --- | --- | --- |
| threshold | Implemented in wizard | Partial | Runtime can evaluate map condition only for `continuous`/`always` triggers; builder serializes trigger as `any`, so main runtime does not evaluate builder threshold rules continuously | `rule_registry.dart`, `rule_wizard_dialog.dart`, `builder_rule.dart`, `rule_engine.dart` | none | Warnings when values cross limits |
| comparison | Registry-only | Missing dedicated runtime support | Wizard can select type but non-threshold rules get generic placeholder condition/action | `rule_registry.dart`, `rule_wizard_dialog.dart` | none | Compare two variables |
| timer | Registry-only | Missing dedicated runtime support | No timer rule scheduler | `rule_registry.dart`, `simulation_clock.dart` | game loop | Time-based actions |
| sensorEvent | Registry-only | Missing dedicated runtime support | Sensor providers exist, but event patterns are not wired to rules | `rule_registry.dart`, `sensor_manager.dart` | sensors | Shake/drop detection |
| buttonEvent | Registry-only | Missing dedicated runtime support | No runtime button events from builder objects | `rule_registry.dart` | Flutter/Flame input | User interaction |
| calculation | Registry-only | Partial expression engine exists | `MathEvaluatorService` can evaluate formulas for string assignment actions, but builder does not expose formula rule config | `rule_registry.dart`, `math_evaluator_service.dart`, `rule_engine.dart` | `math_expressions` | Derived values |
| visibility | Registry-only | Missing dedicated runtime support | No object visibility action handler | `rule_registry.dart`, `rule_engine.dart` | Flame | Show/hide explanations |
| dataCollection | Registry-only | Missing dedicated runtime support | `start_recording`/`stop_recording` action labels exist, but no recorder is implemented | `rule_registry.dart`, `rule_wizard_dialog.dart`, `rule_engine.dart` | none | Data logging |

## Action Types

| Action Type | Builder Support | Runtime Support | Completeness | Key Files | Dependencies | Educational Use Cases |
| --- | --- | --- | --- | --- | --- | --- |
| show_warning | Implemented in rule wizard/templates | Event-only partial | Runtime emits `RuleTriggered` for map actions but does not create a warning event or visual warning | `rule_wizard_dialog.dart`, `experiment_templates.dart`, `rule_engine.dart` | none | Alert learners |
| hide_object | Implemented in rule wizard | Event-only partial | No object visibility mutation | `rule_wizard_dialog.dart`, `rule_engine.dart` | Flame target missing | Hide/reveal visuals |
| start_recording | Implemented in rule wizard/templates | Event-only partial | No data recorder implementation | `rule_wizard_dialog.dart`, `experiment_templates.dart`, `rule_engine.dart` | none | Begin data collection |
| stop_recording | Implemented in rule wizard | Event-only partial | No data recorder implementation | `rule_wizard_dialog.dart`, `rule_engine.dart` | none | End data collection |
| string assignment, e.g. `x = y + dt` | Not exposed in builder UI | Partial implemented | Rule engine evaluates expression and updates variable for string action rules | `rule_engine.dart`, `math_evaluator_service.dart` | `math_expressions` | Simulations/derived variables |
| applyForce | Missing from builder UI | Declared runtime capability only for `physics_ball` | No central action dispatcher invokes it | `runtime_object_factory.dart` | Forge2D | Physics impulses |
| applyImpulse | Missing from builder UI | Declared runtime capability only for `physics_ball` | No central action dispatcher invokes it | `runtime_object_factory.dart` | Forge2D | Collision/momentum |
| reset | Missing from builder UI | Declared for pendulum/plant | No central action dispatcher invokes it | `runtime_object_factory.dart` | Flame | Reset simulations |

## Event Types

| Event Type | Builder Support | Runtime Support | Completeness | Key Files | Dependencies | Educational Use Cases |
| --- | --- | --- | --- | --- | --- | --- |
| sessionCreated | Runtime UI only | Implemented | Emitted when player prepares world | `runtime_event.dart`, `experiment_player_controller.dart` | none | Runtime lifecycle visibility |
| sessionStarted | Runtime UI only | Implemented | Emitted on Start | same | none | Start tracking |
| sessionPaused | Runtime UI only | Implemented | Emitted on Pause | same | none | Pause/resume learning |
| sessionResumed | Runtime UI only | Implemented | Emitted on Resume | same | none | Continue experiment |
| sessionStopped | Runtime UI only | Implemented | Emitted on Stop | same | none | End run |
| sessionCompleted | Runtime enum only | Partial | Enum/UI handling exists; current player uses `sessionStopped` for stop | `runtime_event.dart`, `runtime_timeline.dart` | none | Completion reports |
| measurementReceived | Sensor runtime | Partial | `SensorRuntime` can emit; builder player path does not auto-start sensors from variables | `sensor_runtime.dart`, `runtime_visualization_controller.dart` | sensors | Sensor readings |
| warning | Runtime enum/UI only | Partial | UI counts warnings; rule actions do not emit warning events | `runtime_event.dart`, `runtime_visualization_controller.dart` | none | Learner feedback |
| error | Runtime enum/UI only | Partial | UI counts errors; preparation errors are surfaced separately via controller | `runtime_event.dart`, `experiment_player_controller.dart` | none | Diagnostics |
| custom | Implemented | Partial | Used for `RuleTriggered`/`VariableChanged`; UI interprets some playground metadata | `rule_engine.dart`, `runtime_visualization_controller.dart`, `experiment_player_screen.dart` | none | Rule/event feed |
| sceneLoaded | Preview playground only | Implemented in preview engine | Not part of main runtime event enum | `playground_event.dart`, `simulation_playground_engine.dart` | none | Builder preview |
| objectCreated | Preview playground only | Implemented in preview engine | Not part of main runtime event enum | same | none | Builder preview |
| objectUpdated | Preview playground only | Implemented in preview engine | Not part of main runtime event enum | same | none | Object state inspection |
| variableChanged | Preview playground/custom runtime message | Partial | Preview emits event; main runtime emits `custom` message `VariableChanged` for string actions | `playground_event.dart`, `rule_engine.dart` | none | Variable monitor |
| ruleExecuted | Preview playground only | Implemented in preview engine | Main runtime uses custom `RuleTriggered` message | `playground_event.dart`, `simulation_playground_engine.dart` | none | Rule feed |
| interaction | Preview enum only | Registry-only | No current publisher found | `playground_event.dart` | input handling missing | Button/tap experiments |
| custom | Preview playground | Partial | Generic extension point | `playground_event.dart` | none | Future custom events |

