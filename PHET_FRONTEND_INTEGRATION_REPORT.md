# PhET Frontend Integration Report

Generated: 2026-06-24

## Previous Frontend State

- The dashboard already opened the PhET catalog screen.
- The catalog read only `assets/phet/catalog.json`.
- Five mock entries all opened `assets/phet/simulations/placeholder.html`.
- `/experiments/catalog` was not called.
- Backend `local_url` values were not consumed.
- The `phet_simulations_v1` pack was not downloaded or resolved.
- Installed simulation HTML files were not used by the player.

## Verified Backend Contract

Live PiHub:

- `GET /experiments/catalog`
- Response contains `experiments[]`, `simulations[]`, and `total`.
- Each PhET entry provides `slug`, `url`, `local_url`, and `manifest`.
- `local_url` resolves to `/simulations/<slug>/index.html`.

Live pack:

- `GET /packs/phet_simulations_v1/download`
- Downloaded size: approximately 40 MB.
- Archive format: gzip-compressed tar.
- Extracted size: approximately 117 MB.
- Pack manifest: `phet_simulations_v1/manifest.json`.
- PhET catalog: `phet_simulations_v1/simulations/catalog.json`.
- Standalone simulation files: 40 verified `index.html` entries.

The backend catalog reports `total: 45` because it combines five native
experiments with 40 PhET simulations.

## Implemented Frontend Flow

```text
Open Experiment Studio
        |
        v
Check installed phet_simulations_v1 pack
        |
        +-- installed --> load simulations/catalog.json from disk
        |                 and launch file://.../index.html
        |
        +-- missing ----> GET /experiments/catalog
                          resolve local_url against RuntimeBackendUrl
                          and launch PiHub-served HTML
        |
        +-- unavailable -> bundled placeholder catalog fallback
```

## Offline Installation

The catalog now provides `Install Offline`.

```text
GET /packs/phet_simulations_v1/download
        |
        v
ContentPackArchiveService
        |
        v
Installed content pack root
        |
        v
simulations/catalog.json
simulations/<slug>/index.html
```

Simulation packs are explicitly excluded from textbook PDF acquisition. This
is required because the PhET manifest contains generic grade/subject metadata
but no textbook PDF.

## Player Behavior

- Forces landscape while a simulation is active.
- Loads installed simulations through a local file URI.
- Loads connected simulations through the PiHub `local_url`.
- Allows JavaScript and sibling file access required by standalone PhET HTML.
- Shows loading progress and actionable load errors.
- Updates the existing simulation context for tutor integration.

## Verification

- Focused Dart analysis: no PhET errors.
- Catalog contract tests: PASS, 2 tests.
- Android debug build: PASS.
- Live archive structure inspection: PASS.
- Live catalog response inspection: PASS.

