import 'drying_time_estimate.dart';
import 'recommendation_status.dart';

class ScoreComponent {
  const ScoreComponent({
    required this.key,
    required this.label,
    required this.rawScore,
    required this.weight,
  });

  final String key;
  final String label;
  final double rawScore;
  final double weight;
}

class ScoreAdjustment {
  const ScoreAdjustment({
    required this.label,
    required this.delta,
  });

  final String label;
  final double delta;
}

class RecommendationScoreBreakdown {
  const RecommendationScoreBreakdown({
    required this.components,
    required this.adjustments,
    required this.finalScore,
    required this.status,
  });

  final List<ScoreComponent> components;
  final List<ScoreAdjustment> adjustments;
  final int finalScore;
  final RecommendationStatus status;
}

class RecommendationResult {
  const RecommendationResult({
    required this.score,
    required this.status,
    required this.headline,
    required this.description,
    required this.dryingEstimate,
    required this.breakdown,
  });

  final int score;
  final RecommendationStatus status;
  final String headline;
  final String description;
  final DryingTimeEstimate dryingEstimate;
  final RecommendationScoreBreakdown breakdown;
}
