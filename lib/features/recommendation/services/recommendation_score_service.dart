import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/recommendation_result.dart';
import '../models/recommendation_status.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';

class RecommendationScoreInput {
  const RecommendationScoreInput({
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

class RecommendationScoreService {
  const RecommendationScoreService();

  RecommendationScoreBreakdown calculate(RecommendationScoreInput input) {
    final weights = _weights(input.preferences);
    final components = <ScoreComponent>[
      ScoreComponent(
        key: 'humidity',
        label: '습도',
        rawScore: _humidityScore(input.weather.humidity),
        weight: weights['humidity']!,
      ),
      ScoreComponent(
        key: 'rain',
        label: '강수 확률',
        rawScore: _rainScore(input.weather.rainProbability),
        weight: weights['rain']!,
      ),
      ScoreComponent(
        key: 'wind',
        label: '바람',
        rawScore: _windScore(
          input.weather.windSpeedMps,
          input.preferences.useIndoorDryingMode,
        ),
        weight: weights['wind']!,
      ),
      ScoreComponent(
        key: 'temperature',
        label: '기온',
        rawScore: _temperatureScore(input.weather.temperatureCelsius),
        weight: weights['temperature']!,
      ),
      ScoreComponent(
        key: 'sun',
        label: '일조',
        rawScore: _sunScore(input.weather.skyCondition),
        weight: weights['sun']!,
      ),
    ];

    final weightedScore = components.fold<double>(
      0,
      (sum, component) => sum + (component.rawScore * component.weight),
    );

    final adjustments = <ScoreAdjustment>[
      ScoreAdjustment(
        label: '${input.difficulty.label} 난이도 반영',
        delta: -_difficultyPenalty(input.difficulty),
      ),
    ];

    final hourAffinity = input.patternSummary.hourAffinityFor(input.startTime);
    if (hourAffinity != 0) {
      adjustments.add(
        ScoreAdjustment(
          label: '사용자 시작 시간 패턴 반영',
          delta: hourAffinity * 8,
        ),
      );
    }

    if (input.difficulty == LaundryDifficulty.extraHeavy &&
        input.patternSummary.extraHeavyUsageRatio > 0.25) {
      adjustments.add(
        ScoreAdjustment(
          label: '초두꺼움 빨래 사용 패턴 보정',
          delta: -(input.patternSummary.extraHeavyUsageRatio * 12),
        ),
      );
    }

    if (input.patternSummary.recommendationAcceptanceRate < 0.35) {
      adjustments.add(
        const ScoreAdjustment(
          label: '추천 무시 패턴 보정',
          delta: -4,
        ),
      );
    }

    final finalScore = _clampInt(
      (weightedScore +
              adjustments.fold<double>(
                0,
                (sum, adjustment) => sum + adjustment.delta,
              ))
          .round(),
      0,
      100,
    );

    return RecommendationScoreBreakdown(
      components: components,
      adjustments: adjustments,
      finalScore: finalScore,
      status: _statusForScore(finalScore),
    );
  }

  Map<String, double> _weights(UserPreferenceSettings preferences) {
    final weights = <String, double>{
      'humidity': 0.26,
      'rain': 0.26,
      'wind': 0.16,
      'temperature': 0.14,
      'sun': 0.18,
    };

    if (preferences.prioritizeFastDrying) {
      weights['humidity'] = weights['humidity']! + 0.06;
      weights['wind'] = weights['wind']! + 0.05;
      weights['sun'] = weights['sun']! + 0.06;
      weights['rain'] = weights['rain']! - 0.07;
      weights['temperature'] = weights['temperature']! - 0.04;
    }

    if (preferences.avoidRainExposure) {
      weights['rain'] = weights['rain']! + 0.12;
      weights['wind'] = weights['wind']! - 0.04;
      weights['temperature'] = weights['temperature']! - 0.04;
      weights['sun'] = weights['sun']! - 0.04;
    }

    if (preferences.useIndoorDryingMode) {
      weights['humidity'] = weights['humidity']! + 0.08;
      weights['temperature'] = weights['temperature']! + 0.05;
      weights['wind'] = weights['wind']! - 0.07;
      weights['sun'] = weights['sun']! - 0.06;
    }

    final total = weights.values.fold<double>(0, (sum, value) => sum + value);
    return {
      for (final entry in weights.entries) entry.key: entry.value / total,
    };
  }

  double _humidityScore(int humidity) {
    return _clampDouble(
      100 - ((humidity - 45).abs() * 1.7) - ((humidity > 70 ? humidity - 70 : 0) * 1.0),
      0,
      100,
    );
  }

  double _rainScore(int rainProbability) {
    return _clampDouble(100 - (rainProbability * 1.1), 0, 100);
  }

  double _windScore(double windSpeed, bool indoorMode) {
    if (indoorMode) {
      return _clampDouble(100 - ((windSpeed - 1.0).abs() * 18), 45, 100);
    }

    return _clampDouble(100 - ((windSpeed - 3.2).abs() * 15), 25, 100);
  }

  double _temperatureScore(double temperature) {
    return _clampDouble(100 - ((temperature - 23).abs() * 4.8), 20, 100);
  }

  double _sunScore(SkyCondition condition) {
    switch (condition) {
      case SkyCondition.sunny:
        return 100;
      case SkyCondition.partlyCloudy:
        return 78;
      case SkyCondition.cloudy:
        return 58;
      case SkyCondition.rainy:
        return 20;
    }
  }

  double _difficultyPenalty(LaundryDifficulty difficulty) {
    switch (difficulty) {
      case LaundryDifficulty.light:
        return 0;
      case LaundryDifficulty.normal:
        return 4;
      case LaundryDifficulty.heavy:
        return 10;
      case LaundryDifficulty.extraHeavy:
        return 18;
    }
  }

  RecommendationStatus _statusForScore(int score) {
    if (score >= 75) {
      return RecommendationStatus.good;
    }

    if (score >= 45) {
      return RecommendationStatus.normal;
    }

    return RecommendationStatus.bad;
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) {
      return min;
    }

    if (value > max) {
      return max;
    }

    return value;
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
