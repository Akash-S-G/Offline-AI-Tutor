# Object Runtime Implementation Order

Generated: 2026-06-09

## Scope

This document defines which builder objects should be implemented first and why.

No runtime features were implemented for this sprint.

## Prioritization Rules

### P0

Required for generic educational experiments.

Criteria:

- Common across many subjects.
- Uses simple variable-to-state binding.
- Makes runtime state visible to learners.
- Supports current built-in templates or obvious classroom experiments.
- Low-to-medium implementation complexity.

### P1

Useful but not essential.

Criteria:

- Useful in many experiments but not required for first reliable runtime.
- Requires additional state semantics or controls.
- Can build on P0 infrastructure.

### P2

Advanced/scientific.

Criteria:

- Requires specialized signal, history, sensor, or scientific processing.
- Less common in basic classroom experiments.
- Should wait until generic object behavior is stable.

## Recommended Implementation Order

| Order | Object | Classification | Priority | Why First/Why Later |
| ---: | --- | --- | --- | --- |
| 1 | numericDisplay | DISPLAY_OBJECT | P0 | Simplest proof of object runtime: value binding, formatting, dedicated display renderer. Useful everywhere. |
| 2 | textDisplay | DISPLAY_OBJECT | P0 | Enables labels, explanations, and state messages. Low complexity once display renderer base exists. |
| 3 | gauge | DISPLAY_OBJECT | P0 | Built-in Heart Rate uses it; common for temperature/pulse/speed. Needs min/max but no history. |
| 4 | progressBar | DISPLAY_OBJECT | P0 | Common for growth/countdown/completion. Builds on min/max normalization used by gauge. |
| 5 | lineGraph | VISUALIZATION_OBJECT | P0 | Built-in Free Fall uses it. Requires history buffer, so should come after simple display objects. |
| 6 | button | INTERACTIVE_OBJECT | P0 | Required for generic event-driven experiments, but needs interaction event adapter. |
| 7 | slider | INTERACTIVE_OBJECT | P0 | Required for manual parameter control, but needs object-to-variable update path. |
| 8 | toggle | INTERACTIVE_OBJECT | P1 | Same interaction foundation as slider/button, but less critical than numeric controls. |
| 9 | counter | DISPLAY_OBJECT | P1 | Useful for events/pulses but depends on action/event semantics for full behavior. |
| 10 | table | DISPLAY_OBJECT | P1 | Useful for lab observations, but needs row/column schema and data collection integration. |
| 11 | barChart | VISUALIZATION_OBJECT | P1 | Useful for comparisons, but category data model should wait until display/graph basics are done. |
| 12 | vectorVisualizer | SCIENTIFIC_OBJECT | P1 | Important for physics, but requires vector component schema and renderer. |
| 13 | scatterPlot | VISUALIZATION_OBJECT | P2 | Requires x/y multi-binding and point history; implement after lineGraph/history support. |
| 14 | oscilloscope | SCIENTIFIC_OBJECT | P2 | Requires high-frequency waveform buffer and signal input pipeline. |
| 15 | spectrumAnalyzer | SCIENTIFIC_OBJECT | P2 | Most advanced; needs FFT/spectrum processing and signal input pipeline. |

## P0 Implementation Batch

Recommended first implementation batch:

1. `numericDisplay`
2. `textDisplay`
3. `gauge`
4. `progressBar`
5. `lineGraph`
6. `button`
7. `slider`

Why this batch:

- Covers display, visualization, and interaction foundations.
- Supports common educational experiments: temperature, motion, pulse, growth, timing, and parameter exploration.
- Converts the current binding system into visible learning value.
- Avoids advanced scientific processing until the core object lifecycle is stable.

## P1 Implementation Batch

Recommended second batch:

1. `toggle`
2. `counter`
3. `table`
4. `barChart`
5. `vectorVisualizer`

Why this batch:

- Builds on P0 display and interaction infrastructure.
- Adds richer classroom data workflows.
- Introduces vector/scientific representation without requiring full signal processing.

## P2 Implementation Batch

Recommended final batch:

1. `scatterPlot`
2. `oscilloscope`
3. `spectrumAnalyzer`

Why this batch:

- Requires multi-variable binding, high-frequency samples, or specialized scientific math.
- Should wait until history buffers, renderers, and object-state schemas are mature.

## Required Foundation Before Implementing P0

Before implementing object behavior, create:

- Object state schema registry.
- Object behavior registry.
- Object renderer registry.
- Display object base behavior.
- Renderer consumption of `RuntimeObjectState`.
- Object layout model.
- Object-specific validation and failure events.

## First Concrete Runtime Feature Sprint Recommendation

Start with:

```text
numericDisplay
```

Reason:

- It validates the full object runtime path with minimal complexity.
- Expected state is simple:

```json
{
  "value": 25,
  "unit": "",
  "precision": 1,
  "formattedValue": "25.0"
}
```

- Required behavior is straightforward:
  - read `state.value`
  - format number
  - render label/value
  - update when binding changes

Once `numericDisplay` is complete, `textDisplay`, `gauge`, and `progressBar` can reuse most of the display object foundation.

