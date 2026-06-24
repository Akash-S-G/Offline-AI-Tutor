# P2P and Classroom Connectivity Audit

Generated: 2026-06-24

## Scope

Audited:

- `lib/features/network/`
- `lib/features/p2p/`
- `lib/core/services/`
- `lib/features/discovery/`
- application startup and backend URL consumers

Tutor, Voice, and Experiment behavior were not changed.

## Existing Systems

| Component | Status Before Sprint | Finding |
| --- | --- | --- |
| `PiHubDiscoveryCoordinator` | Implemented, partially integrated | Cached-node lookup, LAN scan, health checks, fastest healthy-node promotion, and persistence existed. |
| `BackendDiscoveryService` | Partial | Persisted one URL and performed health checks, but exposed only `activeEndpoint` and `isDiscovering`. |
| `ConnectivityController` | Implemented, internal | Tracked offline/discovering/online/syncing but was not connected to the active P2P UI. |
| `BackendUrlManager` | Implemented | Propagated a promoted URL to `RuntimeBackendUrl`. |
| `RuntimeBackendUrl` | Implemented and active | Used by backend HTTP, pack sync, PDF installation, and educational sync. |
| `DiscoverySyncBridge` | Implemented | Connected discovery events to endpoint promotion and connectivity state. |
| `ReconnectCoordinator` | Partial | Re-registered a classroom session but did not manage gateway retry timing. |
| `ClassroomSessionManager` | Stub-level | Stored only in-memory connected/session state. |
| `SessionPersistenceManager` | Implemented but unused for gateway selection | Generic JSON session persistence existed separately from discovery. |
| `P2PScreen` | Implemented for peer transfer | Supported nearby peers, trusted peers, bundles, pack transfer, security, and telemetry. It did not expose classroom gateway discovery. |
| Discovery/connection screen | Missing | No student-facing classroom selection, manual gateway, or connection detail workflow existed. |
| Global classroom banner | Missing | Connection state was not visible throughout the app. |

## Root Causes

1. Classroom gateway discovery and nearby-device file transfer were implemented as separate UX flows.
2. `main.dart` called `PiHubDiscoveryCoordinator.clearPersistedCache()` on every boot, defeating last-known classroom recovery.
3. `BackendDiscoveryService` could reconnect internally but had no explicit connection state, classroom metadata, latency, or backoff model.
4. The active P2P page exposed transfer internals before classroom connectivity.
5. Multiple discovery classes existed, but only `RuntimeBackendUrl` consistently acted as the endpoint source for backend consumers.

## Endpoint Audit

Confirmed consumers of `RuntimeBackendUrl`:

- `BackendHttpClient`
- `ContentPackSyncService`
- `PdfInstallService`
- `SyncManager`
- `HybridInferenceService` diagnostics and routing

`AppEnvironment.backendBaseUrl` remains the initial fallback seed. Runtime requests use the promoted `RuntimeBackendUrl` after classroom connection.

## Implemented Consolidation

- Upgraded the existing `BackendDiscoveryService` into the classroom connection provider.
- Added states: disconnected, discovering, connecting, connected, reconnecting.
- Preserved `activeEndpoint` and `isDiscovering` for existing consumers.
- Added persisted classroom ID, name, node ID, and gateway URL.
- Added cached-session reconnect before discovery.
- Added 5, 10, 20, and 30 second reconnect backoff.
- Added manual IP/hostname connection.
- Added health-derived latency and optional classroom metadata parsing.
- Promoted successful connections to `RuntimeBackendUrl`.
- Removed startup cache deletion.
- Added a global connection banner and classroom details screen.
- Added classroom discovery and selection above the existing P2P transfer tools.

## Remaining Deployment Dependency

The `/health` endpoint currently guarantees health status. Classroom name, node ID, and student count are shown when the endpoint returns compatible metadata keys. Otherwise the frontend uses gateway-derived fallback values. No new backend contract was introduced.
