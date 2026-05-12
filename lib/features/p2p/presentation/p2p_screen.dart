import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../application/p2p_secret_bootstrap_service.dart';
import '../../content_packs/application/content_pack_archive_service.dart';
import '../../content_packs/data/local/content_pack_repository.dart';
import '../../content_packs/domain/content_pack_models.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../../rag/data/local/rag_repository.dart';
import '../data/local/p2p_security_settings_repository.dart';
import '../data/local/trusted_peer_repository.dart';
import '../data/p2p_bundle_service.dart';
import '../data/p2p_channel_service.dart';
import '../../shared/application/offline_error_taxonomy.dart';

class P2PScreen extends StatefulWidget {
  const P2PScreen({
    required this.courseRepository,
    this.initialChapterId,
    this.quickSendPreset = false,
    super.key,
  });

  final CourseRepository courseRepository;
  final String? initialChapterId;
  final bool quickSendPreset;

  @override
  State<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends State<P2PScreen> {
  final P2PChannelService _service = P2PChannelService();
  final P2PBundleService _bundleService = P2PBundleService(
    ragRepository: RagRepository(),
  );
  final ContentPackRepository _packRepository = ContentPackRepository();
  final ContentPackArchiveService _packArchiveService = ContentPackArchiveService();
  final TrustedPeerRepository _trustedPeerRepository = TrustedPeerRepository();
  final P2PSecuritySettingsRepository _securitySettingsRepository =
      P2PSecuritySettingsRepository();
  final P2PSecretBootstrapService _bootstrapService = P2PSecretBootstrapService();
  final TextEditingController _sharedSecretController = TextEditingController();
  final TextEditingController _rotationSecretController = TextEditingController();
  final TextEditingController _bootstrapPasscodeController = TextEditingController();
  final TextEditingController _importTokenController = TextEditingController();
  final TextEditingController _importPasscodeController = TextEditingController();
  final TextEditingController _apkDownloadUrlController = TextEditingController();

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
  String? _lastExportPath;
  int _rotationGraceHours = 24;
  int _previousSecretExpiresAt = 0;
  bool _previousSecretActive = false;
  bool _loading = true;
  bool _processingBundle = false;
  bool _processingTransfer = false;
  bool _downloadingApk = false;
  bool _showSharedSecret = false;
  bool _autoAcceptTrustedUnknown = true;
  Set<String> _trustedPeerAddresses = <String>{};
  P2PPermissionStatus? _permissionStatus;
  P2PTransferTelemetrySnapshot _telemetry =
      const P2PTransferTelemetrySnapshot(send: null, receive: null);
  final Set<String> _promptedIncomingIds = <String>{};
  Timer? _telemetryTimer;
  String? _error;
  
  BundleTransferProgress? _exportProgress;
  BundleTransferProgress? _importProgress;
  bool _quickSendTriggered = false;

  @override
  void initState() {
    super.initState();
    _apkDownloadUrlController.text =
        'https://example.com/releases/offline_tutor_app-latest.apk';
    _startTelemetryPolling();
    _refresh();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _sharedSecretController.dispose();
    _rotationSecretController.dispose();
    _bootstrapPasscodeController.dispose();
    _importTokenController.dispose();
    _importPasscodeController.dispose();
    _apkDownloadUrlController.dispose();
    super.dispose();
  }

  void _startTelemetryPolling() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollTransferTelemetry();
    });
  }

  Future<void> _pollTransferTelemetry() async {
    if (!mounted) {
      return;
    }
    try {
      final telemetry = await _service.getTransferTelemetry();
      if (!mounted) {
        return;
      }
      setState(() {
        _telemetry = telemetry;
      });
    } catch (_) {
      // Ignore telemetry polling failures and continue.
    }
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
      final rawChapters = await widget.courseRepository.getAllChapters();
      final chapterById = <String, Chapter>{};
      for (final chapter in rawChapters) {
        chapterById[chapter.id] ??= chapter;
      }
      final chapters = chapterById.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      final installedPacks = await _packRepository.listInstalledPacks();
      final trustedPeerAddresses = await _trustedPeerRepository.listTrustedAddresses();
      final sharedSecret = await _securitySettingsRepository.getSharedSecret();
      final autoAcceptTrustedUnknown =
          await _securitySettingsRepository.getAutoAcceptTrustedUnknown();
      final rotationStatus = await _securitySettingsRepository.getRotationStatus();
      await _securitySettingsRepository.clearExpiredPreviousSecret();
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
      if (!mounted) {
        return;
      }
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
        _autoAcceptTrustedUnknown = autoAcceptTrustedUnknown;
        _sharedSecretController.text = sharedSecret;
        _previousSecretExpiresAt =
            rotationStatus['previousSecretExpiresAt'] as int? ?? 0;
        _previousSecretActive =
            rotationStatus['previousSecretActive'] as bool? ?? false;
        _selectedChapterId = selectedChapterId;
        _selectedChapter =
          selectedChapterId == null ? null : chapterById[selectedChapterId];
        _selectedPack = installedPacks.isEmpty
            ? null
            : (selectedPack ?? _selectedPack ?? installedPacks.first);
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
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'P2P is not available on this platform yet. Currently implemented on Android.';
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
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

    if (_autoAcceptTrustedUnknown) {
      for (final pending in _pendingIncomingTransfers) {
        final trusted = _trustedPeerAddresses.contains(pending.senderAddress);
        if (trusted) {
          await _approveIncomingTransfer(
            pending,
            silent: true,
            customMessage: 'Auto-approved trusted sender ${pending.senderAddress}',
          );
          return;
        }
      }
    }

    PendingIncomingTransfer? candidate;
    for (final pending in _pendingIncomingTransfers) {
      if (!_promptedIncomingIds.contains(pending.id)) {
        candidate = pending;
        break;
      }
    }

    if (candidate == null) {
      return;
    }

    _promptedIncomingIds.add(candidate.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
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

  Future<void> _exportBundle() async {
    final chapter = _selectedChapter;
    if (chapter == null || _processingBundle) {
      return;
    }

    setState(() {
      _processingBundle = true;
      _error = null;
      _exportProgress = null;
    });

    try {
      final result = await _bundleService.exportChapterBundle(
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
      if (!mounted) {
        return;
      }

      setState(() {
        _lastExportPath = result.filePath;
        _exportProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${result.chunkCount} chunks to ${result.filePath.split('/').last}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Export failed.',
      );
      setState(() {
        _error = details.formatForUi();
        _exportProgress = null;
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
    if (_processingBundle) {
      return;
    }

    setState(() {
      _processingBundle = true;
      _error = null;
      _importProgress = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'otpack', 'zip'],
        allowMultiple: false,
      );

      final bundlePath = picked?.files.single.path;
      if (bundlePath == null || bundlePath.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _processingBundle = false;
        });
        return;
      }

      final lowerPath = bundlePath.toLowerCase();
      if (lowerPath.endsWith('.otpack') || lowerPath.endsWith('.zip')) {
        final packResult = await _packArchiveService.importPackArchive(bundlePath);
        await _refresh();

        if (!mounted) {
          return;
        }

        setState(() {
          _importProgress = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installed pack ${packResult.packId} with ${packResult.itemCount} items.',
            ),
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

      if (!mounted) {
        return;
      }

      setState(() {
        _importProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.importedChunkCount} chunks for ${result.chapterId} (manifest v${result.manifestVersion})',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.contentImport,
        fallbackMessage: 'Import failed.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingBundle = false;
        });
      }
    }
  }

  Future<void> _toggleReceiver() async {
    if (_processingTransfer) {
      return;
    }

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
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
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

  Future<void> _sendLastBundleToPeer() async {
    final peer = _selectedPeer;
    final exportPath = _lastExportPath;
    if (peer == null || exportPath == null || exportPath.isEmpty || _processingTransfer) {
      return;
    }
    if (!_trustedPeerAddresses.contains(peer.address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust this peer before sending bundles.')),
      );
      return;
    }

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final result = await _service.sendBundle(
        address: peer.address,
        filePath: exportPath,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Failed to send bundle.',
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

  Future<void> _runQuickSendPreset() async {
    if (!mounted) {
      return;
    }

    final chapter = _selectedChapter;
    if (chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick send skipped: no chapter selected.')),
      );
      return;
    }

    if (_sharedSecretController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick send skipped: save a shared secret first.'),
        ),
      );
      return;
    }

    final trustedPeers = _peers
        .where((peer) => _trustedPeerAddresses.contains(peer.address))
        .toList();
    if (trustedPeers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick send skipped: trust at least one peer first.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedPeer = trustedPeers.first;
      _lastExportPath = null;
    });

    await _exportBundle();
    if (!mounted) {
      return;
    }

    if (_lastExportPath == null || _lastExportPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick send export did not produce a bundle.')),
      );
      return;
    }

    await _sendLastBundleToPeer();
  }

  Future<void> _requestPermissions() async {
    if (_processingTransfer) {
      return;
    }

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final status = await _service.requestPermissions();
      if (!mounted) {
        return;
      }

      setState(() {
        _permissionStatus = status;
      });
      await _refresh();
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pStatus,
        fallbackMessage: 'Permission request failed.',
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

  Future<void> _approveIncomingTransfer(
    PendingIncomingTransfer pending, {
    bool silent = false,
    String? customMessage,
  }) async {
    if (_processingTransfer) {
      return;
    }

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final result = await _service.approveIncomingTransfer(pending.id);
      await _refresh();
      if (!mounted) {
        return;
      }
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(customMessage ?? result.message)),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Approve incoming transfer failed.',
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

  Future<void> _rejectIncomingTransfer(PendingIncomingTransfer pending) async {
    if (_processingTransfer) {
      return;
    }

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      final result = await _service.rejectIncomingTransfer(pending.id);
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Reject incoming transfer failed.',
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

  Future<void> _saveSharedSecret() async {
    final value = _sharedSecretController.text.trim();
    await _securitySettingsRepository.setSharedSecret(value);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value.isEmpty
              ? 'Shared secret cleared. Signed bundle transfer is disabled.'
              : 'Shared secret saved for signed bundle export/import.',
        ),
      ),
    );
  }

  Future<void> _setAutoAcceptTrustedUnknown(bool value) async {
    await _securitySettingsRepository.setAutoAcceptTrustedUnknown(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _autoAcceptTrustedUnknown = value;
    });
    await _refresh();
  }

  Future<void> _toggleTrustForSelectedPeer() async {
    final peer = _selectedPeer;
    if (peer == null || _processingTransfer) {
      return;
    }

    setState(() {
      _processingTransfer = true;
      _error = null;
    });

    try {
      if (_trustedPeerAddresses.contains(peer.address)) {
        await _trustedPeerRepository.untrustPeer(peer.address);
      } else {
        await _trustedPeerRepository.trustPeer(
          address: peer.address,
          alternateAddress:
              peer.resolvedAddress.isEmpty ? null : peer.resolvedAddress,
          name: peer.name,
          transport: peer.transport,
        );
      }

      await _refresh();
      if (!mounted) {
        return;
      }

      final trustedNow = _trustedPeerAddresses.contains(peer.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trustedNow
                ? 'Peer trusted: ${peer.name} (${peer.address})'
                : 'Peer removed from trusted list: ${peer.address}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
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
    if (_processingBundle) {
      return;
    }

    setState(() {
      _processingBundle = true;
      _error = null;
    });

    try {
      final lowerPath = bundle.path.toLowerCase();
      if (lowerPath.endsWith('.otpack') || lowerPath.endsWith('.zip')) {
        final packResult = await _packArchiveService.importPackArchive(bundle.path);
        await _refresh();
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installed pack ${packResult.packId} (${packResult.itemCount} items) from inbox.',
            ),
          ),
        );
        return;
      }

      final result = await _bundleService.importBundleFromFile(
        bundle.path,
        verificationSecrets: await _securitySettingsRepository.getVerificationSecrets(),
        onProgress: (_) {}, // Silent progress for auto-import
      );
      await _refresh();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.importedChunkCount} chunks for ${result.chapterId} from inbox.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
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

  Future<void> _shareApkFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['apk'],
        allowMultiple: false,
      );
      final apkPath = picked?.files.single.path;
      if (apkPath == null || apkPath.isEmpty) {
        return;
      }

      await Share.shareXFiles(
        <XFile>[XFile(apkPath)],
        text: 'Offline Tutor app install package',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.p2pTransfer,
        fallbackMessage: 'Failed to share APK.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    }
  }

  Future<void> _exportSelectedPack() async {
    final pack = _selectedPack;
    if (pack == null || _processingBundle) {
      return;
    }

    setState(() {
      _processingBundle = true;
      _error = null;
      _exportProgress = null;
    });

    try {
      final result = await _packArchiveService.exportPackArchive(pack.packId);
      if (!mounted) {
        return;
      }

      setState(() {
        _lastExportPath = result.archivePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported pack ${result.packId}: ${result.itemCount} items to ${result.archivePath.split('/').last}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.contentImport,
        fallbackMessage: 'Pack export failed.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processingBundle = false;
        });
      }
    }
  }

  Future<void> _downloadApkFromUrl() async {
    if (_downloadingApk) {
      return;
    }

    final raw = _apkDownloadUrlController.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
      setState(() {
        _error = 'Enter a valid APK URL (http/https).';
      });
      return;
    }

    setState(() {
      _downloadingApk = true;
      _error = null;
    });

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Download failed with HTTP ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) {
        throw Exception('Downloaded file is empty.');
      }

      final tempDir = await getTemporaryDirectory();
      final inferredName = uri.pathSegments.isEmpty
          ? 'offline_tutor_app-latest.apk'
          : uri.pathSegments.last;
      final fileName = inferredName.toLowerCase().endsWith('.apk')
          ? inferredName
          : '$inferredName.apk';
      final output = File('${tempDir.path}/$fileName');
      await output.writeAsBytes(bytes, flush: true);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('APK downloaded: ${output.path}')),
      );

      await Share.shareXFiles(
        <XFile>[XFile(output.path)],
        text: 'Downloaded APK package',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final details = OfflineErrorTaxonomy.fromError(
        e,
        context: OfflineErrorContext.contentImport,
        fallbackMessage: 'APK download failed.',
      );
      setState(() {
        _error = details.formatForUi();
      });
    } finally {
      client?.close(force: true);
      if (mounted) {
        setState(() {
          _downloadingApk = false;
        });
      }
    }
  }

  Offset _peerRadarPosition(int index, int totalPeers) {
    final total = totalPeers <= 0 ? 1 : totalPeers;
    final angle = (2 * math.pi * index / total) - (math.pi / 2);
    final ring = 0.24 + ((index % 3) * 0.16);
    return Offset(
      0.5 + (math.cos(angle) * ring),
      0.5 + (math.sin(angle) * ring),
    );
  }

  String _peerLabel(P2PPeer peer) {
    final trusted = _trustedPeerAddresses.contains(peer.address);
    final trustLabel = trusted ? 'trusted' : 'untrusted';
    return '${peer.transport} • $trustLabel';
  }

  String _formatThroughput(int bps) {
    if (bps <= 0) {
      return '0 B/s';
    }
    if (bps < 1024) {
      return '$bps B/s';
    }
    final kb = bps / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB/s';
  }

  String _formatEta(int etaSeconds) {
    if (etaSeconds < 0) {
      return 'n/a';
    }
    final minutes = etaSeconds ~/ 60;
    final seconds = etaSeconds % 60;
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  Future<void> _rotateSharedSecret() async {
    final nextSecret = _rotationSecretController.text.trim();
    if (nextSecret.isEmpty) {
      setState(() {
        _error = 'Enter a new secret to rotate.';
      });
      return;
    }

    await _securitySettingsRepository.rotateSharedSecret(
      newSecret: nextSecret,
      gracePeriod: Duration(hours: _rotationGraceHours),
    );
    _rotationSecretController.clear();
    await _refresh();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Secret rotated. Previous secret valid for $_rotationGraceHours hours.',
        ),
      ),
    );
  }

  Future<void> _showExportBootstrapDialog() async {
    final secret = _sharedSecretController.text.trim();
    if (secret.isEmpty) {
      setState(() {
        _error = 'Set and save a shared secret before bootstrap export.';
      });
      return;
    }

    _bootstrapPasscodeController.clear();
    await showDialog<void>(
      context: context,
      builder: (context) {
        String? token;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Export Bootstrap Token'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter a passcode to encrypt a short-lived bootstrap token.',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bootstrapPasscodeController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Bootstrap passcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final pin = _bootstrapPasscodeController.text.trim();
                        if (pin.isEmpty) {
                          return;
                        }
                        final created = _bootstrapService.createBootstrapToken(
                          sharedSecret: secret,
                          passcode: pin,
                          ttl: const Duration(minutes: 15),
                        );
                        setLocalState(() {
                          token = created;
                        });
                      },
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Generate QR Token'),
                    ),
                    if (token != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: QrImageView(
                          data: token!,
                          size: 200,
                          version: QrVersions.auto,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(token!),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Share.share(token!);
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Token'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showImportBootstrapDialog() async {
    _importTokenController.clear();
    _importPasscodeController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Bootstrap Token'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste token and passcode to recover shared secret securely.',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _importTokenController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bootstrap token',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _importPasscodeController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Bootstrap passcode',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final imported = _bootstrapService.importBootstrapToken(
                  token: _importTokenController.text,
                  passcode: _importPasscodeController.text,
                );
                await _securitySettingsRepository.setSharedSecret(imported.secret);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                await _refresh();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Shared secret imported from bootstrap token.'),
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                final details = OfflineErrorTaxonomy.fromError(
                  e,
                  context: OfflineErrorContext.p2pStatus,
                  fallbackMessage: 'Secret import failed.',
                );
                messenger.showSnackBar(
                  SnackBar(content: Text(details.formatForUi())),
                );
              }
            },
            child: const Text('Import Secret'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final sendTelemetry = _telemetry.send;
    final receiveTelemetry = _telemetry.receive;
    final permissionStatus = _permissionStatus;
    final selectedPeerTrusted =
        _selectedPeer != null && _trustedPeerAddresses.contains(_selectedPeer!.address);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline P2P Sharing'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!),
                    ),
                  if (widget.quickSendPreset) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedChapter == null
                                  ? 'Quick send mode: waiting for chapter selection.'
                                  : 'Quick send mode: ${_selectedChapter!.title}',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _processingBundle || _processingTransfer
                                ? null
                                : _runQuickSendPreset,
                            child: const Text('Run Now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'P2P Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Transport: ${status?.transport ?? 'unknown'}')),
                            Chip(label: Text('Route: ${status?.routeDecision ?? 'NONE'}')),
                            Chip(label: Text('Peers: ${status?.pairedCount ?? 0}')),
                            Chip(label: Text('Inbox: ${status?.inboxCount ?? 0}')),
                            Chip(
                              label: Text(
                                status?.receiverRunning == true ? 'Receiver: ON' : 'Receiver: OFF',
                              ),
                            ),
                            Chip(
                              label: Text(
                                status?.localIp.isNotEmpty == true
                                    ? 'Local IP: ${status?.localIp}'
                                    : 'Local IP: n/a',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'APK Distribution',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apkDownloadUrlController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'APK URL',
                            hintText: 'https://.../offline_tutor_app.apk',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _downloadingApk ? null : _downloadApkFromUrl,
                              icon: _downloadingApk
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: const Text('Download APK'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _shareApkFile,
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share Existing APK'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (sendTelemetry != null || receiveTelemetry != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Transfer Telemetry',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (sendTelemetry != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Send: ${sendTelemetry.fileName} (${sendTelemetry.stage})'),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (sendTelemetry.progressPct.clamp(0, 100)) / 100,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Peer: ${sendTelemetry.peerAddress} | ${sendTelemetry.progressPct}% | ${_formatThroughput(sendTelemetry.throughputBps)} | ETA: ${_formatEta(sendTelemetry.etaSeconds)}',
                            ),
                            if (sendTelemetry.done && !sendTelemetry.success)
                              Text(
                                'Error: ${sendTelemetry.errorMessage}',
                                style: const TextStyle(color: Color(0xFFB91C1C)),
                              ),
                          ],
                        ),
                      ),
                    if (sendTelemetry != null && receiveTelemetry != null)
                      const SizedBox(height: 8),
                    if (receiveTelemetry != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FEE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Receive: ${receiveTelemetry.fileName} (${receiveTelemetry.stage})'),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (receiveTelemetry.progressPct.clamp(0, 100)) / 100,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Peer: ${receiveTelemetry.peerAddress} | ${receiveTelemetry.progressPct}% | ${_formatThroughput(receiveTelemetry.throughputBps)} | ETA: ${_formatEta(receiveTelemetry.etaSeconds)}',
                            ),
                            if (receiveTelemetry.done && !receiveTelemetry.success)
                              Text(
                                'Error: ${receiveTelemetry.errorMessage}',
                                style: const TextStyle(color: Color(0xFFB91C1C)),
                              ),
                          ],
                        ),
                      ),
                  ],
                  if (permissionStatus != null && !permissionStatus.allGranted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wi-Fi Direct permission setup required',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${permissionStatus.locationGranted ? 'granted' : 'missing'} | Nearby Wi-Fi: ${permissionStatus.requiresNearbyWifi ? (permissionStatus.nearbyWifiGranted ? 'granted' : 'missing') : 'not required'}',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _processingTransfer ? null : _requestPermissions,
                            icon: const Icon(Icons.security_rounded),
                            label: const Text('Grant Local Network Permissions'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((status?.lastTransferError ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last transfer error: ${status!.lastTransferError}',
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _processingTransfer ? null : _toggleReceiver,
                          icon: Icon(
                            status?.receiverRunning == true
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline_rounded,
                          ),
                          label: Text(
                            status?.receiverRunning == true
                                ? 'Stop Receiver'
                                : 'Start Receiver',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<P2PPeer>(
                    initialValue: _selectedPeer,
                    items: _peers
                        .map(
                          (peer) => DropdownMenuItem<P2PPeer>(
                            value: peer,
                            child: Text('${peer.name} (${peer.address})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPeer = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Target peer (LAN / Wi-Fi Direct fallback)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectedPeer == null || _processingTransfer
                              ? null
                              : _toggleTrustForSelectedPeer,
                          icon: Icon(
                            selectedPeerTrusted
                                ? Icons.verified_user_outlined
                                : Icons.shield_outlined,
                          ),
                          label: Text(
                            selectedPeerTrusted ? 'Untrust Selected Peer' : 'Trust Selected Peer',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPeer != null)
                    Text(
                      selectedPeerTrusted
                          ? 'Selected peer is trusted for outgoing bundle transfers.'
                          : 'Selected peer is not trusted. Sending is blocked until trusted.',
                      style: TextStyle(
                        color: selectedPeerTrusted
                            ? const Color(0xFF065F46)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  if (_selectedPeer != null && _selectedPeer!.transport == 'wifi-direct')
                    Text(
                      _selectedPeer!.resolvedAddress.isNotEmpty
                          ? 'Wi-Fi Direct route ready: ${_selectedPeer!.resolvedAddress}'
                          : 'Wi-Fi Direct route will be established on send.',
                      style: const TextStyle(color: Color(0xFF1D4ED8)),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: (_processingTransfer || _lastExportPath == null || !selectedPeerTrusted)
                        ? null
                        : _sendLastBundleToPeer,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      _lastExportPath == null
                          ? 'Export bundle first to enable sending'
                          : (selectedPeerTrusted
                              ? 'Send Last Exported Bundle'
                              : 'Trust peer to enable sending'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Material Pack Transfer (PDF/Video/Quiz/Resources)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ContentPackManifest>(
                    initialValue: _selectedPack,
                    items: _installedPacks
                        .map(
                          (pack) => DropdownMenuItem<ContentPackManifest>(
                            value: pack,
                            child: Text('${pack.title} (v${pack.version})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedPack = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Installed content pack',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _processingBundle || _selectedPack == null
                              ? null
                              : _exportSelectedPack,
                          icon: const Icon(Icons.inventory_rounded),
                          label: const Text('Export Pack (.otpack)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bundle Transfer (Manifest + Hash Validation)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedChapterId,
                    items: _chapters
                        .map(
                          (chapter) => DropdownMenuItem<String>(
                            value: chapter.id,
                            child: Text(chapter.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedChapterId = value;
                        _selectedChapter = _chapterById(value);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Chapter for content bundle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _processingBundle ? null : _exportBundle,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Export Bundle'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _processingBundle ? null : _importBundle,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Import Bundle'),
                        ),
                      ),
                    ],
                  ),
                  if (_exportProgress != null) ...[const SizedBox(height: 12),
 Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Exporting bundle...',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                '${_exportProgress!.current}/${_exportProgress!.total}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _exportProgress!.percentComplete,
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_importProgress != null) ...[const SizedBox(height: 12),
 Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF0),
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Importing bundle...',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                '${_importProgress!.current}/${_importProgress!.total}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _importProgress!.percentComplete,
                            minHeight: 6,
                            backgroundColor: Colors.green.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null && (_exportProgress == null && _importProgress == null)) ...[const SizedBox(height: 12),
 Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E0),
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                  const Text(
                    'Security Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sharedSecretController,
                    obscureText: !_showSharedSecret,
                    decoration: InputDecoration(
                      labelText: 'Shared secret for HMAC-signed bundles',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showSharedSecret = !_showSharedSecret;
                          });
                        },
                        icon: Icon(
                          _showSharedSecret
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveSharedSecret,
                          icon: const Icon(Icons.key_outlined),
                          label: const Text('Save Shared Secret'),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: _autoAcceptTrustedUnknown,
                    onChanged: _setAutoAcceptTrustedUnknown,
                    title: const Text('Auto-accept trusted peers'),
                    subtitle: const Text('Unknown peers will still require manual accept/reject.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Key Rotation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rotationSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New shared secret',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Grace window (hours): '),
                      DropdownButton<int>(
                        value: _rotationGraceHours,
                        items: const [1, 6, 12, 24, 48, 72]
                            .map(
                              (h) => DropdownMenuItem<int>(
                                value: h,
                                child: Text('$h'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _rotationGraceHours = value;
                          });
                        },
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _rotateSharedSecret,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Rotate'),
                      ),
                    ],
                  ),
                  if (_previousSecretActive)
                    Text(
                      'Previous secret active until ${DateTime.fromMillisecondsSinceEpoch(_previousSecretExpiresAt)}',
                      style: const TextStyle(color: Color(0xFF1D4ED8)),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure Bootstrap Exchange',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showExportBootstrapDialog,
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('Export QR Token'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showImportBootstrapDialog,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Import Token'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pending Incoming Transfers',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _pendingIncomingTransfers.isEmpty
                        ? const Center(child: Text('No pending incoming transfers.'))
                        : ListView.builder(
                            itemCount: _pendingIncomingTransfers.length,
                            itemBuilder: (context, index) {
                              final pending = _pendingIncomingTransfers[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.notifications_active_outlined),
                                title: Text(pending.fileName),
                                subtitle: Text('From ${pending.senderAddress}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${(pending.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _processingTransfer
                                          ? null
                                          : () => _rejectIncomingTransfer(pending),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 6),
                                    FilledButton(
                                      onPressed: _processingTransfer
                                          ? null
                                          : () => _approveIncomingTransfer(pending),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Received Bundles (Native Inbox)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _receivedBundles.isEmpty
                        ? const Center(child: Text('No bundles received yet.'))
                        : ListView.builder(
                            itemCount: _receivedBundles.length,
                            itemBuilder: (context, index) {
                              final bundle = _receivedBundles[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(bundle.name),
                                subtitle: Text(bundle.path),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${(bundle.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _processingBundle
                                          ? null
                                          : () => _importReceivedBundle(bundle),
                                      child: const Text('Import'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nearby Devices Radar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1221),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _peers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No nearby peers found. Start receiver on both devices and stay on same Wi-Fi.',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              return Stack(
                                children: [
                                  CustomPaint(
                                    size: size,
                                    painter: _RadarPainter(),
                                  ),
                                  for (var i = 0; i < _peers.length; i++)
                                    Builder(
                                      builder: (context) {
                                        final peer = _peers[i];
                                        final normalized = _peerRadarPosition(i, _peers.length);
                                        final trusted = _trustedPeerAddresses.contains(peer.address);
                                        final selected = _selectedPeer?.address == peer.address;
                                        final x = (normalized.dx * size.width) - 34;
                                        final y = (normalized.dy * size.height) - 34;

                                        return Positioned(
                                          left: x,
                                          top: y,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedPeer = peer;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: selected ? 68 : 58,
                                              height: selected ? 68 : 58,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: trusted
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFF2563EB),
                                                border: Border.all(
                                                  color: selected
                                                      ? Colors.amberAccent
                                                      : Colors.white24,
                                                  width: selected ? 3 : 1,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black45,
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  peer.name.isNotEmpty
                                                      ? peer.name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: _peers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final peer = _peers[index];
                        final trusted = _trustedPeerAddresses.contains(peer.address);
                        final selected = _selectedPeer?.address == peer.address;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPeer = peer;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: trusted
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFDBEAFE),
                                  child: Icon(
                                    trusted
                                        ? Icons.verified_user_outlined
                                        : Icons.devices_rounded,
                                    color: trusted
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        peer.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        peer.resolvedAddress.isEmpty
                                            ? peer.address
                                            : '${peer.address} -> ${peer.resolvedAddress}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _peerLabel(peer),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Chapter? _chapterById(String chapterId) {
    for (final chapter in _chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF22D3EE).withAlpha(45),
          const Color(0xFF22D3EE).withAlpha(10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      );
    canvas.drawCircle(center, maxRadius, sweepPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white24
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), ringPaint);
    }

    final crossPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), crossPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), crossPaint);

    final centerPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(center, 6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
