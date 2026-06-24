# Classroom Connection and P2P Sharing

Generated: 2026-06-24

## Classroom Connection

Classroom connection and device-to-device sharing are separate systems.

The classroom connection finds a PiHub HTTP gateway:

```text
Student device
  -> cached gateway URL
  -> HTTP GET /health
  -> LAN PiHub discovery when required
  -> RuntimeBackendUrl
```

The saved classroom contains:

- classroom ID
- classroom name
- node ID
- gateway URL

After connection, the app does not need to repeat full LAN discovery. It
periodically calls the active gateway's `/health` endpoint. Full discovery is
used only when:

- no saved classroom exists
- the saved classroom is unreachable
- repeated reconnect attempts fail
- the user explicitly presses Refresh or Retry

Reconnect delays are:

```text
5 seconds
10 seconds
20 seconds
30 seconds
```

## Connection Issue Found

The status banner previously appeared above every route because it was added
through `MaterialApp.builder`.

It is now shown only on the first dashboard page, `My Learning`.

The apparent repeated connection behavior had two causes:

1. The Refresh action could start discovery even when the current classroom
   was healthy.
2. Every latency/health notification from `BackendDiscoveryService` rebuilt
   `voiceConnectionProvider`, destroying and recreating its WebSocket.

Changes applied:

- normal discovery now exits immediately while connected
- explicit user refresh uses `force: true`
- starting forced discovery cancels the current health timer first
- the voice provider watches only `activeEndpoint`
- latency-only updates no longer recreate the voice socket

## P2P Sharing Methods

### 1. Wi-Fi LAN

This is the primary sharing method.

Discovery:

```text
UDP broadcast
Port 45889
Probe: DISCOVER_OFFLINE_TUTOR
```

Transfer:

```text
TCP socket
Port 45888
Maximum bundle size: 50 MB
```

Both devices normally need to be connected to the same Wi-Fi network.

Transport labels:

- `wifi-lan`
- `wifi-lan-tcp`

### 2. Wi-Fi Direct

This is the fallback when no peer is found on the normal LAN.

Android APIs used:

- `WifiP2pManager.discoverPeers`
- `WifiP2pManager.connect`
- Wi-Fi Direct group owner/client resolution
- ARP lookup for the peer IPv4 route

After a Wi-Fi Direct route is established, the actual file transfer still
uses the same TCP receiver on port `45888`.

Required Android permissions:

- Fine Location
- Nearby Wi-Fi Devices on Android 13 and later

Transport labels:

- `wifi-direct`
- `wifi-direct-discovery`

Routing policy:

```text
LAN first
Wi-Fi Direct fallback
```

## Bluetooth

Bluetooth sharing is not implemented.

The application does not currently use:

- Bluetooth Classic sockets
- BLE advertising
- BLE GATT transfer
- Nearby Connections Bluetooth transport

The current P2P implementation is Wi-Fi-only.

## Security and Transfer Behavior

The P2P layer also provides:

- trusted peer storage
- shared-secret validation
- pending-transfer approval
- automatic approval for configured trusted peers
- transfer progress, throughput, and ETA
- hash/manifest validation for educational bundles

## Relevant Source Files

- `lib/features/network/services/backend_discovery_service.dart`
- `lib/features/network/providers/backend_discovery_provider.dart`
- `lib/features/voice/providers/voice_connection_provider.dart`
- `lib/features/p2p/data/p2p_channel_service.dart`
- `lib/features/p2p/presentation/p2p_screen.dart`
- `android/app/src/main/kotlin/com/example/offline_tutor_app/P2PManager.kt`
