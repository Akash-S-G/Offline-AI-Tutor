# Experiment Engine V1 - Capability Gap Analysis

## Current Engine State
Validated Families:
- **Motion:** Pendulum
- **Flow:** Circuit
- **Environment:** Water Cycle
- **Growth:** Plant Growth

Existing Capabilities:
- Blueprint-driven runtime
- Formula engine & variable system
- State machine engine & rule engine
- Behaviors (Oscillation, Flow, Orbit, Pulse, Growth)
- Effects (MotionTrail, Glow, Ripple, PulseRing, CurrentFlow, Rain, Cloud, WaveMotion, WaterDroplets, OrganicGrowth)
- Tools (Ruler, Stopwatch, NumericMeasurement)
- Visual mapping system

## Missing Capabilities & Gaps for Remaining Simulations

### 1. Missing Behaviors
Behaviors encapsulate high-level physical or domain logic decoupled from specific visuals.
- **RayBehavior** (Optics): Needs to calculate reflection/refraction angles based on geometry.
- **RefractionBehavior** (Optics): Specific snell's law solvers.
- **ReactionBehavior** (Chemistry): Manages stoichiometry and progression of chemical reactions.
- **StateTransitionBehavior** (Thermodynamics): Manages phase transitions based on thermal energy (Melting, Freezing, Boiling).

### 2. Missing Effects
Effects handle pure visual rendering based on mapped properties.
- **RayEffect** (Optics): Render a light beam/ray.
- **ReflectionEffect / RefractionEffect** (Optics): Render optical bounces/bending.
- **ReactionEffect** (Chemistry): Render particle interactions.
- **GasEmissionEffect** (Chemistry / Matter): Render bubbles or escaping gas.
- **HeatEffect** (Chemistry): Render burner flames or heat distortion.
- **StateTransitionEffect** (Matter): Render melting ice, boiling water, condensation.
- **HeartGlowEffect / BloodFlowEffect** (Biology): Render localized organ pumping and vascular flow.

### 3. Missing Tools
Measurement tools that students can drag into the scene to measure variables.
- **AngleMeasurementTool** (Optics): A protractor to measure incidence/reflection/refraction angles.
- **RayInspectorTool** (Optics): View light intensity or focal properties.
- **ThermometerTool** (Thermodynamics/Chemistry): Visual representation of temperature.
- **MagnificationTool** (Optics): View virtual/real images and their scaling.

### 4. Missing Runtime Systems
Sub-engines required to handle specific multi-variable solvers that are too complex for simple formulas.
- **Optics Engine (`runtime/optics/`)**: Ray Casting, Reflection Solver, Refraction Solver, Image Formation. Needs to handle geometry intersections dynamically.
- **Chemistry Engine (`runtime/reactions/`)**: ReactionRegistry, ReactionExecutor. Needs to track reactants, products, activation energy, and yield.
- **Automated Evaluation Framework (`runtime/evaluation/`)**: `ExperimentEvaluator` to measure stability, variable consistency, and UX metrics.

## Gap Resolution Strategy
1. **Heart Rate Family**: Will use existing `PulseBehavior` and introduce `HeartGlowEffect` and `BloodFlowEffect`.
2. **Optics Engine**: Will require a new sub-system (`runtime/optics/`) to perform raycasting and image solvers, plus `RayBehavior` and `AngleMeasurementTool`.
3. **Chemistry Engine**: Will require a new sub-system (`runtime/reactions/`) to parse complex reaction definitions from blueprints.
4. **Matter States**: Will leverage formulas and new state transition effects.
5. **Solar System**: Will extend `OrbitBehavior` to support elliptical shapes and rotation.
6. **Universal UX**: Will introduce layered rendering and visual focus systems across all experiments.
7. **Evaluation**: Will build an automated certification suite (`reports/experiment_certifications/`).
