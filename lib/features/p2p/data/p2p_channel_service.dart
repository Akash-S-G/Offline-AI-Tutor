import 'package:flutter/services.dart';

class P2PPeer {
  const P2PPeer({
    required this.name,
    required this.address,
    required this.transport,
    required this.resolvedAddress,
  });

  final String name;
  final String address;
  final String transport;
  final String resolvedAddress;
}

class ReceivedBundle {
  const ReceivedBundle({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.lastModified,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final int lastModified;
}

class PendingIncomingTransfer {
  const PendingIncomingTransfer({
    required this.id,
    required this.senderAddress,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String senderAddress;
  final String fileName;
  final int sizeBytes;
  final int createdAt;
}

class P2POperationResult {
  const P2POperationResult({
    required this.ok,
    required this.message,
    this.bytes,
  });

  final bool ok;
  final String message;
  final int? bytes;
}

class P2PStatus {
  const P2PStatus({
    required this.supported,
    required this.enabled,
    required this.pairedCount,
    required this.transport,
    required this.receiverRunning,
    required this.inboxCount,
    required this.lastTransferError,
    required this.localIp,
    required this.routeDecision,
    required this.routePolicy,
    required this.pendingIncomingCount,
  });

  final bool supported;
  final bool enabled;
  final int pairedCount;
  final String transport;
  final bool receiverRunning;
  final int inboxCount;
  final String lastTransferError;
  final String localIp;
  final String routeDecision;
  final String routePolicy;
  final int pendingIncomingCount;
}

class P2PPermissionStatus {
  const P2PPermissionStatus({
    required this.locationGranted,
    required this.nearbyWifiGranted,
    required this.requiresNearbyWifi,
    required this.allGranted,
  });

  final bool locationGranted;
  final bool nearbyWifiGranted;
  final bool requiresNearbyWifi;
  final bool allGranted;
}

class P2PTransferTelemetry {
  const P2PTransferTelemetry({
    required this.direction,
    required this.stage,
    required this.peerAddress,
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.progressPct,
    required this.throughputBps,
    required this.etaSeconds,
    required this.done,
    required this.success,
    required this.errorMessage,
  });

  final String direction;
  final String stage;
  final String peerAddress;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final int progressPct;
  final int throughputBps;
  final int etaSeconds;
  final bool done;
  final bool success;
  final String errorMessage;
}

class P2PTransferTelemetrySnapshot {
  const P2PTransferTelemetrySnapshot({
    required this.send,
    required this.receive,
  });

  final P2PTransferTelemetry? send;
  final P2PTransferTelemetry? receive;
}

class P2PChannelService {
  static const MethodChannel _channel = MethodChannel('offline_tutor/p2p');

  Future<P2PStatus> getStatus() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('getStatus');

    return P2PStatus(
      supported: data?['supported'] as bool? ?? false,
      enabled: data?['enabled'] as bool? ?? false,
      pairedCount: data?['pairedCount'] as int? ?? 0,
      transport: data?['transport'] as String? ?? 'unknown',
      receiverRunning: data?['receiverRunning'] as bool? ?? false,
      inboxCount: data?['inboxCount'] as int? ?? 0,
      lastTransferError: data?['lastTransferError'] as String? ?? '',
      localIp: data?['localIp'] as String? ?? '',
      routeDecision: data?['routeDecision'] as String? ?? 'NONE',
      routePolicy: data?['routePolicy'] as String? ?? 'lan-first,wifi-direct-fallback',
      pendingIncomingCount: data?['pendingIncomingCount'] as int? ?? 0,
    );
  }

  Future<P2PTransferTelemetrySnapshot> getTransferTelemetry() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('getTransferTelemetry');
    final send = _parseTelemetry(data?['send']);
    final receive = _parseTelemetry(data?['receive']);
    return P2PTransferTelemetrySnapshot(send: send, receive: receive);
  }

  P2PTransferTelemetry? _parseTelemetry(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final stage = raw['stage'] as String? ?? '';
    if (stage.isEmpty) {
      return null;
    }

    return P2PTransferTelemetry(
      direction: raw['direction'] as String? ?? 'unknown',
      stage: stage,
      peerAddress: raw['peerAddress'] as String? ?? '',
      fileName: raw['fileName'] as String? ?? '',
      totalBytes: raw['totalBytes'] as int? ?? 0,
      transferredBytes: raw['transferredBytes'] as int? ?? 0,
      progressPct: raw['progressPct'] as int? ?? 0,
      throughputBps: raw['throughputBps'] as int? ?? 0,
      etaSeconds: raw['etaSeconds'] as int? ?? -1,
      done: raw['done'] as bool? ?? false,
      success: raw['success'] as bool? ?? false,
      errorMessage: raw['errorMessage'] as String? ?? '',
    );
  }

  Future<P2PPermissionStatus> getPermissionStatus() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('getPermissionStatus');
    return P2PPermissionStatus(
      locationGranted: data?['locationGranted'] as bool? ?? false,
      nearbyWifiGranted: data?['nearbyWifiGranted'] as bool? ?? false,
      requiresNearbyWifi: data?['requiresNearbyWifi'] as bool? ?? false,
      allGranted: data?['allGranted'] as bool? ?? false,
    );
  }

  Future<P2PPermissionStatus> requestPermissions() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('requestPermissions');
    return P2PPermissionStatus(
      locationGranted: data?['locationGranted'] as bool? ?? false,
      nearbyWifiGranted: data?['nearbyWifiGranted'] as bool? ?? false,
      requiresNearbyWifi: data?['requiresNearbyWifi'] as bool? ?? false,
      allGranted: data?['allGranted'] as bool? ?? false,
    );
  }

  Future<List<P2PPeer>> listPeers() async {
    final data = await _channel.invokeMethod<List<dynamic>>('listPeers');
    final peers = data ?? const <dynamic>[];

    return peers
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (peer) => P2PPeer(
            name: peer['name'] as String? ?? 'Unknown Device',
            address: peer['address'] as String? ?? '',
            transport: peer['transport'] as String? ?? 'unknown',
            resolvedAddress: peer['resolvedAddress'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<P2POperationResult> startReceiver() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('startReceiver');
    return P2POperationResult(
      ok: data?['ok'] as bool? ?? false,
      message: data?['message'] as String? ?? 'Unknown receiver start result',
    );
  }

  Future<P2POperationResult> stopReceiver() async {
    final data = await _channel.invokeMapMethod<String, dynamic>('stopReceiver');
    return P2POperationResult(
      ok: data?['ok'] as bool? ?? false,
      message: data?['message'] as String? ?? 'Unknown receiver stop result',
    );
  }

  Future<P2POperationResult> sendBundle({
    required String address,
    required String filePath,
  }) async {
    final data = await _channel.invokeMapMethod<String, dynamic>(
      'sendBundle',
      <String, dynamic>{
        'address': address,
        'filePath': filePath,
      },
    );

    return P2POperationResult(
      ok: data?['ok'] as bool? ?? false,
      message: data?['message'] as String? ?? 'Unknown send result',
      bytes: data?['bytes'] as int?,
    );
  }

  Future<List<ReceivedBundle>> listReceivedBundles() async {
    final data = await _channel.invokeMethod<List<dynamic>>('listReceivedBundles');
    final bundles = data ?? const <dynamic>[];

    return bundles
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => ReceivedBundle(
            name: item['name'] as String? ?? 'bundle.json',
            path: item['path'] as String? ?? '',
            sizeBytes: item['sizeBytes'] as int? ?? 0,
            lastModified: item['lastModified'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<List<PendingIncomingTransfer>> listPendingIncomingTransfers() async {
    final data = await _channel.invokeMethod<List<dynamic>>('listPendingIncomingTransfers');
    final items = data ?? const <dynamic>[];

    return items
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => PendingIncomingTransfer(
            id: item['id'] as String? ?? '',
            senderAddress: item['senderAddress'] as String? ?? 'unknown',
            fileName: item['fileName'] as String? ?? 'bundle.json',
            sizeBytes: item['sizeBytes'] as int? ?? 0,
            createdAt: item['createdAt'] as int? ?? 0,
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<P2POperationResult> approveIncomingTransfer(String id) async {
    final data = await _channel.invokeMapMethod<String, dynamic>(
      'approveIncomingTransfer',
      <String, dynamic>{'id': id},
    );
    return P2POperationResult(
      ok: data?['ok'] as bool? ?? false,
      message: data?['message'] as String? ?? 'Unknown approve result',
    );
  }

  Future<P2POperationResult> rejectIncomingTransfer(String id) async {
    final data = await _channel.invokeMapMethod<String, dynamic>(
      'rejectIncomingTransfer',
      <String, dynamic>{'id': id},
    );
    return P2POperationResult(
      ok: data?['ok'] as bool? ?? false,
      message: data?['message'] as String? ?? 'Unknown reject result',
    );
  }
}
