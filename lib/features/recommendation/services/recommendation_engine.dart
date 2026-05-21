import '../models/drying_time_estimate.dart';
import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/recommendation_result.dart';
import '../models/recommendation_status.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';
import 'drying_time_calculator.dart';
import 'recommendation_reason_builder.dart';
import 'recommendation_score_service.dart';

class RecommendationEngineInput {
  const RecommendationEngineInput({
    required this.weather,
    required this.preferences,
    required this.patternSummary,
    required this.difficulty,
    required this.startTime,
  });

  final WeatherSnapshot weather;
  final UserPreferenceSettings preferences;
  final LaundryPatternSummary patternSummary;
  final LaundryDifficulty difficulty;
  final DateTime startTime;
}

class RecommendationEngine {
  const RecommendationEngine({
    this.dryingTimeCalculator = const DryingTimeCalculator(),
    this.scoreService = const RecommendationScoreService(),
    this.reasonBuilder = const RecommendationReasonBuilder(),
  });

  final DryingTimeCalculator dryingTimeCalculator;
  final RecommendationScoreService scoreService;
  final RecommendationReasonBuilder reasonBuilder;

  RecommendationResult evaluate(RecommendationEngineInput input) {
    final dryingEstimate = dryingTimeCalculator.calculate(
      weather: input.weather,
      difficulty: input.difficulty,
      indoorDrying: input.preferences.useIndoorDryingMode,
    );

    final baseBreakdown = scoreService.calculate(
      RecommendationScoreInput(
        weather: input.weather,
        preferences: input.preferences,
        patternSummary: input.patternSummary,
        difficulty: input.difficulty,
        startTime: input.startTime,
      ),
    );

    final dryingAdjustment = _dryingAdjustment(dryingEstimate);
    final adjustments = [
      ...baseBreakdown.adjustments,
      if (dryingAdjustment != 0)
        ScoreAdjustment(
          label: '예상 건조 시간 보정',
          delta: dryingAdjustment.toDouble(),
        ),
    ];

    final finalScore = _clampInt(baseBreakdown.finalScore + dryingAdjustment, 0, 100);
    final finalStatus = _statusFromScoreAndEstimate(finalScore, dryingEstimate);
    final finalBreakdown = RecommendationScoreBreakdown(
      components: baseBreakdown.components,
      adjustments: adjustments,
      finalScore: finalScore,
      status: finalStatus,
    );

    final reasonContext = RecommendationReasonContext(
      startTime: input.startTime,
      difficulty: input.difficulty,
      weather: input.weather,
      breakdown: finalBreakdown,
      estimatedMinutes: dryingEstimate.estimatedMinutes,
      dryingDisplayText: dryingEstimate.displayText,
    );

    return RecommendationResult(
      score: finalScore,
      status: finalStatus,
      headline: reasonBuilder.buildHeadline(reasonContext),
      description: reasonBuilder.buildDescription(reasonContext),
      dryingEstimate: DryingTimeEstimate(
        estimatedMinutes: dryingEstimate.estimatedMinutes,
        displayText: dryingEstimate.displayText,
        exceedsEightHours: dryingEstimate.exceedsEightHours,
        status: finalStatus,
        explanation: dryingEstimate.explanation,
        factors: dryingEstimate.factors,
      ),
      breakdown: finalBreakdown,
    );
  }

  int _dryingAdjustment(DryingTimeEstimate estimate) {
    if (estimate.exceedsEightHours) {
      return -18;
    }

    if (estimate.estimatedMinutes >= 360) {
      return -10;
    }

    if (estimate.estimatedMinutes <= 180) {
      return 6;
    }

    return 0;
  }

  RecommendationStatus _statusFromScoreAndEstimate(
    int score,
    DryingTimeEstimate estimate,
  ) {
    if (estimate.exceedsEightHours || score < 45) {
      return RecommendationStatus.bad;
    }

    if (score < 75) {
      return RecommendationStatus.normal;
    }

    return RecommendationStatus.good;
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }

    if (value > max) {
      return max;
    }

    return value;
  }
}
