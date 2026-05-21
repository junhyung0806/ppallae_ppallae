import 'dart:convert';

import '../models/laundry_alert.dart';
import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/saved_location.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';
import '../services/notification_service.dart';
import '../services/repositories.dart';
import 'saved_location_storage.dart';

class MockWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather(WeatherRequestContext context) async {
    final signature = (context.latitude ?? 0) + (context.longitude ?? 0);
    final variant = signature.floor().abs() % 3;
    final presets = _profileWeatherPresets[variant];
    return WeatherBundle(
      current: presets.first.weather,
      hourly: presets,
      meta: WeatherFetchMeta.success(
        source: 'mock',
        stage: 'fallback_ready',
        userMessage: 'fallback 데이터로 추천을 표시 중입니다.',
      ),
    );
  }

  static final List<List<HourlyWeatherForecast>> _profileWeatherPresets = [
    [
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 12),
        weather: const WeatherSnapshot(
          temperatureCelsius: 24,
          humidity: 46,
          windSpeedMps: 2.8,
          skyCondition: SkyCondition.sunny,
          rainProbability: 10,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 13),
        weather: const WeatherSnapshot(
          temperatureCelsius: 25,
          humidity: 43,
          windSpeedMps: 3.1,
          skyCondition: SkyCondition.sunny,
          rainProbability: 8,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 16),
        weather: const WeatherSnapshot(
          temperatureCelsius: 23,
          humidity: 54,
          windSpeedMps: 2.1,
          skyCondition: SkyCondition.partlyCloudy,
          rainProbability: 20,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 19),
        weather: const WeatherSnapshot(
          temperatureCelsius: 20,
          humidity: 61,
          windSpeedMps: 1.4,
          skyCondition: SkyCondition.cloudy,
          rainProbability: 35,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 22),
        weather: const WeatherSnapshot(
          temperatureCelsius: 18,
          humidity: 72,
          windSpeedMps: 0.9,
          skyCondition: SkyCondition.cloudy,
          rainProbability: 55,
        ),
      ),
    ],
    [
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 12),
        weather: const WeatherSnapshot(
          temperatureCelsius: 23,
          humidity: 48,
          windSpeedMps: 2.4,
          skyCondition: SkyCondition.partlyCloudy,
          rainProbability: 18,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 13),
        weather: const WeatherSnapshot(
          temperatureCelsius: 24,
          humidity: 45,
          windSpeedMps: 2.7,
          skyCondition: SkyCondition.sunny,
          rainProbability: 12,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 16),
        weather: const WeatherSnapshot(
          temperatureCelsius: 22,
          humidity: 57,
          windSpeedMps: 1.8,
          skyCondition: SkyCondition.partlyCloudy,
          rainProbability: 24,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 19),
        weather: const WeatherSnapshot(
          temperatureCelsius: 19,
          humidity: 66,
          windSpeedMps: 1.0,
          skyCondition: SkyCondition.cloudy,
          rainProbability: 40,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 22),
        weather: const WeatherSnapshot(
          temperatureCelsius: 17,
          humidity: 77,
          windSpeedMps: 0.8,
          skyCondition: SkyCondition.rainy,
          rainProbability: 68,
        ),
      ),
    ],
    [
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 12),
        weather: const WeatherSnapshot(
          temperatureCelsius: 25,
          humidity: 41,
          windSpeedMps: 3.2,
          skyCondition: SkyCondition.sunny,
          rainProbability: 6,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 13),
        weather: const WeatherSnapshot(
          temperatureCelsius: 26,
          humidity: 39,
          windSpeedMps: 3.5,
          skyCondition: SkyCondition.sunny,
          rainProbability: 4,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 16),
        weather: const WeatherSnapshot(
          temperatureCelsius: 24,
          humidity: 49,
          windSpeedMps: 2.6,
          skyCondition: SkyCondition.partlyCloudy,
          rainProbability: 14,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 19),
        weather: const WeatherSnapshot(
          temperatureCelsius: 21,
          humidity: 58,
          windSpeedMps: 1.5,
          skyCondition: SkyCondition.partlyCloudy,
          rainProbability: 28,
        ),
      ),
      HourlyWeatherForecast(
        at: DateTime(2026, 4, 20, 22),
        weather: const WeatherSnapshot(
          temperatureCelsius: 19,
          humidity: 67,
          windSpeedMps: 1.1,
          skyCondition: SkyCondition.cloudy,
          rainProbability: 36,
        ),
      ),
    ],
  ];
}

class InMemoryUserPreferenceRepository implements UserPreferenceRepository {
  UserPreferenceSettings _settings = const UserPreferenceSettings();

  @override
  Future<UserPreferenceSettings> load() async => _settings;

  @override
  Future<void> save(UserPreferenceSettings settings) async {
    _settings = settings;
  }
}

class InMemoryLaundryHistoryRepository implements LaundryHistoryRepository {
  final List<LaundryHistoryEntry> _history = [
    LaundryHistoryEntry(
      startedAt: DateTime(2026, 4, 18, 21),
      difficulty: LaundryDifficulty.normal,
      decision: RecommendationDecision.accepted,
      indoorDrying: false,
    ),
    LaundryHistoryEntry(
      startedAt: DateTime(2026, 4, 19, 22),
      difficulty: LaundryDifficulty.heavy,
      decision: RecommendationDecision.manualStart,
      indoorDrying: true,
    ),
    LaundryHistoryEntry(
      startedAt: DateTime(2026, 4, 17, 13),
      difficulty: LaundryDifficulty.light,
      decision: RecommendationDecision.accepted,
      indoorDrying: false,
    ),
  ];

  @override
  Future<void> append(LaundryHistoryEntry entry) async {
    _history.add(entry);
  }

  @override
  Future<List<LaundryHistoryEntry>> load() async => List.unmodifiable(_history);
}

class InMemorySavedLocationRepository implements SavedLocationRepository {
  InMemorySavedLocationRepository({
    SavedLocationStorage? storage,
  }) : _storage = storage ?? SavedLocationStorage();

  static const _storageKey = 'ppallae_saved_locations_v1';

  final SavedLocationStorage _storage;

  @override
  Future<List<SavedLocation>> load() async {
    final raw = await _storage.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      final seeded = _seedLocations;
      await _write(seeded);
      return List.unmodifiable(seeded);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List.unmodifiable(
          decoded
              .whereType<Map>()
              .map((item) => SavedLocation.fromJson(
                    item.map((key, value) => MapEntry('$key', value)),
                  ))
              .toList(),
        );
      }
    } catch (_) {}

    final seeded = _seedLocations;
    await _write(seeded);
    return List.unmodifiable(seeded);
  }

  @override
  Future<List<SavedLocation>> upsert(SavedLocation location) async {
    final current = [...await load()];
    final index = current.indexWhere((item) => item.id == location.id);
    final next = location.copyWith(updatedAt: DateTime.now());
    if (index >= 0) {
      current[index] = next;
    } else {
      current.add(next);
    }
    await _write(current);
    return List.unmodifiable(current);
  }

  @override
  Future<List<SavedLocation>> delete(String id) async {
    final current = [...await load()]..removeWhere((item) => item.id == id);
    await _write(current);
    return List.unmodifiable(current);
  }

  Future<void> _write(List<SavedLocation> locations) async {
    await _storage.write(
      _storageKey,
      jsonEncode(locations.map((e) => e.toJson()).toList()),
    );
  }

  List<SavedLocation> get _seedLocations => [
        SavedLocation.create(
          label: '우리 집',
          latitude: 37.5447,
          longitude: 127.0557,
          address: '서울시 성동구 성수동',
          isPinned: true,
        ),
        SavedLocation.create(
          label: '회사',
          latitude: 37.5665,
          longitude: 126.9780,
          address: '서울시 중구 을지로',
        ),
      ];
}

class DebugNotificationService implements NotificationService {
  List<String> lastSyncedAlertIds = const [];

  @override
  Future<void> cancelAllLaundryAlerts() async {
    lastSyncedAlertIds = const [];
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncAlerts(List<PlannedLaundryAlert> alerts) async {
    lastSyncedAlertIds = alerts.map((alert) => alert.id).toList();
  }
}
