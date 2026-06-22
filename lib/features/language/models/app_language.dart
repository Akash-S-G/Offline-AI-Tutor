/// Supported application languages.
///
/// Each language carries metadata needed for display, persistence,
/// and backend API requests. The laptop server handles all
/// translation/TTS/ASR — Flutter only tracks the user's preference.
enum AppLanguage {
  english(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
  ),
  hindi(
    code: 'hi',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
  ),
  kannada(
    code: 'kn',
    displayName: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
  );

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
  });

  /// BCP-47 language code sent to the backend.
  final String code;

  /// English name for logs / debugging.
  final String displayName;

  /// Name in the language's own script (shown in UI).
  final String nativeName;

  /// All supported scripts are LTR, but kept for future-proofing.
  bool get isRtl => false;

  /// Look up a language by its BCP-47 code.
  /// Returns [AppLanguage.english] if the code is unrecognized.
  static AppLanguage fromCode(String code) {
    for (final lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return AppLanguage.english;
  }
}
