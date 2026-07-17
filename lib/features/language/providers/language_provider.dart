import 'package:flutter/foundation.dart';

import '../models/app_language.dart';
import '../services/language_service.dart';

/// Reactive state holder for the current application language.
///
/// Follows the same [ChangeNotifier] pattern used by every other
/// controller in this app.  Call [initialize] once at startup,
/// then use [setLanguage] to switch.
class LanguageProvider extends ChangeNotifier {
  LanguageProvider({LanguageService? service})
      : _service = service ?? LanguageService() {
    _sharedInstance ??= this;
  }

  static LanguageProvider? _sharedInstance;
  static LanguageProvider get shared => _sharedInstance ??= LanguageProvider();

  final LanguageService _service;

  AppLanguage _currentLanguage = AppLanguage.english;
  bool _initialized = false;

  // --------------- Public API ---------------

  /// The language the UI is currently using.
  AppLanguage get currentLanguage => _currentLanguage;

  /// BCP-47 code for backend API headers / query params.
  String get languageCode => _currentLanguage.code;

  /// Whether the script direction is right-to-left.
  bool get isRtl => _currentLanguage.isRtl;

  /// Whether [initialize] has completed.
  bool get initialized => _initialized;

  /// Load the persisted language preference.
  /// Safe to call multiple times — only the first call does work.
  Future<void> initialize() async {
    if (_initialized) return;
    _currentLanguage = await _service.loadSavedLanguage();
    _initialized = true;
    notifyListeners();
  }

  /// Switch the active language, persist the choice, and notify the UI.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _currentLanguage) return;
    _currentLanguage = language;
    await _service.saveLanguage(language);
    notifyListeners();
  }
}
