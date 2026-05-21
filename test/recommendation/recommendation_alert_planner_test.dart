import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_alert.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_difficulty.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_history.dart';
import 'package:ppallae_ppallae/features/recommendation/models/user_preference_settings.dart';
import 'package:ppallae_ppallae/features/recommendation/models/weather_snapshot.dart';
import 'package:ppallae_ppallae/features/recommendation/services/recommendation_alert_planner.dart';

void main() {
  group('RecommendationAlertPlanner', () {
    const planner = RecommendationAlertPlanner();

    test('비 예보와 습도 급상승 알림을 함께 계획한다', () {
      final now = DateTime(2026, 4, 20, 9);
      final forecasts = [
        HourlyWeatherForecast(
          at: DateTime(2026, 4, 20, 9),
          weather: WeatherSnapshot(
            temperatureCelsius: 22,
            humidity: 48,
            windSpeedMps: 2.6,
            skyCondition: SkyCondition.partlyCloudy,
            rainProbability: 20,
          ),
        ),
        HourlyWeatherForecast(
          at: DateTime(2026, 4, 20, 10),
          weather: WeatherSnapshot(
            temperatureCelsius: 23,
            humidity: 66,
            windSpeedMps: 2.5,
            skyCondition: SkyCondition.cloudy,
            rainProbability: 40,
          ),
        ),
        HourlyWeatherForecast(
          at: DateTime(2026, 4, 20, 12),
          weather: WeatherSnapshot(
            temperatureCelsius: 21,
            humidity: 72,
            windSpeedMps: 1.2,
            skyCondition: SkyCondition.rainy,
            rainProbability: 70,
          ),
        ),
      ];

      final alerts = planner.plan(
        now: now,
        forecasts: forecasts,
        preferences: const UserPreferenceSettings(),
        patternSummary: const LaundryPatternSummary(
          preferredStartHours: <int>{11, 12},
          nightLaundryAffinity: 0.2,
          extraHeavyUsageRatio: 0.1,
          recommendationAcceptanceRate: 0.7,
        ),
        difficulty: LaundryDifficulty.normal,
      );

      expect(alerts.any((alert) => alert.type == LaundryAlertType.rainWarning), isTrue);
      expect(alerts.any((alert) => alert.type == LaundryAlertType.humiditySurge), isTrue);
    });
  });
}
