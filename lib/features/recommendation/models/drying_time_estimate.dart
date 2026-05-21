import 'recommendation_status.dart';

class DryingFactorDetail {
  const DryingFactorDetail({
    required this.label,
    required this.factor,
    required this.reason,
  });

  final String label;
  final double factor;
  final String reason;
}

class DryingTimeEstimate {
  const DryingTimeEstimate({
    required this.estimatedMinutes,
    required this.displayText,
    required this.exceedsEightHours,
    required this.status,
    required this.explanation,
    required this.factors,
  });

  final int estimatedMinutes;
  final String displayText;
  final bool exceedsEightHours;
  final RecommendationStatus status;
  final String explanation;
  final List<DryingFactorDetail> factors;
}
