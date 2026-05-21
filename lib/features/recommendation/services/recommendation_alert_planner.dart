import '../models/laundry_alert.dart';
import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';
import 'recommendation_engine.dart';

class RecommendationAlertPlanner {
  const RecommendationAlertPlanner({
    this.engine = const RecommendationEngine(),
  });

  final RecommendationEngine engine;

  List<PlannedLaundryAlert> plan({
    required DateTime now,
    required List<HourlyWeatherForecast> forecasts,
    required UserPreferenceSettings preferences,
    required LaundryPatternSummary patternSummary,
    required LaundryDifficulty difficulty,
  }) {
    if (!preferences.notificationsEnabled || forecasts.isEmpty) {
      return const [];
    }

    final alerts = <PlannedLaundryAlert>[
      ..._planBestTimeAlert(
        now: now,
        forecasts: forecasts,
        preferences: preferences,
        patternSummary: patternSummary,
        difficulty: difficulty,
      ),
      ..._planRainAlerts(now: now, forecasts: forecasts, preferences: preferences),
      ..._planHumidityAlerts(now: now, forecasts: forecasts),
    ];

    alerts.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return alerts;
  }

  List<PlannedLaundryAlert> _planBestTimeAlert({
    required DateTime now,
    required List<HourlyWeatherForecast> forecasts,
    required UserPreferenceSettings preferences,
    required LaundryPatternSummary patternSummary,
    required LaundryDifficulty difficulty,
  }) {
    if (!preferences.bestTimeAlertsEnabled) {
      return const [];
    }

    HourlyWeatherForecast? bestForecast;
    var bestScore = -1;

    for (final forecast in forecasts.take(24)) {
      if (!forecast.at.isAfter(now)) {
        continue;
      }

      final result = engine.evaluate(
        RecommendationEngineInput(
          weather: forecast.weather,
          preferences: preferences,
          patternSummary: patternSummary,
          difficulty: difficulty,
          startTime: forecast.at,
        ),
      );

      if (result.score > bestScore) {
        bestScore = result.score;
        bestForecast = forecast;
      }
    }

    if (bestForecast == null || bestScore < 70) {
      return const [];
    }

    final minutesUntil = bestForecast.at.difference(now).inMinutes;
    final title = minutesUntil <= 30 ? '곧 빨래 추천 시간이에요' : '오늘 빨래 추천 시간 안내';
    final body = minutesUntil <= 30
        ? '30분 후 빨래하기 좋은 시간입니다.'
        : '오늘 ${bestForecast.at.hour}시에 빨래 추천 상태가 가장 좋아요.';

    final scheduleTime = minutesUntil <= 30 ? now : bestForecast.at.subtract(const Duration(minutes: 30));

    return [
      PlannedLaundryAlert(
        id: 'best-time-${bestForecast.at.toIso8601String()}',
        type: LaundryAlertType.bestTime,
        title: title,
        body: body,
        scheduledAt: scheduleTime,
        payload: {
          'type': 'best_time',
          'recommendedAt': bestForecast.at.toIso8601String(),
        },
      ),
    ];
  }

  List<PlannedLaundryAlert> _planRainAlerts({
    required DateTime now,
    required List<HourlyWeatherForecast> forecasts,
    required UserPreferenceSettings preferences,
  }) {
    if (!preferences.rainAlertsEnabled) {
      return const [];
    }

    HourlyWeatherForecast? rainStart;
    for (final forecast in forecasts.take(24)) {
      if (forecast.weather.rainProbability >= 60 && forecast.at.isAfter(now)) {
        rainStart = forecast;
        break;
      }
    }

    if (rainStart == null) {
      return const [];
    }

    final alerts = <PlannedLaundryAlert>[];
    for (final leadHours in [2, 1]) {
      final scheduledAt = rainStart.at.subtract(Duration(hours: leadHours));
      if (!scheduledAt.isAfter(now)) {
        continue;
      }

      alerts.add(
        PlannedLaundryAlert(
          id: 'rain-${leadHours}h-${rainStart.at.toIso8601String()}',
          type: LaundryAlertType.rainWarning,
          title: '비 예보 경고',
          body: '⚠️ ${leadHours}시간 후 비 예보 → 빨래를 걷으세요',
          scheduledAt: scheduledAt,
          payload: {
            'type': 'rain_warning',
            'rainAt': rainStart.at.toIso8601String(),
          },
        ),
      );
    }

    return alerts;
  }

  List<PlannedLaundryAlert> _planHumidityAlerts({
    required DateTime now,
    required List<HourlyWeatherForecast> forecasts,
  }) {
    if (forecasts.length < 2) {
      return const [];
    }

    final currentHumidity = forecasts.first.weather.humidity;
    for (final forecast in forecasts.skip(1).take(2)) {
      final delta = forecast.weather.humidity - currentHumidity;
      if (delta >= 15 && forecast.at.isAfter(now)) {
        final scheduledAt = now.add(const Duration(minutes: 10));
        return [
          PlannedLaundryAlert(
            id: 'humidity-${forecast.at.toIso8601String()}',
            type: LaundryAlertType.humiditySurge,
            title: '습도 급상승 예상',
            body: '습도 급상승 예상 → 건조 속도가 느려질 수 있어요',
            scheduledAt: scheduledAt,
            payload: {
              'type': 'humidity_surge',
              'surgeAt': forecast.at.toIso8601String(),
            },
          ),
        ];
      }
    }

    return const [];
  }
}
