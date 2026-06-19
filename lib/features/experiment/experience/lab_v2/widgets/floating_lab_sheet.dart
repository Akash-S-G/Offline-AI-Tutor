import 'package:flutter/material.dart';

class FloatingLabSheet extends StatelessWidget {
  final Widget child;
  final bool hidden;
  final DraggableScrollableController? controller;
  final double bottomInset;

  const FloatingLabSheet({
    super.key,
    required this.child,
    this.hidden = false,
    this.controller,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        controller: controller,
        initialChildSize: 0.05,
        minChildSize: 0.05,
        maxChildSize: 0.72,
        snap: true,
        snapSizes: const [0.05, 0.36, 0.72],
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxHeight < 72) {
                        return const SizedBox.shrink();
                      }
                      return PrimaryScrollController(
                        controller: scrollController,
                        child: child,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
