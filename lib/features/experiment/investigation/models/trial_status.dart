enum TrialStatus { running, saved, discarded }

TrialStatus trialStatusFromString(String? value) {
  switch (value) {
    case 'running':
      return TrialStatus.running;
    case 'discarded':
      return TrialStatus.discarded;
    case 'saved':
    default:
      return TrialStatus.saved;
  }
}
