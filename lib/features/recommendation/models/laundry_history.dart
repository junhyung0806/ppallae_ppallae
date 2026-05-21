import 'laundry_difficulty.dart';

enum RecommendationDecision {
  accepted,
  ignored,
  manualStart,
}

class LaundryHistoryEntry {
  const LaundryHistoryEntry({
    required this.startedAt,
    required this.difficulty,
    required this.decision,
    required this.indoorDrying,
  });

  final DateTime startedAt;
  final LaundryDifficulty difficulty;
  final RecommendationDecision decision;
  final bool indoorDrying;
}

class LaundryPatternSummary {
  const LaundryPatternSummary({
    required this.preferredStartHours,
    required this.nightLaundryAffinity,
    required this.extraHeavyUsageRatio,
    required this.recommendationAcceptanceRate,
  });

  final Set<int> preferredStartHours;
  final double nightLaundryAffinity;
  final double extraHeavyUsageRatio;
  final double recommendationAcceptanceRate;

  double hourAffinityFor(DateTime time) {
    if (preferredStartHours.contains(time.hour)) {
      return 1.0;
    }

    if (time.hour >= 20 || time.hour <= 1) {
      return nightLaundryAffinity;
    }

    return 0.0;
  }
}
