import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_difficulty.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_history.dart';
import 'package:ppallae_ppallae/features/recommendation/models/recommendation_status.dart';
import 'package:ppallae_ppallae/features/recommendation/models/user_preference_settings.dart';
import 'package:ppallae_ppallae/features/recommendation/models/weather_snapshot.dart';
import 'package:ppallae_ppallae/features/recommendation/services/recommendation_engine.dart';

void main() {
  group('RecommendationEngine', () {
    const engine = RecommendationEngine();

    test('좋은 날씨와 가벼운 빨래는 높은 점수를 받는다', () {
      final result = engine.evaluate(
        RecommendationEngineInput(
          weather: const WeatherSnapshot(
            temperatureCelsius: 25,
            humidity: 40,
            windSpeedMps: 3.0,
            skyCondition: SkyCondition.sunny,
            rainProbability: 5,
          ),
          preferences: const UserPreferenceSettings(
            prioritizeFastDrying: true,
          ),
          patternSummary: const LaundryPatternSummary(
            preferredStartHours: <int>{13, 14},
            nightLaundryAffinity: 0.1,
            extraHeavyUsageRatio: 0.05,
            recommendationAcceptanceRate: 0.8,
          ),
          difficulty: LaundryDifficulty.light,
          startTime: DateTime(2026, 4, 20, 13),
        ),
      );

      expect(result.score, greaterThanOrEqualTo(80));
      expect(result.status, RecommendationStatus.good);
    });

    test('비 예보가 높고 초두꺼움이면 점수가 낮다', () {
      final result = engine.evaluate(
        RecommendationEngineInput(
          weather: const WeatherSnapshot(
            temperatureCelsius: 19,
            humidity: 80,
            windSpeedMps: 1.0,
            skyCondition: SkyCondition.rainy,
            rainProbability: 85,
          ),
          preferences: const UserPreferenceSettings(
            avoidRainExposure: true,
          ),
          patternSummary: const LaundryPatternSummary(
            preferredStartHours: <int>{21, 22},
            nightLaundryAffinity: 0.7,
            extraHeavyUsageRatio: 0.4,
            recommendationAcceptanceRate: 0.4,
          ),
          difficulty: LaundryDifficulty.extraHeavy,
          startTime: DateTime(2026, 4, 20, 21),
        ),
      );

      expect(result.score, lessThan(45));
      expect(result.status, RecommendationStatus.bad);
    });
  });
}
