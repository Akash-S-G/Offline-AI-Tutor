import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../providers/language_provider.dart';

/// A reusable language picker that can be dropped into Settings,
/// Onboarding, or any dialog.
///
/// Shows all three supported languages with their native names.
/// Highlights the currently active language and calls
/// [LanguageProvider.setLanguage] on selection.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.languageProvider,
    this.compact = false,
  });

  final LanguageProvider languageProvider;

  /// When true, render as a compact horizontal chip row
  /// instead of vertical list tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, _) {
        if (compact) return _buildCompact(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == languageProvider.currentLanguage;
            return _LanguageTile(
              language: lang,
              isSelected: isSelected,
              onTap: () => languageProvider.setLanguage(lang),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AppLanguage.values.map((lang) {
        final isSelected = lang == languageProvider.currentLanguage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(lang.nativeName),
            selected: isSelected,
            onSelected: (_) => languageProvider.setLanguage(lang),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        language.nativeName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(language.displayName),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(40),
    );
  }
}
