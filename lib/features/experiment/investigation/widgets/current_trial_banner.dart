import 'package:flutter/material.dart';

import '../trials/experiment_trial_manager.dart';

class CurrentTrialBanner extends StatelessWidget {
  final ExperimentTrialManager trialManager;

  const CurrentTrialBanner({super.key, required this.trialManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trialManager,
      builder: (context, _) {
        final trial = trialManager.activeTrial;
        if (trial == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Current Trial  #${trial.trialNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}
