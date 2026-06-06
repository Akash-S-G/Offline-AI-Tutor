import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the active backend URL dynamically.
///
/// All network services consume [currentUrl] instead of a hardcoded config.
/// When discovery finds a new PiHub, calling [updateUrl] propagates the change
/// to every listener without requiring an app restart.
class BackendUrlManager extends ChangeNotifier {
  BackendUrlManager({required String initialUrl}) : _currentUrl = initialUrl {
    print('[DISCOVERY] BackendUrlManager initialized: $_currentUrl');
  }

  String _currentUrl;
  final StreamController<String> _urlStreamController =
      StreamController<String>.broadcast();

  /// The current active backend URL.
  String get currentUrl => _currentUrl;

  /// Stream of URL change events for reactive subscribers.
  Stream<String> get urlChanges => _urlStreamController.stream;

  static const _persistKey = 'backend_active_url';

  /// Update the backend URL at runtime.
  ///
  /// Notifies all listeners (ChangeNotifier + Stream).
  void updateUrl(String newUrl) {
    if (newUrl == _currentUrl || newUrl.isEmpty) return;

    final previousUrl = _currentUrl;
    _currentUrl = newUrl;

    print('[DISCOVERY] URL_UPDATED=$newUrl');
    print('[BACKEND] URL_SWITCH from=$previousUrl to=$newUrl');

    _urlStreamController.add(newUrl);
    notifyListeners();

    // Persist asynchronously — fire and forget
    _persist(newUrl);
  }

  /// Load persisted URL if available, otherwise keep initial.
  Future<void> loadPersistedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_persistKey);
      if (saved != null && saved.isNotEmpty && saved != _currentUrl) {
        print('[DISCOVERY] LOADED_PERSISTED_URL=$saved');
        _currentUrl = saved;
        _urlStreamController.add(saved);
        notifyListeners();
      }
    } catch (e) {
      print('[DISCOVERY] PERSIST_LOAD_ERROR=$e');
    }
  }

  Future<void> _persist(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistKey, url);
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlStreamController.close();
    super.dispose();
  }
}
