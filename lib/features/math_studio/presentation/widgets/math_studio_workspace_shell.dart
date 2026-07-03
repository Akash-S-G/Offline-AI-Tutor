import 'package:flutter/material.dart';

import '../../../../core/theme/idp_colors.dart';

class MathStudioWorkspaceShell extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxContentWidth;

  const MathStudioWorkspaceShell({
    super.key,
    required this.title,
    required this.accentColor,
    required this.children,
    this.actions = const [],
    this.maxContentWidth = 960,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        actions: actions,
      ),
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + bottomPadding + bottomInset,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
