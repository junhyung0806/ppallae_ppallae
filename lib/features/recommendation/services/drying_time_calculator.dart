import '../models/drying_time_estimate.dart';
import '../models/laundry_difficulty.dart';
import '../models/recommendation_status.dart';
import '../models/weather_snapshot.dart';

class DryingTimeCalculator {
  const DryingTimeCalculator();

  DryingTimeEstimate calculate({
    required WeatherSnapshot weather,
    required LaundryDifficulty difficulty,
    required bool indoorDrying,
  }) {
    final baseMinutes = difficulty.baseDryingMinutes.toDouble();
    final temperatureFactor = _temperatureFactor(weather.temperatureCelsius);
    final humidityFactor = _humidityFactor(weather.humidity, indoorDrying);
    final windFactor = _windFactor(weather.windSpeedMps, indoorDrying);
    final skyFactor = _skyFactor(weather.skyCondition, indoorDrying);
    final rainFactor = _rainFactor(weather.rainProbability, indoorDrying);
    final indoorFactor = indoorDrying ? 1.15 : 1.0;

    final factors = [
      DryingFactorDetail(
        label: '기온',
        factor: temperatureFactor,
        reason: weather.temperatureCelsius >= 22
            ? '온도가 적당해 건조 시간이 조금 짧아져요.'
            : '기온이 낮아 건조 속도가 다소 느려져요.',
      ),
      DryingFactorDetail(
        label: '습도',
        factor: humidityFactor,
        reason: weather.humidity <= 55
            ? '습도가 낮아 수분이 비교적 잘 빠져요.'
            : '습도가 높아 마르는 속도가 늦어져요.',
      ),
      DryingFactorDetail(
        label: '바람',
        factor: windFactor,
        reason: indoorDrying
            ? '실내 건조라 바람 영향은 줄이고 계산했어요.'
            : weather.windSpeedMps >= 2
                ? '바람이 있어 표면 수분이 빨리 날아가요.'
                : '바람이 약해 건조 효율이 크게 오르지 않아요.',
      ),
      DryingFactorDetail(
        label: '하늘 상태',
        factor: skyFactor,
        reason: indoorDrying
            ? '실내 건조 모드에서는 일조 가중치를 낮췄어요.'
            : '${weather.skyCondition.label} 기준으로 일조량을 반영했어요.',
      ),
      DryingFactorDetail(
        label: '강수 확률',
        factor: rainFactor,
        reason: weather.rainProbability >= 50
            ? '비 가능성이 있어 보수적으로 계산했어요.'
            : '강수 위험이 낮아 추가 패널티가 크지 않아요.',
      ),
      if (indoorDrying)
        const DryingFactorDetail(
          label: '실내 건조',
          factor: 1.15,
          reason: '직사광선과 자연 바람이 적어 기본 시간을 늘렸어요.',
        ),
    ];

    final estimatedMinutes = (baseMinutes *
            temperatureFactor *
            humidityFactor *
            windFactor *
            skyFactor *
            rainFactor *
            indoorFactor)
        .round();

    final exceedsEightHours = estimatedMinutes >= 480;
    final status = _buildStatus(
      estimatedMinutes: estimatedMinutes,
      rainProbability: weather.rainProbability,
      difficulty: difficulty,
      indoorDrying: indoorDrying,
    );

    final recommended = status != RecommendationStatus.bad;
    final displayText = exceedsEightHours
        ? '8시간 이상'
        : _formatMinutes(estimatedMinutes);
    final explanation =
        '${difficulty.buildUserHint(recommended: recommended, exceedsEightHours: exceedsEightHours)} '
        '예상 건조 시간은 $displayText로 계산됐어요.';

    return DryingTimeEstimate(
      estimatedMinutes: estimatedMinutes,
      displayText: displayText,
      exceedsEightHours: exceedsEightHours,
      status: status,
      explanation: explanation,
      factors: factors,
    );
  }

  double _temperatureFactor(double temperature) {
    return _clampDouble(1.18 - ((temperature - 22) * 0.018), 0.78, 1.26);
  }

  double _humidityFactor(int humidity, bool indoorDrying) {
    final base = indoorDrying ? 0.92 : 0.85;
    final multiplier = indoorDrying ? 0.010 : 0.008;
    return _clampDouble(base + (humidity * multiplier), 0.90, 1.55);
  }

  double _windFactor(double windSpeed, bool indoorDrying) {
    if (indoorDrying) {
      return _clampDouble(1.02 - (windSpeed * 0.015), 0.95, 1.02);
    }

    return _clampDouble(1.04 - (windSpeed * 0.06), 0.72, 1.04);
  }

  double _skyFactor(SkyCondition condition, bool indoorDrying) {
    if (indoorDrying) {
      return _clampDouble(1.05 - (condition.sunExposureScore * 0.08), 0.96, 1.03);
    }

    switch (condition) {
      case SkyCondition.sunny:
        return 0.84;
      case SkyCondition.partlyCloudy:
        return 0.94;
      case SkyCondition.cloudy:
        return 1.08;
      case SkyCondition.rainy:
        return 1.24;
    }
  }

  double _rainFactor(int rainProbability, bool indoorDrying) {
    final weight = indoorDrying ? 0.0015 : 0.0032;
    return _clampDouble(1 + (rainProbability * weight), 1.0, 1.34);
  }

  RecommendationStatus _buildStatus({
    required int estimatedMinutes,
    required int rainProbability,
    required LaundryDifficulty difficulty,
    required bool indoorDrying,
  }) {
    if (!indoorDrying && rainProbability >= 65) {
      return RecommendationStatus.bad;
    }

    if (difficulty == LaundryDifficulty.extraHeavy && estimatedMinutes >= 480) {
      return RecommendationStatus.bad;
    }

    if (estimatedMinutes <= 220) {
      return RecommendationStatus.good;
    }

    if (estimatedMinutes <= 420) {
      return RecommendationStatus.normal;
    }

    return RecommendationStatus.bad;
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '${minutes}분';
    }

    if (minutes == 0) {
      return '${hours}시간';
    }

    return '${hours}시간 ${minutes}분';
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
}
