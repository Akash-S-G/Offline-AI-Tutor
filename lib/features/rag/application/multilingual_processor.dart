/// Handles multilingual text processing for English and Kannada
class MultilingualProcessor {
  /// Detect language of text
  static String detectLanguage(String text) {
    // Check for Kannada Unicode range: U+0C80–U+0CFF
    if (RegExp(r'[\u0C80-\u0CF3]').hasMatch(text)) {
      return 'kn';
    }
    return 'en';
  }

  /// Normalize Kannada text (preserve Unicode, handle ligatures)
  static String normalizeKannada(String text) {
    var normalized = text;

    // Normalize Kannada virama (halant) usage
    // KANNADA SIGN VIRAMA U+0CCD
    normalized = normalized.replaceAll(RegExp(r'್+'), '್');

    // Normalize nuktas (combining marks)
    // Remove zero-width joiners that might cause issues
    normalized = normalized.replaceAll(RegExp(r'[\u200B\u200C\u200D]'), '');

    return normalized;
  }

  /// Extract transliteration variants for search flexibility
  /// e.g., "ರೇಖೀಯ" -> ["rekhiya", "rekiya"]
  static List<String> getTransliterationVariants(String kannadaText) {
    // Simple mapping of Kannada to Latin transliteration
    final mapping = {
      'ಕ': 'k',
      'ಖ': 'kh',
      'ಗ': 'g',
      'ಘ': 'gh',
      'ಙ': 'ng',
      'ಚ': 'ch',
      'ಛ': 'chh',
      'ಜ': 'j',
      'ಝ': 'jh',
      'ಞ': 'ny',
      'ಟ': 'ta',
      'ಠ': 'tha',
      'ಡ': 'da',
      'ಢ': 'dha',
      'ಣ': 'na',
      'ತ': 't',
      'ಥ': 'th',
      'ದ': 'd',
      'ಧ': 'dh',
      'ನ': 'n',
      'ಪ': 'p',
      'ಫ': 'ph',
      'ಬ': 'b',
      'ಭ': 'bh',
      'ಮ': 'm',
      'ಯ': 'y',
      'ರ': 'r',
      'ಲ': 'l',
      'ವ': 'v',
      'ಶ': 'sh',
      'ಷ': 'sh',
      'ಸ': 's',
      'ಹ': 'h',
      'ಾ': 'a',
      'ಿ': 'i',
      'ೀ': 'ee',
      'ು': 'u',
      'ೂ': 'oo',
      'ೃ': 'ri',
      'ೇ': 'e',
      'ೈ': 'ai',
      'ೋ': 'o',
      'ೌ': 'ou',
      'ಂ': 'n',
      'ಃ': 'h',
      'ತ್ರ': 'tra',
      'ದ್ರ': 'dra',
      'ಹ್ರ': 'hra',
    };

    var transliterated = kannadaText;

    // Replace each Kannada character with Latin equivalent
    mapping.forEach((kannada, latin) {
      transliterated = transliterated.replaceAll(kannada, latin);
    });

    // Remove combining marks that might remain
    transliterated = transliterated.replaceAll(RegExp(r'[್]'), '');

    // Generate variants with different spacing/joining
    return {
      transliterated, // Standard
      transliterated.replaceAll(RegExp(r'\s+'), ''),  // No spaces
      transliterated.toLowerCase(),
      transliterated.replaceAll(RegExp(r'\s+'), '_'), // Underscores
    }.toList();
  }

  /// Create bilingual definition format
  static String createBilingualDefinition(
    String englishTerm,
    String kannedaTerm,
    String definition,
  ) {
    return '$englishTerm / $kannedaTerm\n$definition';
  }

  /// Extract language-specific metadata
  static Map<String, dynamic> getLanguageMetadata(String language) {
    return {
      'language': language,
      'direction': language == 'ar' ? 'rtl' : 'ltr',
      'script': language == 'kn' ? 'Kannada' : 'Latin',
      'tokenizer': language == 'kn' ? 'kannada_aware' : 'unicode61',
      'min_chunk_size': language == 'kn' ? 40 : 50, // Kannada typically shorter
    };
  }

  /// Check if text is predominantly one language
  static bool isPureLang(String text, String targetLang) {
    if (targetLang == 'kn') {
      final kannadaChars = RegExp(r'[\u0C80-\u0CF3]').allMatches(text).length;
      final totalChars = text.replaceAll(RegExp(r'\s'), '').length;
      return (kannadaChars / (totalChars > 0 ? totalChars : 1)) > 0.9;
    } else {
      // English: check for Latin characters
      final englishChars = RegExp(r'[a-zA-Z0-9]').allMatches(text).length;
      final totalChars = text.replaceAll(RegExp(r'\s'), '').length;
      return (englishChars / (totalChars > 0 ? totalChars : 1)) > 0.85;
    }
  }

  /// Clean up mixed-language text
  static String cleanMixedLanguage(String text) {
    // Remove control characters
    var cleaned = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Normalize spaces between scripts
    cleaned = cleaned.replaceAll(
      RegExp(r'([\u0C80-\u0CF3])\s+([\u0C80-\u0CF3])'),
      r'$1$2',
    );

    return cleaned;
  }

  /// Generate search variants for multilingual retrieval
  static List<String> generateSearchVariants(String query, String language) {
    final variants = <String>{query};

    if (language == 'kn') {
      // Add transliteration variants
      variants.addAll(getTransliterationVariants(query));
    } else {
      // English: add lowercase variants
      variants.add(query.toLowerCase());
      variants.add(query.toUpperCase());
    }

    // Remove duplicates
    return variants.toList();
  }

  /// Estimate text quality (completeness, encoding issues)
  static double estimateTextQuality(String text) {
    if (text.isEmpty) return 0.0;

    var score = 1.0;

    // Check for encoding issues (replacement characters)
    final replacementChars = RegExp(r'[\uFFFD]').allMatches(text).length;
    if (replacementChars > 0) {
      score -= (replacementChars / text.length) * 0.3; // Max -0.3
    }

    // Check for excessive control characters
    final controlChars =
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').allMatches(text).length;
    if (controlChars > 0) {
      score -= (controlChars / text.length) * 0.2; // Max -0.2
    }

    // Check for garbled sequences
    final garbledPattern =
        RegExp(r'[^\p{L}\p{N}\p{P}\p{Z}]', unicode: true);
    final garbled = garbledPattern.allMatches(text).length;
    if (garbled > text.length * 0.3) {
      score -= 0.25;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Log quality issues for manual review
  static List<String> getQualityIssues(String text, String language) {
    final issues = <String>[];

    if (text.isEmpty) {
      issues.add('Text is empty');
    }

    if (RegExp(r'[\uFFFD]').hasMatch(text)) {
      issues.add('Encoding issues detected (replacement characters)');
    }

    if (language == 'kn' && RegExp(r'[a-zA-Z]').hasMatch(text)) {
      // Kannada text with lots of English might indicate encoding issues
      final englishRatio = RegExp(r'[a-zA-Z]').allMatches(text).length /
          (text.isNotEmpty ? text.length : 1);
      if (englishRatio > 0.3) {
        issues.add('Mixed script detected (mostly Kannada with significant English)');
      }
    }

    if (text.length < 20) {
      issues.add('Text is very short (< 20 chars)');
    }

    return issues;
  }
}
