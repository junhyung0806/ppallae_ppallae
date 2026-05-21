enum SkyCondition {
  sunny(label: '맑음', sunExposureScore: 1.0),
  partlyCloudy(label: '구름 조금', sunExposureScore: 0.8),
  cloudy(label: '흐림', sunExposureScore: 0.55),
  rainy(label: '비', sunExposureScore: 0.2);

  const SkyCondition({
    required this.label,
    required this.sunExposureScore,
  });

  final String label;
  final double sunExposureScore;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureCelsius,
    required this.humidity,
    required this.windSpeedMps,
    required this.skyCondition,
    required this.rainProbability,
  });

  final double temperatureCelsius;
  final int humidity;
  final double windSpeedMps;
  final SkyCondition skyCondition;
  final int rainProbability;
}

class HourlyWeatherForecast {
  const HourlyWeatherForecast({
    required this.at,
    required this.weather,
  });

  final DateTime at;
  final WeatherSnapshot weather;
}
