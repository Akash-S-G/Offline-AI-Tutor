import 'package:flutter/material.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/theme/idp_typography.dart';

class FormattedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const FormattedTextWidget({required this.text, this.style, super.key});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final lines = text.split('\n');
    final List<Widget> children = [];

    List<String> currentList = [];

    void flushList() {
      if (currentList.isNotEmpty) {
        children.add(_buildBulletList(currentList));
        currentList = [];
      }
    }

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushList();
        children.add(const SizedBox(height: 8));
        continue;
      }

      // Check for bullet list
      if (trimmed.startsWith('* ') || trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        final content = trimmed.substring(2);
        currentList.add(content);
      } else {
        flushList();
        
        // Check for headers
        if (trimmed.startsWith('### ')) {
          children.add(Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(4),
              style: IDPTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: IDPColors.primary,
              ),
            ),
          ));
        } else if (trimmed.startsWith('## ')) {
          children.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              trimmed.substring(3),
              style: IDPTypography.titleMd.copyWith(
                fontWeight: FontWeight.bold,
                color: IDPColors.primary,
              ),
            ),
          ));
        } else if (trimmed.startsWith('# ')) {
          children.add(Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: IDPTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: IDPColors.primary,
              ),
            ),
          ));
        } else {
          // Normal text line
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildRichText(line),
          ));
        }
      }
    }

    flushList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: IDPColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: _buildRichText(item)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRichText(String rawText) {
    final spans = <TextSpan>[];
    final parts = rawText.split('**');
    
    final baseStyle = style ?? IDPTypography.bodyMd.copyWith(color: IDPColors.onSurface);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty && i == 0) continue; // Skip empty first element if text starts with **
      
      // Odd indices are bold because they are between ** markers
      final isBold = i % 2 != 0;
      spans.add(TextSpan(
        text: parts[i],
        style: isBold ? boldStyle : baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}
