import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';

/// Stateless persistence helper for the user's language preference.
///
/// Wraps [SharedPreferences] so the rest of the language feature
/// doesn't need to know about the storage mechanism.
class LanguageService {
  static const String _key = 'app_language_code';

  /// Load the previously saved language, defaulting to English.
  Future<AppLanguage> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null) return AppLanguage.english;
    return AppLanguage.fromCode(code);
  }

  /// Persist the user's language choice.
  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}
