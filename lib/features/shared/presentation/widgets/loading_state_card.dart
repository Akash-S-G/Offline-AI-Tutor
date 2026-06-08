import 'package:flutter/material.dart';

class LoadingStateCard extends StatelessWidget {
  final String message;

  const LoadingStateCard({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
