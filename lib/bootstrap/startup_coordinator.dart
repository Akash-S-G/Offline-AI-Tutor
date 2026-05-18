import 'package:flutter/foundation.dart';

import 'runtime_mode.dart';

class StartupCoordinator extends ChangeNotifier {
  StartupCoordinator({required this.runtimeMode});

  final RuntimeMode runtimeMode;

  final List<String> _messages = <String>[];
  String _currentStep = 'Preparing runtime...';
  bool _localAiReady = false;
  bool _offlineSearchReady = false;
  bool _syncReady = false;
  bool _backendConnected = false;
  bool _backgroundComplete = false;
  bool _optionalComplete = false;

  String get currentStep => _currentStep;
  bool get localAiReady => _localAiReady;
  bool get offlineSearchReady => _offlineSearchReady;
  bool get syncReady => _syncReady;
  bool get backendConnected => _backendConnected;
  bool get backgroundComplete => _backgroundComplete;
  bool get optionalComplete => _optionalComplete;

  List<String> get recentMessages => List.unmodifiable(_messages.take(5).toList());

  void beginStep(String step) {
    _currentStep = step;
    _messages.insert(0, step);
    _trimMessages();
    notifyListeners();
  }

  void completeStep(String step, {String? detail}) {
    _currentStep = detail ?? step;
    _messages.insert(0, detail ?? '$step ready');
    _trimMessages();
    notifyListeners();
  }

  void markLocalAiReady() {
    _localAiReady = true;
    notifyListeners();
  }

  void markOfflineSearchReady() {
    _offlineSearchReady = true;
    notifyListeners();
  }

  void markSyncReady() {
    _syncReady = true;
    notifyListeners();
  }

  void markBackendConnected() {
    _backendConnected = true;
    notifyListeners();
  }

  void markBackgroundComplete() {
    _backgroundComplete = true;
    notifyListeners();
  }

  void markOptionalComplete() {
    _optionalComplete = true;
    notifyListeners();
  }

  String runtimeBanner() {
    final parts = <String>[runtimeMode.label];
    if (_localAiReady) parts.add('Local AI Ready');
    if (_offlineSearchReady) parts.add('Offline Search Ready');
    if (_syncReady) parts.add('Sync Ready');
    if (_backendConnected) parts.add('Backend Connected');
    return parts.join(' • ');
  }

  void _trimMessages() {
    if (_messages.length <= 5) {
      return;
    }
    _messages.removeRange(5, _messages.length);
  }
}
