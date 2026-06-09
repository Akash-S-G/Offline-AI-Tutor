# Runtime Dependency Graph

Generated: 2026-06-09

This graph documents the current Experiment Engine implementation. It is a source-level dependency map, not a proposed architecture.

## High-Level Flow

```text
Experiment Builder UI
  -> ExperimentBuilderController
  -> ExperimentBuilderState
  -> generateManifestJson()
  -> BuilderExecutionPreviewPanel
  -> ExperimentPlayerScreen
  -> ExperimentPlayerController.prepare()
  -> RuntimeLoader.loadFromManifest()
  -> RuntimeValidator.validate()
  -> RuntimeWorld.initialize()
  -> VariableStore / ObjectRegistry / RuleEngine / SimulationClock
  -> ExperimentFlameGame
  -> RuntimeObjectFactory.create()
  -> BuilderObjectComponent or PhysicsBall
```

## Builder Dependency Graph

```text
ExperimentBuilderScreen
  -> AiGeneratorTab
  -> BuilderDraftsScreen
  -> DesignWorkspacePanel
      -> SceneEditor
      -> VariableEditor
          -> VariableWizardDialog
          -> VariableRegistry
      -> ObjectEditor
          -> ObjectWizardDialog
          -> ObjectRegistry
      -> RuleEditor
          -> RuleWizardDialog
          -> RuleRegistry
  -> PreviewWorkspacePanel
      -> BuilderExecutionPreviewPanel
      -> RuntimePreviewPanel
          -> ExecutionDefinitionMapper
          -> SimulationPlaygroundEngine
  -> PublishWorkspacePanel
```

## Manifest Generation

```text
BuilderScene.toJson()
BuilderVariable.toJson()
BuilderObject.toJson()
BuilderRule.toJson()
  -> ExperimentBuilderState.generateManifestJson()
      {
        scene: {
          sceneId,
          name,
          description,
          tags,
          variables[],
          objects[],
          rules[]
        }
      }
```

## Validation Dependencies

```text
BuilderValidator
  -> ExperimentBuilderState
  -> BuilderVariable ids/names
  -> BuilderObject ids/names/properties
  -> BuilderRule ids/names/condition/action

RuntimeValidator
  -> manifest.scene
  -> variables[].id/name
  -> objects[].objectId/id
  -> object.properties var_* references
  -> rules[].ruleId
  -> rule.condition.variableId
  -> rule.action string assignment dependencies
```

## Runtime World Dependencies

```text
RuntimeLoader
  -> RuntimeObjectFactory.registerDefaults()
  -> RuntimeValidator.validate()
  -> RuntimeProfileManager.determineProfile()
  -> RuntimeWorld.initialize()

RuntimeWorld
  -> VariableStore
      -> Map<variableId, value>
  -> ObjectRegistry
      -> Map<objectId, objectData>
  -> RuleEngine
      -> VariableStore
      -> RuntimeEventBus
      -> MathEvaluatorService
  -> RuntimeEventBus
  -> SimulationClock
  -> RuntimeAnalytics
```

## Rendering Dependencies

```text
ExperimentPlayerScreen
  -> GameWidget
      -> ExperimentFlameGame
          -> RuntimeWorld.tick(dt)
          -> RuntimeObjectFactory.create(objectData, world)
              -> PhysicsBall for objectType=physics_ball
              -> BuilderObjectComponent for registered simple simulations
              -> BuilderObjectComponent fallback for unknown types
```

## Object Factory Registry

```text
RuntimeObjectFactory.registerDefaults()
  -> physics_ball
      -> PhysicsBall
      -> Forge2D body
  -> pendulumSimulation
      -> BuilderObjectComponent
  -> plantSimulation
      -> BuilderObjectComponent
  -> circle
      -> BuilderObjectComponent

Unregistered object types
  -> BuilderObjectComponent fallback
```

## Rule Evaluation Dependencies

```text
ExperimentFlameGame.update(dt)
  -> RuntimeWorld.tick(dt)
      -> SimulationClock.tick(dt)
      -> RuleEngine.evaluateContinuousRules(dt)
          -> rules where trigger == continuous or always
          -> condition map { variableId, operator, value }
          -> VariableStore.get(variableId)
          -> action
              -> if String assignment:
                  -> MathEvaluatorService.evaluateExpression()
                  -> VariableStore.set()
                  -> RuntimeEventBus.emit(custom RuleTriggered)
                  -> RuntimeEventBus.emit(custom VariableChanged)
              -> if Map:
                  -> RuntimeEventBus.emit(custom RuleTriggered)
```

Important current limitation:

```text
BuilderRule.toJson()
  -> trigger: any

RuleEngine.evaluateContinuousRules()
  -> evaluates only trigger continuous or always

Therefore builder-created rules are loaded, but not continuously evaluated by the main runtime unless their trigger is changed to continuous/always or another dispatcher invokes them.
```

## Sensor Dependencies

```text
SensorManager
  -> SensorRegistry
      -> AccelerometerProvider -> sensors_plus
      -> GyroscopeProvider -> sensors_plus
      -> MagnetometerProvider -> sensors_plus
      -> BarometerProvider -> sensors_plus
      -> GpsProvider -> geolocator
      -> MicrophoneProvider -> placeholder
      -> LightProvider -> placeholder

SensorRuntime
  -> SensorManager.measurementStream
  -> RuntimeEventType.measurementReceived
```

Important current limitation:

```text
ExperimentPlayerScreen / ExperimentPlayerController
  -> RuntimeLoader / RuntimeWorld
  X does not automatically start SensorManager based on sensor variable types
```

## Event Dependencies

```text
RuntimeEventBus
  -> RuntimeAnalytics
      -> counts RuleTriggered and VariableChanged messages
  -> RuntimeVisualizationController
      -> timeline
      -> measurements
      -> variable/object panels for recognized playground metadata
  -> ExperimentPlayerScreen
      -> Runtime Health
      -> Rule Execution Feed
      -> Event Monitor
```

Preview playground event flow:

```text
RuntimePreviewPanel
  -> SimulationPlaygroundEngine
      -> PlaygroundEventBus
      -> PlaygroundEventType.sceneLoaded
      -> objectCreated
      -> variableChanged
      -> objectUpdated
      -> ruleExecuted
```

## External Packages

| Package | Used By | Purpose |
| --- | --- | --- |
| `flutter/material.dart` | Builder/runtime UI | Forms, dialogs, tabs, cards |
| `flame` | `ExperimentFlameGame`, components | Runtime canvas/game loop |
| `flame_forge2d` | `PhysicsBall`, `ExperimentFlameGame` | Physics world/body simulation |
| `sensors_plus` | Accelerometer, gyroscope, magnetometer, barometer providers | Device sensor streams |
| `geolocator` | GPS provider | Location stream |
| `math_expressions` | `MathEvaluatorService` | Rule expression evaluation |
| `uuid` | Builder/runtime preview IDs | ID generation |
| `shared_preferences` | Builder drafts | Draft persistence |

## Capability Boundaries

```text
Builder registries are broader than runtime implementation.
Runtime object fallback prevents crashes but does not mean object-specific behavior exists.
Rule action labels are broader than action execution.
Sensor providers exist independently from runtime variable binding.
Preview playground engine and main Flame runtime are separate execution paths.
```

