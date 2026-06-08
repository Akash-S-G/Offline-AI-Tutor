import 'package:flutter/material.dart';
import '../theme/idp_colors.dart';
import '../theme/idp_theme.dart';
import '../theme/idp_typography.dart';

class IDPCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const IDPCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(IDPSpacing.md),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? IDPColors.surface,
      elevation: 0, // Flat design for modern look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IDPRadius.lg),
        side: const BorderSide(color: IDPColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IDPRadius.lg),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class IDPSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const IDPSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: IDPTypography.heading3),
              if (subtitle != null) ...[
                const SizedBox(height: IDPSpacing.xs),
                Text(subtitle!, style: IDPTypography.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class IDPBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const IDPBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: IDPSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
