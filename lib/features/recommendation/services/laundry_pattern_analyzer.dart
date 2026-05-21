import '../models/laundry_history.dart';
import '../models/laundry_difficulty.dart';

class LaundryPatternAnalyzer {
  const LaundryPatternAnalyzer();

  LaundryPatternSummary summarize(List<LaundryHistoryEntry> history) {
    if (history.isEmpty) {
      return const LaundryPatternSummary(
        preferredStartHours: <int>{},
        nightLaundryAffinity: 0,
        extraHeavyUsageRatio: 0,
        recommendationAcceptanceRate: 0.5,
      );
    }

    final hourCounts = <int, int>{};
    var nightCount = 0;
    var acceptedCount = 0;
    var extraHeavyCount = 0;

    for (final entry in history) {
      hourCounts.update(entry.startedAt.hour, (count) => count + 1, ifAbsent: () => 1);

      if (entry.startedAt.hour >= 20 || entry.startedAt.hour <= 1) {
        nightCount += 1;
      }

      if (entry.decision == RecommendationDecision.accepted) {
        acceptedCount += 1;
      }

      if (entry.difficulty == LaundryDifficulty.extraHeavy) {
        extraHeavyCount += 1;
      }
    }

    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredHours = sortedHours.take(3).map((entry) => entry.key).toSet();

    return LaundryPatternSummary(
      preferredStartHours: preferredHours,
      nightLaundryAffinity: nightCount / history.length,
      extraHeavyUsageRatio: extraHeavyCount / history.length,
      recommendationAcceptanceRate: acceptedCount / history.length,
    );
  }
}
