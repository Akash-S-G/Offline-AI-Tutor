class ComparisonResult {
  final String parameter;
  final dynamic trialA;
  final dynamic trialB;
  final dynamic difference;

  const ComparisonResult({
    required this.parameter,
    required this.trialA,
    required this.trialB,
    required this.difference,
  });

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'trialA': trialA,
      'trialB': trialB,
      'difference': difference,
    };
  }
}
