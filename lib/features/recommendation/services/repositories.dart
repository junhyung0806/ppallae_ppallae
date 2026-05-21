import '../models/laundry_history.dart';
import '../models/saved_location.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';

class WeatherBundle {
  const WeatherBundle({
    required this.current,
    required this.hourly,
    required this.meta,
  });

  final WeatherSnapshot current;
  final List<HourlyWeatherForecast> hourly;
  final WeatherFetchMeta meta;
}

class WeatherFetchMeta {
  const WeatherFetchMeta({
    required this.source,
    required this.stage,
    required this.userMessage,
    this.errorCode,
    this.debugMessage,
    this.usedFallback = false,
    this.details = const <String, String>{},
  });

  factory WeatherFetchMeta.success({
    required String source,
    required String stage,
    required String userMessage,
    Map<String, String> details = const <String, String>{},
  }) {
    return WeatherFetchMeta(
      source: source,
      stage: stage,
      userMessage: userMessage,
      details: details,
    );
  }

  final String source;
  final String stage;
  final String userMessage;
  final String? errorCode;
  final String? debugMessage;
  final bool usedFallback;
  final Map<String, String> details;
}

class WeatherRequestContext {
  const WeatherRequestContext({
    required this.selectionId,
    required this.sourceType,
    required this.selectionLabel,
    this.latitude,
    this.longitude,
  });

  final String selectionId;
  final LocationSourceType sourceType;
  final String selectionLabel;
  final double? latitude;
  final double? longitude;

  String get cacheKey {
    final lat = latitude?.toStringAsFixed(5) ?? 'null';
    final lon = longitude?.toStringAsFixed(5) ?? 'null';
    return '${sourceType.name}:$selectionId:$lat:$lon';
  }
}

abstract class WeatherRepository {
  Future<WeatherBundle> fetchWeather(WeatherRequestContext context);
}

class WeatherRepositoryException implements Exception {
  const WeatherRepositoryException({
    required this.code,
    required this.stage,
    required this.message,
    this.debugMessage,
    this.details = const <String, String>{},
  });

  final String code;
  final String stage;
  final String message;
  final String? debugMessage;
  final Map<String, String> details;

  WeatherRepositoryException withMergedDetails(Map<String, String> nextDetails) {
    return WeatherRepositoryException(
      code: code,
      stage: stage,
      message: message,
      debugMessage: debugMessage,
      details: {
        ...nextDetails,
        ...details,
      },
    );
  }
}

abstract class UserPreferenceRepository {
  Future<UserPreferenceSettings> load();
  Future<void> save(UserPreferenceSettings settings);
}

abstract class LaundryHistoryRepository {
  Future<List<LaundryHistoryEntry>> load();
  Future<void> append(LaundryHistoryEntry entry);
}

abstract class SavedLocationRepository {
  Future<List<SavedLocation>> load();
  Future<List<SavedLocation>> upsert(SavedLocation location);
  Future<List<SavedLocation>> delete(String id);
}
