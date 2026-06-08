import 'package:flutter/material.dart';
import '../theme/idp_colors.dart';
import '../theme/idp_theme.dart';

class IDPSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const IDPSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = IDPRadius.md,
  });

  @override
  State<IDPSkeletonLoader> createState() => _IDPSkeletonLoaderState();
}

class _IDPSkeletonLoaderState extends State<IDPSkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _colorTween = ColorTween(
      begin: IDPColors.surfaceVariant,
      end: IDPColors.border,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorTween.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
