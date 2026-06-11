import 'package:flutter/material.dart';

class ExperimentCanvas extends StatelessWidget {
  final Widget child;

  const ExperimentCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: ClipRect(child: SizedBox.expand(child: child)),
      ),
    );
  }
}
