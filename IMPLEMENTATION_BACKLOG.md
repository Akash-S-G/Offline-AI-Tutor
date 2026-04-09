# Implementation Backlog (Mobile-First)

## Completed in this iteration
- Android model and P2P runtime stabilized.
- Model selection screen upgraded with:
  - model picker validation for `.gguf`
  - generation presets (Fast, Balanced, Deep Explain)
  - configurable max tokens, timeout, system prompt
  - live engine status display
  - model validation probe button
  - engine reset action
- New **Math Simulator** feature added:
  - 2D formula plotting (function graphing)
  - 2D geometry simulation (circle, rectangle, right triangle)
- P2P screen overflow fix on mobile.
- Dashboard chapter dropdown stabilization fix.

## Remaining implementations

### High priority
1. **Video resources pipeline completion**
- Replace placeholder local paths with actual content source (device paths, app storage, or remote links).
- Add metadata model for videos (title, duration, tags, source path/url).
- Add persistence for user video library.
- Add graceful fallback for missing/unreadable videos.

2. **Model setup UX completion**
- Add guided checklist in UI (file selected -> validated -> first inference success).
- Add one-tap "test prompt" action from model settings.
- Add clearer native error mapping (OOM, invalid model, permission/path issues).

3. **Quiz and assessment module**
- Question bank per chapter.
- Scoring + feedback view.
- Persisted attempts and trend analytics.

4. **P2P production hardening**
- End-to-end manual tests across two Android devices.
- Transfer retry/cancel UX.
- Better status text for network discovery states.

### Medium priority
5. **Notes module completion**
- Create/edit/delete notes.
- Chapter linking and tags.
- Search notes.

6. **RAG quality improvements**
- Retrieval ranking tuning.
- Better multilingual chunk scoring.
- Source citation confidence display.

7. **Performance tuning**
- App startup optimization.
- Background ingestion progress controls.
- Chat streaming telemetry in-app diagnostics.

### Future updates (do not implement now)
8. **3D Math/Geometry Simulation**
- Add 3D plotting support for surfaces and solids.
- Candidate tech options:
  - Flutter: custom 3D renderer or package-based scene view.
  - WebView bridge for mature 3D math libraries if needed.
- Suggested first 3D lessons: cube, sphere, cylinder, paraboloid.

9. **Advanced model profiles**
- Profile templates per device capability (low/mid/high RAM).
- Adaptive token limits based on memory pressure.

## Inputs needed from user
- Sample video files (or a folder path structure) to complete the resources/video pipeline.
- Preferred model files for low-end and mid/high-end devices.
- Priority order between Quiz vs P2P hardening vs Notes.
