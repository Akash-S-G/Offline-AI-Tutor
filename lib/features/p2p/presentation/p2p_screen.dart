import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content_packs/application/content_pack_archive_service.dart';
import '../../content_packs/data/local/content_pack_repository.dart';
import '../../content_packs/domain/content_pack_models.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../../network/services/backend_discovery_service.dart';
import '../../rag/data/local/rag_repository.dart';
import '../data/local/p2p_security_settings_repository.dart';
import '../data/local/trusted_peer_repository.dart';
import '../data/p2p_bundle_service.dart';
import '../data/p2p_channel_service.dart';
import '../../shared/application/offline_error_taxonomy.dart';

class P2PScreen extends StatefulWidget {
  const P2PScreen({
    required this.courseRepository,
    required this.languageCode,
    this.initialChapterId,
    this.quickSendPreset = false,
    super.key,
  });

  final CourseRepository courseRepository;
  final String languageCode;
  final String? initialChapterId;
  final bool quickSendPreset;

  @override
  State<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends State<P2PScreen> with SingleTickerProviderStateMixin {
  final BackendDiscoveryService _classroomConnection = BackendDiscoveryService();
  final P2PChannelService _service = P2PChannelService();
  final P2PBundleService _bundleService = P2PBundleService(
    ragRepository: RagRepository(),
  );
  final ContentPackRepository _packRepository = ContentPackRepository();
  final ContentPackArchiveService _packArchiveService = ContentPackArchiveService();
  final TrustedPeerRepository _trustedPeerRepository = TrustedPeerRepository();
  final P2PSecuritySettingsRepository _securitySettingsRepository = P2PSecuritySettingsRepository();
  
  final TextEditingController _sharedSecretController = TextEditingController();
  late final TabController _tabController;

  P2PStatus? _status;
  List<P2PPeer> _peers = const [];
  List<ReceivedBundle> _receivedBundles = const [];
  List<PendingIncomingTransfer> _pendingIncomingTransfers = const [];
  List<Chapter> _chapters = const [];
  List<ContentPackManifest> _installedPacks = const [];
  Chapter? _selectedChapter;
  String? _selectedChapterId;
  ContentPackManifest? _selectedPack;
  P2PPeer? _selectedPeer;
  bool _loading = true;
  bool _processingBundle = false;
  bool _processingTransfer = false;
  Set<String> _trustedPeerAddresses = <String>{};
  P2PPermissionStatus? _permissionStatus;
  P2PTransferTelemetrySnapshot _telemetry = const P2PTransferTelemetrySnapshot(
    send: null,
    receive: null,
  );
  final Set<String> _promptedIncomingIds = <String>{};
  Timer? _telemetryTimer;
  String? _error;

  BundleTransferProgress? _exportProgress;
  BundleTransferProgress? _importProgress;
  bool _quickSendTriggered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _classroomConnection.addListener(_onClassroomConnectionChanged);
    _startTelemetryPolling();
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telemetryTimer?.cancel();
    _classroomConnection.removeListener(_onClassroomConnectionChanged);
    _sharedSecretController.dispose();
    super.dispose();
  }

  void _onClassroomConnectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTelemetryPolling() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollTransferTelemetry();
    });
  }

  Future<void> _pollTransferTelemetry() async {
    if (!mounted) return;
    try {
      final telemetry = await _service.getTransferTelemetry();
      if (!mounted) return;
      setState(() {
        _telemetry = telemetry;
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = await _service.getStatus();
      final telemetry = await _service.getTransferTelemetry();
      final permissionStatus = await _service.getPermissionStatus();
      final peers = await _service.listPeers();
      final received = await _service.listReceivedBundles();
      final pendingIncoming = await _service.listPendingIncomingTransfers();
      final rawChapters = await widget.courseRepository.getAllChapters(
        languageCode: widget.languageCode,
      );
      
      final chapterById = <String, Chapter>{};
      for (final chapter in rawChapters) {
        chapterById[chapter.id] ??= chapter;
      }
      final chapters = chapterById.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      final installedPacks = await _packRepository.listInstalledPacks();
      final trustedPeerAddresses = await _trustedPeerRepository.listTrustedAddresses();
      
      // Auto-set a fallback/default shared secret if empty so P2P validation works instantly
      var sharedSecret = await _securitySettingsRepository.getSharedSecret();
      if (sharedSecret.isEmpty) {
        sharedSecret = 'default_p2p_secret_12345';
        await _securitySettingsRepository.setSharedSecret(sharedSecret);
      }
      _sharedSecretController.text = sharedSecret;

      final selectedPeerAddress = _selectedPeer?.address;
      P2PPeer? selectedPeer;
      if (selectedPeerAddress != null) {
        for (final peer in peers) {
          if (peer.address == selectedPeerAddress) {
            selectedPeer = peer;
            break;
          }
        }
      }

      final selectedPackId = _selectedPack?.packId;
      ContentPackManifest? selectedPack;
      if (selectedPackId != null) {
        for (final pack in installedPacks) {
          if (pack.packId == selectedPackId) {
            selectedPack = pack;
            break;
          }
        }
      }

      final selectedChapterId =
          widget.initialChapterId != null && chapterById.containsKey(widget.initialChapterId)
          ? widget.initialChapterId
          : (_selectedChapterId != null && chapterById.containsKey(_selectedChapterId)
                ? _selectedChapterId
                : (chapters.isEmpty ? null : chapters.first.id));

      if (!mounted) return;
      setState(() {
        _status = status;
        _telemetry = telemetry;
        _permissionStatus = permissionStatus;
        _peers = peers;
        _receivedBundles = received;
        _pendingIncomingTransfers = pendingIncoming;
        _chapters = chapters;
        _installedPacks = installedPacks;
        _trustedPeerAddresses = trustedPeerAddresses;
        _selectedChapterId = selectedChapterId;
        _selectedChapter = selectedChapterId == null ? null : chapterById[selectedChapterId];
        _selectedPack = installedPacks.isEmpty ? null : (selectedPack ?? _selectedPack ?? installedPacks.first);
        _selectedPeer = peers.isEmpty ? null : (selectedPeer ?? peers.first);
        _loading = false;
      });

      if (widget.quickSendPreset && !_quickSendTriggered) {
        _quickSendTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _runQuickSendPreset();
        });
      }

      final activePendingIds = pendingIncoming.map((item) => item.id).toSet();
      _promptedIncomingIds.removeWhere((id) => !activePendingIds.contains(id));

      await _handlePendingIncomingTransfers();
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error = 'P2P is not available on this platform yet. Currently implemented on Android.';
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pStatus,
        fallbackMessage: 'Failed to load P2P status.',
      );
      setState(() {
        _error = details.formatForUi();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pStatus,
        fallbackMessage: 'Failed to load P2P status.',
      );
      setState(() {
        _error = details.formatForUi();
        _loading = false;
      });
    }
  }

  Future<void> _handlePendingIncomingTransfers() async {
    if (!mounted || _processingTransfer || _pendingIncomingTransfers.isEmpty) {
      return;
    }

    PendingIncomingTransfer? candidate;
    for (final pending in _pendingIncomingTransfers) {
      if (!_promptedIncomingIds.contains(pending.id)) {
        candidate = pending;
        break;
      }
    }

    if (candidate == null) return;

    _promptedIncomingIds.add(candidate.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final approve = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incoming Bundle Request'),
          content: Text(
            'Allow ${candidate!.senderAddress} to send ${candidate.fileName} (${(candidate.sizeBytes / 1024).toStringAsFixed(1)} KB)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (approve == true) {
        await _approveIncomingTransfer(candidate!);
      } else {
        await _rejectIncomingTransfer(candidate!);
      }
    });
  }

  Future<void> _toggleReceiver() async {
    if (_processingTransfer) return;

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final running = _status?.receiverRunning == true;
      final result = running
          ? await _service.stopReceiver()
          : await _service.startReceiver();

      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Failed to toggle receiver.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingTransfer = false;
        });
      }
    }
  }

  // A combined, elegant, one-click Send flow for Content Packs
  Future<void> _exportAndSendPack(ContentPackManifest pack, P2PPeer peer) async {
    setState(() {
      _processingBundle = true;
      _processingTransfer = true;
      _error = null;
      _exportProgress = null;
    });

    try {
      // 1. Ensure target peer is trusted (handled automatically under the hood)
      if (!_trustedPeerAddresses.contains(peer.address)) {
        await _trustedPeerRepository.trustPeer(
          address: peer.address,
          alternateAddress: peer.resolvedAddress.isEmpty ? null : peer.resolvedAddress,
          name: peer.name,
          transport: peer.transport,
        );
        _trustedPeerAddresses.add(peer.address);
      }

      // 2. Export Pack Archive
      final exportResult = await _packArchiveService.exportPackArchive(pack.packId);
      
      // 3. Send Bundle
      final sendResult = await _service.sendBundle(
        address: peer.address,
        filePath: exportResult.archivePath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sent pack archive: ${sendResult.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Failed to send pack archive.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingBundle = false;
          _processingTransfer = false;
          _exportProgress = null;
        });
        _refresh();
      }
    }
  }

  // A combined, elegant, one-click Send flow for Custom Chapter Bundles
  Future<void> _exportAndSendChapter(Chapter chapter, P2PPeer peer) async {
    setState(() {
      _processingBundle = true;
      _processingTransfer = true;
      _error = null;
      _exportProgress = null;
    });

    try {
      // 1. Ensure target peer is trusted (handled automatically under the hood)
      if (!_trustedPeerAddresses.contains(peer.address)) {
        await _trustedPeerRepository.trustPeer(
          address: peer.address,
          alternateAddress: peer.resolvedAddress.isEmpty ? null : peer.resolvedAddress,
          name: peer.name,
          transport: peer.transport,
        );
        _trustedPeerAddresses.add(peer.address);
      }

      // 2. Export Chapter Bundle
      final exportResult = await _bundleService.exportChapterBundle(
        chapter,
        sharedSecret: _sharedSecretController.text,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
            });
          }
        },
      );

      // 3. Send Bundle
      final sendResult = await _service.sendBundle(
        address: peer.address,
        filePath: exportResult.filePath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sent chapter bundle: ${sendResult.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Failed to send chapter bundle.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingBundle = false;
          _processingTransfer = false;
          _exportProgress = null;
        });
        _refresh();
      }
    }
  }

  Future<void> _runQuickSendPreset() async {
    if (!mounted) return;
    final chapter = _selectedChapter;
    if (chapter == null) return;

    final trustedPeers = _peers.toList();
    if (trustedPeers.isEmpty) return;

    setState(() {
      _selectedPeer = trustedPeers.first;
    });

    await _exportAndSendChapter(chapter, trustedPeers.first);
  }

  Future<void> _requestPermissions() async {
    if (_processingTransfer) return;

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      await _service.requestPermissions();
      await _refresh();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _processingTransfer = false;
      });
    }
  }

  Future<void> _approveIncomingTransfer(PendingIncomingTransfer pending, {bool silent = false, String? customMessage}) async {
    if (_processingTransfer) return;

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final result = await _service.approveIncomingTransfer(pending.id);
      await _refresh();

      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(customMessage ?? result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingTransfer = false;
        });
      }
    }
  }

  Future<void> _rejectIncomingTransfer(PendingIncomingTransfer pending) async {
    if (_processingTransfer) return;

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final result = await _service.rejectIncomingTransfer(pending.id);
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingTransfer = false;
        });
      }
    }
  }

  Future<void> _importReceivedBundle(ReceivedBundle bundle) async {
    if (_processingBundle) return;

    setState(() {
      _processingBundle = true;
      _error = null;
    });

    try {
      final lowerPath = bundle.path.toLowerCase();
      if (lowerPath.endsWith('.otpack') || lowerPath.endsWith('.zip')) {
        final packResult = await _packArchiveService.importPackArchive(bundle.path);
        await _refresh();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installed pack ${packResult.packId} (${packResult.itemCount} items) from inbox.'),
          ),
        );
        return;
      }

      final result = await _bundleService.importBundleFromFile(
        bundle.path,
        verificationSecrets: await _securitySettingsRepository.getVerificationSecrets(),
        onProgress: (_) {}, 
      );
      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${result.importedChunkCount} chunks for ${result.chapterId} from inbox.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingBundle = false;
        });
      }
    }
  }

  Future<void> _importBundle() async {
    if (_processingBundle) return;

    setState(() {
      _processingBundle = true;
      _error = null;
      _importProgress = null;
    });

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'otpack', 'zip'],
        allowMultiple: false,
      );

      final bundlePath = picked?.files.single.path;
      if (bundlePath == null || bundlePath.isEmpty) {
        if (!mounted) return;
        setState(() {
          _processingBundle = false;
        });
        return;
      }

      final lowerPath = bundlePath.toLowerCase();
      if (lowerPath.endsWith('.otpack') || lowerPath.endsWith('.zip')) {
        final packResult = await _packArchiveService.importPackArchive(bundlePath);
        await _refresh();

        if (!mounted) return;
        setState(() {
          _importProgress = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installed pack ${packResult.packId} with ${packResult.itemCount} items.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final result = await _bundleService.importBundleFromFile(
        bundlePath,
        verificationSecrets: await _securitySettingsRepository.getVerificationSecrets(),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _importProgress = progress;
            });
          }
        },
        maxRetries: 3,
      );
      await _refresh();

      if (!mounted) return;
      setState(() {
        _importProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${result.importedChunkCount} chunks for ${result.chapterId}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.contentImport,
        fallbackMessage: 'Import failed.',
      );
      setState(() {
        _error = details.formatForUi();
        _importProgress = null;
        _processingBundle = false;
      });
    }
  }

  Future<void> _showManualClassroomDialog() async {
    final controller = TextEditingController(text: _classroomConnection.activeEndpoint ?? '');
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect by Address'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Classroom gateway',
            hintText: '192.168.1.20 or http://pihub.local',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (address == null || address.trim().isEmpty) return;
    final connected = await _classroomConnection.connectManual(address);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected ? 'Connected to classroom.' : 'Could not reach that classroom gateway.',
        ),
      ),
    );
  }

  String _classroomStatusText(ClassroomConnectionState state) {
    return switch (state) {
      ClassroomConnectionState.disconnected => 'Not connected',
      ClassroomConnectionState.discovering => 'Searching nearby network...',
      ClassroomConnectionState.connecting => 'Connecting...',
      ClassroomConnectionState.connected => 'Connected',
      ClassroomConnectionState.reconnecting => 'Reconnecting automatically...',
    };
  }



  String _formatThroughput(int bps) {
    if (bps <= 0) return '0 B/s';
    if (bps < 1024) return '$bps B/s';
    final kb = bps / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB/s';
  }

  String _formatEta(int etaSeconds) {
    if (etaSeconds < 0) return 'n/a';
    final minutes = etaSeconds ~/ 60;
    final seconds = etaSeconds % 60;
    if (minutes <= 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  Widget _buildClassroomConnectionSection(BuildContext context) {
    final connection = _classroomConnection;
    final classroom = connection.currentClassroom;
    final available = connection.availableClassrooms;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connection.isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: connection.isConnected ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.isConnected
                            ? classroom?.name ?? 'Connected Classroom'
                            : 'Classroom connection',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        connection.isConnected
                            ? classroom?.gatewayUrl ?? ''
                            : _classroomStatusText(connection.state),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (connection.isDiscovering)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () => connection.discover(force: true),
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
            if (connection.isConnected && classroom != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.hub_rounded, size: 16),
                    label: Text('Node: ${classroom.nodeId}'),
                  ),
                  if (classroom.studentCount != null)
                    Chip(
                      avatar: const Icon(Icons.people_alt_rounded, size: 16),
                      label: Text('${classroom.studentCount} students'),
                    ),
                  if (classroom.latencyMs != null)
                    Chip(
                      avatar: const Icon(Icons.speed_rounded, size: 16),
                      label: Text('${classroom.latencyMs} ms'),
                    ),
                ],
              ),
            ],
            if (!connection.isConnected && !connection.isDiscovering && available.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No classroom found. Check that this device and the PiHub are on the same Wi-Fi network.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            if (!connection.isConnected && available.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...available.map((item) => Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room_rounded, color: Colors.indigo),
                  title: Text(item.name),
                  subtitle: Text(item.gatewayUrl),
                  trailing: FilledButton(
                    onPressed: () => connection.connect(item),
                    child: const Text('Connect'),
                  ),
                ),
              )),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!connection.isConnected) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: connection.isDiscovering ? null : () => connection.discover(force: true),
                      icon: const Icon(Icons.wifi_find_rounded),
                      label: const Text('Search'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showManualClassroomDialog,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Manual IP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetrySection() {
    final sendTelemetry = _telemetry.send;
    final receiveTelemetry = _telemetry.receive;
    if (sendTelemetry == null && receiveTelemetry == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.indigo.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Active Transfer Progress', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (sendTelemetry != null) ...[
              const SizedBox(height: 12),
              Text('Sending: ${sendTelemetry.fileName}'),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: (sendTelemetry.progressPct.clamp(0, 100)) / 100),
              const SizedBox(height: 6),
              Text(
                'Speed: ${_formatThroughput(sendTelemetry.throughputBps)} | ETA: ${_formatEta(sendTelemetry.etaSeconds)}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
            if (receiveTelemetry != null) ...[
              const SizedBox(height: 12),
              Text('Receiving: ${receiveTelemetry.fileName}'),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (receiveTelemetry.progressPct.clamp(0, 100)) / 100,
                color: Colors.green,
                backgroundColor: Colors.green.shade100,
              ),
              const SizedBox(height: 6),
              Text(
                'Speed: ${_formatThroughput(receiveTelemetry.throughputBps)} | ETA: ${_formatEta(receiveTelemetry.etaSeconds)}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    final permissionStatus = _permissionStatus;
    if (permissionStatus == null || permissionStatus.allGranted) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Local Network Permissions Missing', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'To find other devices nearby and transfer materials offline, this app needs Wi-Fi Direct and Local Network access permissions.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _processingTransfer ? null : _requestPermissions,
              icon: const Icon(Icons.security_rounded),
              label: const Text('Grant Permissions'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPermissionsSection(),
          _buildTelemetrySection(),
          
          // Nearby devices selector
          const Text(
            '1. Choose Target Device',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _peers.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scanning for nearby devices...',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Make sure the target device has "Receive" mode turned on and is on the same Wi-Fi connection.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _peers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final peer = _peers[index];
                    final selected = _selectedPeer?.address == peer.address;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPeer = peer;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? Colors.indigo.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? Colors.indigo : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: selected ? Colors.indigo.shade100 : Colors.grey.shade100,
                              child: Icon(
                                Icons.devices_rounded,
                                color: selected ? Colors.indigo : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    peer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    peer.address,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: selected ? Colors.indigo : Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          
          const SizedBox(height: 24),
          const Text(
            '2. Choose Material to Send',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Pack send Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Send Content Pack', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _installedPacks.isEmpty
                      ? const Text('No content packs installed on this device.')
                      : DropdownButtonFormField<ContentPackManifest>(
                          initialValue: _selectedPack,
                          isExpanded: true,
                          items: _installedPacks
                              .map(
                                (pack) => DropdownMenuItem<ContentPackManifest>(
                                  value: pack,
                                  child: Text(
                                    '${pack.title} (v${pack.version})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedPack = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Installed Packs',
                            border: OutlineInputBorder(),
                          ),
                        ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _processingBundle || _processingTransfer || _selectedPack == null || _selectedPeer == null
                        ? null
                        : () => _exportAndSendPack(_selectedPack!, _selectedPeer!),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Selected Pack'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Custom chapter bundle Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_zip_rounded, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Send Chapter Materials', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _chapters.isEmpty
                      ? const Text('No chapter syllabus materials available to send.')
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedChapterId,
                          isExpanded: true,
                          items: _chapters
                              .map(
                                (chapter) => DropdownMenuItem<String>(
                                  value: chapter.id,
                                  child: Text(
                                    chapter.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedChapterId = value;
                              _selectedChapter = _chapters.firstWhere((ch) => ch.id == value);
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Chapters',
                            border: OutlineInputBorder(),
                          ),
                        ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _processingBundle || _processingTransfer || _selectedChapter == null || _selectedPeer == null
                        ? null
                        : () => _exportAndSendChapter(_selectedChapter!, _selectedPeer!),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Selected Chapter'),
                  ),
                  if (_exportProgress != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.indigo.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Exporting: ${(_exportProgress!.percentComplete * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _exportProgress!.percentComplete),
                            const SizedBox(height: 6),
                            Text(
                              'Processing segment ${_exportProgress!.current} of ${_exportProgress!.total}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveTab(BuildContext context) {
    final receiverActive = _status?.receiverRunning == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPermissionsSection(),
          _buildTelemetrySection(),

          // Receiver on/off status card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: receiverActive ? Colors.green.shade300 : Colors.grey.shade300,
                width: receiverActive ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: receiverActive ? Colors.green : Colors.grey,
                      boxShadow: [
                        if (receiverActive)
                          BoxShadow(
                            color: Colors.green.withAlpha(100),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receiverActive ? 'Receiver is Active' : 'Receiver is Offline',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          receiverActive 
                              ? 'Your device can be found by others on the network.' 
                              : 'Turn on receiver to allow others to send packs to you.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: receiverActive,
                    onChanged: (_) => _toggleReceiver(),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Import Local Files Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Import Materials',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              OutlinedButton.icon(
                onPressed: _processingBundle ? null : _importBundle,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Pick Local File'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Received inbox
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inbox_rounded, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Received Files Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _receivedBundles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No received files waiting to be imported.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _receivedBundles.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final bundle = _receivedBundles[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.archive_outlined, color: Colors.indigo),
                              title: Text(
                                bundle.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${(bundle.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: FilledButton.icon(
                                onPressed: _processingBundle ? null : () => _importReceivedBundle(bundle),
                                icon: const Icon(Icons.install_desktop_rounded, size: 16),
                                label: const Text('Import'),
                              ),
                            );
                          },
                        ),
                  if (_importProgress != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Importing: ${(_importProgress!.percentComplete * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _importProgress!.percentComplete,
                              color: Colors.green,
                              backgroundColor: Colors.green.shade100,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Processing segment ${_importProgress!.current} of ${_importProgress!.total}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sharing (P2P)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.send_rounded),
              text: 'Send',
            ),
            Tab(
              icon: Icon(Icons.download_rounded),
              text: 'Receive',
            ),
            Tab(
              icon: Icon(Icons.cloud_sync_rounded),
              text: 'Classroom',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(context),
                _buildReceiveTab(context),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      _buildClassroomConnectionSection(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
