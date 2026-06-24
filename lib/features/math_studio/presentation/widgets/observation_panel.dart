import 'package:flutter/material.dart';
import '../../../../core/theme/idp_colors.dart';

class ObservationPanel extends StatefulWidget {
  final TextEditingController controller;

  const ObservationPanel({super.key, required this.controller});

  @override
  State<ObservationPanel> createState() => _ObservationPanelState();
}

class _ObservationPanelState extends State<ObservationPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: IDPColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Observation Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: IDPColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: IDPColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: widget.controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g., I noticed that increasing a makes the parabola narrower.',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
