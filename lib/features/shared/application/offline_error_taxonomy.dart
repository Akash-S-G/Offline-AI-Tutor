import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum OfflineErrorCategory {
  invalidInput,
  unavailable,
  network,
  timeout,
  permission,
  storage,
  conflict,
  unsupported,
  parse,
  unknown,
}

enum OfflineErrorContext {
  general,
  chatInference,
  catalogSync,
  catalogDiscovery,
  catalogHealthCheck,
  contentImport,
  p2pStatus,
  p2pTransfer,
}

class OfflineErrorDetails {
  const OfflineErrorDetails({
    required this.category,
    required this.code,
    required this.title,
    required this.userMessage,
    required this.diagnosticMessage,
  });

  final OfflineErrorCategory category;
  final String code;
  final String title;
  final String userMessage;
  final String diagnosticMessage;

  String formatForUi() => '$title: $userMessage';
}

class OfflineErrorTaxonomy {
  const OfflineErrorTaxonomy._();

  static OfflineErrorDetails fromError(
    Object error, {
    OfflineErrorContext context = OfflineErrorContext.general,
    String? fallbackMessage,
  }) {
    if (error is TimeoutException) {
      return _details(
        category: OfflineErrorCategory.timeout,
        code: 'TIMEOUT',
        title: _titleFor(context, OfflineErrorCategory.timeout),
        userMessage: _messageFor(
          context,
          OfflineErrorCategory.timeout,
          fallbackMessage,
        ),
        diagnosticMessage: error.toString(),
      );
    }

    if (error is MissingPluginException) {
      return _details(
        category: OfflineErrorCategory.unsupported,
        code: 'MISSING_PLUGIN',
        title: _titleFor(context, OfflineErrorCategory.unsupported),
        userMessage: _messageFor(
          context,
          OfflineErrorCategory.unsupported,
          fallbackMessage,
        ),
        diagnosticMessage: error.message ?? error.toString(),
      );
    }

    if (error is SocketException || error is HttpException) {
      return _details(
        category: OfflineErrorCategory.network,
        code: 'NETWORK',
        title: _titleFor(context, OfflineErrorCategory.network),
        userMessage: _messageFor(
          context,
          OfflineErrorCategory.network,
          fallbackMessage,
        ),
        diagnosticMessage: error.toString(),
      );
    }

    if (error is FileSystemException) {
      return _details(
        category: OfflineErrorCategory.storage,
        code: 'STORAGE',
        title: _titleFor(context, OfflineErrorCategory.storage),
        userMessage: _messageFor(
          context,
          OfflineErrorCategory.storage,
          fallbackMessage,
        ),
        diagnosticMessage: error.toString(),
      );
    }

    if (error is FormatException) {
      return _details(
        category: OfflineErrorCategory.parse,
        code: 'PARSE',
        title: _titleFor(context, OfflineErrorCategory.parse),
        userMessage: _messageFor(
          context,
          OfflineErrorCategory.parse,
          fallbackMessage,
        ),
        diagnosticMessage: error.toString(),
      );
    }

    if (error is PlatformException) {
      final platformCode = error.code.trim().isEmpty ? 'PLATFORM' : error.code.trim();
      return _fromPlatformException(
        error,
        context: context,
        code: platformCode,
        fallbackMessage: fallbackMessage,
      );
    }

    final rawMessage = error.toString();
    return _details(
      category: _categoryFromText(rawMessage),
      code: 'UNKNOWN',
      title: _titleFor(context, _categoryFromText(rawMessage)),
      userMessage: _messageFor(
        context,
        _categoryFromText(rawMessage),
        fallbackMessage ?? rawMessage,
      ),
      diagnosticMessage: rawMessage,
    );
  }

  static OfflineErrorDetails _fromPlatformException(
    PlatformException error, {
    required OfflineErrorContext context,
    required String code,
    String? fallbackMessage,
  }) {
    final rawMessage = (error.message ?? '').trim();
    final combined = '$code ${rawMessage.isNotEmpty ? rawMessage : error.toString()}';
    final category = _categoryFromText(combined);
    return _details(
      category: category,
      code: code,
      title: _titleFor(context, category),
      userMessage: _messageFor(
        context,
        category,
        fallbackMessage ?? rawMessage,
      ),
      diagnosticMessage: error.toString(),
    );
  }

  static OfflineErrorDetails _details({
    required OfflineErrorCategory category,
    required String code,
    required String title,
    required String userMessage,
    required String diagnosticMessage,
  }) {
    return OfflineErrorDetails(
      category: category,
      code: code,
      title: title,
      userMessage: userMessage,
      diagnosticMessage: diagnosticMessage,
    );
  }

  static OfflineErrorCategory _categoryFromText(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return OfflineErrorCategory.timeout;
    }
    if (lower.contains('permission') || lower.contains('not granted')) {
      return OfflineErrorCategory.permission;
    }
    if (lower.contains('unsupported') || lower.contains('missingplugin')) {
      return OfflineErrorCategory.unsupported;
    }
    if (lower.contains('conflict') || lower.contains('already installed') || lower.contains('version')) {
      return OfflineErrorCategory.conflict;
    }
    if (lower.contains('parse') || lower.contains('format') || lower.contains('malformed')) {
      return OfflineErrorCategory.parse;
    }
    if (lower.contains('disk full') || lower.contains('space left') || lower.contains('filesystem')) {
      return OfflineErrorCategory.storage;
    }
    if (lower.contains('invalid') || lower.contains('empty') || lower.contains('required')) {
      return OfflineErrorCategory.invalidInput;
    }
    if (lower.contains('offline') || lower.contains('unavailable') || lower.contains('not found')) {
      return OfflineErrorCategory.unavailable;
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('host') || lower.contains('connection refused')) {
      return OfflineErrorCategory.network;
    }
    return OfflineErrorCategory.unknown;
  }

  static String _titleFor(OfflineErrorContext context, OfflineErrorCategory category) {
    switch (category) {
      case OfflineErrorCategory.timeout:
        return switch (context) {
          OfflineErrorContext.chatInference => 'Response timed out',
          OfflineErrorContext.catalogSync => 'Catalog sync timed out',
          OfflineErrorContext.catalogDiscovery => 'Discovery timed out',
          OfflineErrorContext.catalogHealthCheck => 'Health check timed out',
          OfflineErrorContext.contentImport => 'Import timed out',
          OfflineErrorContext.p2pStatus => 'Status request timed out',
          OfflineErrorContext.p2pTransfer => 'Transfer timed out',
          OfflineErrorContext.general => 'Operation timed out',
        };
      case OfflineErrorCategory.permission:
        return 'Permission required';
      case OfflineErrorCategory.network:
        return 'Network problem';
      case OfflineErrorCategory.storage:
        return 'Storage problem';
      case OfflineErrorCategory.conflict:
        return 'Version conflict';
      case OfflineErrorCategory.unsupported:
        return 'Unsupported on this device';
      case OfflineErrorCategory.parse:
        return 'Data parse failed';
      case OfflineErrorCategory.invalidInput:
        return 'Invalid input';
      case OfflineErrorCategory.unavailable:
        return 'Resource unavailable';
      case OfflineErrorCategory.unknown:
        return 'Operation failed';
    }
  }

  static String _messageFor(
    OfflineErrorContext context,
    OfflineErrorCategory category,
    String? fallbackMessage,
  ) {
    switch (category) {
      case OfflineErrorCategory.timeout:
        return switch (context) {
          OfflineErrorContext.chatInference =>
            'The model did not return quickly enough. Try Fast mode, shorten the prompt, or check the native engine.',
          OfflineErrorContext.catalogSync =>
            'The catalog server did not respond in time. Check the LAN URL or retry discovery.',
          OfflineErrorContext.catalogDiscovery =>
            'Discovery took too long. Verify the server is on the same network and try again.',
          OfflineErrorContext.catalogHealthCheck =>
            'The health check did not complete in time. Recheck the catalog URL and network path.',
          OfflineErrorContext.contentImport =>
            'The import took too long. Try a smaller archive or verify storage space.',
          OfflineErrorContext.p2pStatus =>
            'The P2P status request timed out. Retry after permissions and Wi-Fi stabilize.',
          OfflineErrorContext.p2pTransfer =>
            'The transfer took too long. Keep the devices close and retry on a stable network.',
          OfflineErrorContext.general =>
            'The operation took too long to finish. Please retry.',
        };
      case OfflineErrorCategory.permission:
        return switch (context) {
          OfflineErrorContext.p2pStatus || OfflineErrorContext.p2pTransfer =>
            'Grant Nearby Wi-Fi and Location permissions, then try again.',
          OfflineErrorContext.catalogDiscovery || OfflineErrorContext.catalogSync || OfflineErrorContext.catalogHealthCheck =>
            'Grant the required network permission and retry discovery.',
          _ => 'Grant the required permission and try again.',
        };
      case OfflineErrorCategory.network:
        return switch (context) {
          OfflineErrorContext.chatInference =>
            'The local model bridge is unreachable right now. Check the native engine and retry.',
          OfflineErrorContext.catalogSync || OfflineErrorContext.catalogDiscovery || OfflineErrorContext.catalogHealthCheck =>
            'The catalog server is not reachable. Check the LAN URL, hotspot, or Wi-Fi connection.',
          OfflineErrorContext.p2pStatus || OfflineErrorContext.p2pTransfer =>
            'The other device or local network is not reachable. Retry on the same Wi-Fi or hotspot.',
          _ => 'Check the connection and try again.',
        };
      case OfflineErrorCategory.storage:
        return switch (context) {
          OfflineErrorContext.contentImport =>
            'Free up storage space or choose a smaller pack, then import again.',
          _ => 'Check available storage and try again.',
        };
      case OfflineErrorCategory.conflict:
        return switch (context) {
          OfflineErrorContext.contentImport =>
            'That pack version is already installed or conflicts with a newer one.',
          _ => 'A newer or matching version is already present.',
        };
      case OfflineErrorCategory.unsupported:
        return switch (context) {
          OfflineErrorContext.chatInference =>
            'This platform does not support the native inference bridge yet.',
          OfflineErrorContext.p2pStatus || OfflineErrorContext.p2pTransfer =>
            'This transfer mode is not available on the current platform.',
          _ => 'This feature is not available on the current platform.',
        };
      case OfflineErrorCategory.parse:
        return switch (context) {
          OfflineErrorContext.contentImport =>
            'The archive or manifest looks invalid. Re-download the pack and try again.',
          _ => 'The app could not parse the response. Try again.',
        };
      case OfflineErrorCategory.invalidInput:
        return switch (context) {
          OfflineErrorContext.chatInference =>
            'Enter a question before sending it.',
          OfflineErrorContext.catalogSync || OfflineErrorContext.catalogDiscovery || OfflineErrorContext.catalogHealthCheck =>
            'Enter a valid catalog URL that starts with http:// or https://.',
          _ => fallbackMessage ?? 'Check the input and try again.',
        };
      case OfflineErrorCategory.unavailable:
        return switch (context) {
          OfflineErrorContext.chatInference =>
            'The model is not ready yet. Check the native engine setup.',
          OfflineErrorContext.catalogSync || OfflineErrorContext.catalogDiscovery || OfflineErrorContext.catalogHealthCheck =>
            'The catalog server is not available. Verify the machine hosting the packs is online.',
          OfflineErrorContext.p2pStatus || OfflineErrorContext.p2pTransfer =>
            'The other device is not available right now. Retry when both devices are connected.',
          _ => 'The requested resource is not available.',
        };
      case OfflineErrorCategory.unknown:
        return fallbackMessage?.trim().isNotEmpty == true
            ? fallbackMessage!.trim()
            : 'Something went wrong. Please retry.';
    }
  }
}