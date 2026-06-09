# Experiment Runtime Certification Report

Generated: 2026-06-09

## Scope

This pass validates that the experiment runtime can be observed from the Flutter UI without relying on ADB logcat or backend logs.

## Templates Tested

| Template | Manifest Loaded | Objects Created | Variables Created | Rules Loaded | Runtime Started | Simulation Visible | Events Received | No Runtime Exceptions |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Free Fall Experiment | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| Pendulum Motion | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| Plant Growth | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| Water Cycle | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| Heart Rate Monitor | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |

## Runtime Snapshots

| Template | Objects Count | Variables Count | Rules Count | Events Count | FPS |
| --- | ---: | ---: | ---: | ---: | --- |
| Free Fall Experiment | 1 | 2 | 1 | 1 | On-device only |
| Pendulum Motion | 1 | 1 | 1 | 1 | On-device only |
| Plant Growth | 1 | 2 | 1 | 1 | On-device only |
| Water Cycle | 1 | 1 | 1 | 1 | On-device only |
| Heart Rate Monitor | 1 | 1 | 1 | 1 | On-device only |

## Runtime Health Results

- Runtime Health Card: implemented.
- Runtime Summary: implemented for objects, variables, rules, and events.
- Manifest Loaded: visible as PASS/FAIL.
- Objects Loaded: visible as PASS/FAIL.
- Variables Loaded: visible as PASS/FAIL.
- Rules Loaded: visible as PASS/FAIL.
- Runtime Prepared: visible as PASS/FAIL.
- Simulation Running: visible as PASS/FAIL.

## Runtime Error Results

- Runtime Status Indicator: implemented for READY, PREPARING, RUNNING, PAUSED, and FAILED.
- Last Error Panel: implemented.
- User-friendly failed-start message: implemented.
- Latest runtime preparation error remains visible in the player UI.

## Rule Feed Validation

- Rule Execution Feed: implemented.
- Rule Statistics: implemented for rules loaded, rules triggered, and last trigger time.
- Free Fall includes one rule and exposes triggered rule events when its condition fires.
- Templates with no rules show an empty-state message instead of requiring logs.

## Event Feed Validation

- Event Monitor: implemented.
- Event Counters: implemented for fired, processed, and pending events.
- Event categories shown in UI: sensor updates, rule events, runtime events, warnings, errors, timer/button custom events when emitted.

## Mobile Validation Results

| Device Mode | Result |
| --- | --- |
| Android Phone Portrait | Pending physical-device pass |
| Android Phone Landscape | Pending physical-device pass |
| Tablet Portrait | Pending physical-device pass |
| Tablet Landscape | Pending physical-device pass |

Checks to complete on device:

- No overflow.
- No clipped buttons.
- No hidden controls.
- No unreachable actions.
- No scroll locking.

## Known Failures

- FPS capture is not available in the static certification service yet; it must be verified from the live Flame runtime on device.
- Screenshots were not captured in this CLI pass.
- Physical mobile orientation validation is still pending.

## Screenshots

No screenshots captured in this pass.
