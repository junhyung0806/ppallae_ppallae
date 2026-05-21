import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/features/recommendation/models/laundry_difficulty.dart';
import 'package:ppallae_ppallae/features/recommendation/models/recommendation_status.dart';
import 'package:ppallae_ppallae/features/recommendation/models/weather_snapshot.dart';
import 'package:ppallae_ppallae/features/recommendation/services/drying_time_calculator.dart';

void main() {
  group('DryingTimeCalculator', () {
    const calculator = DryingTimeCalculator();

    test('가벼운 빨래는 좋은 날씨에서 빠르게 마른다', () {
      final estimate = calculator.calculate(
        weather: WeatherSnapshot(
          temperatureCelsius: 24,
          humidity: 42,
          windSpeedMps: 3.5,
          skyCondition: SkyCondition.sunny,
          rainProbability: 10,
        ),
        difficulty: LaundryDifficulty.light,
        indoorDrying: false,
      );

      expect(estimate.estimatedMinutes, lessThan(150));
      expect(estimate.status, RecommendationStatus.good);
    });

    test('초두꺼움 빨래는 불리한 날씨에서 8시간 이상으로 계산된다', () {
      final estimate = calculator.calculate(
        weather: WeatherSnapshot(
          temperatureCelsius: 18,
          humidity: 78,
          windSpeedMps: 0.8,
          skyCondition: SkyCondition.cloudy,
          rainProbability: 55,
        ),
        difficulty: LaundryDifficulty.extraHeavy,
        indoorDrying: false,
      );

      expect(estimate.exceedsEightHours, isTrue);
      expect(estimate.displayText, '8시간 이상');
      expect(estimate.status, RecommendationStatus.bad);
    });
  });
}
