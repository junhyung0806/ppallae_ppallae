import '../../map/models/laundromat.dart';
import '../../home/models/recent_location_search.dart';
import '../models/laundry_alert.dart';
import '../models/current_location_summary.dart';
import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/recommendation_result.dart';
import '../models/saved_location.dart';
import '../models/user_preference_settings.dart';
import '../models/weather_snapshot.dart';
import '../services/repositories.dart';

class LaundryDashboardState {
  const LaundryDashboardState({
    required this.isLoading,
    required this.selectedLocationId,
    required this.selectedDifficulty,
    required this.savedLocations,
    required this.recentSearches,
    required this.searchedLocation,
    required this.currentLocation,
    required this.preferences,
    required this.history,
    required this.patternSummary,
    required this.currentWeather,
    required this.hourlyForecasts,
    required this.recommendation,
    required this.alerts,
    required this.selectedLaundromat,
    required this.weatherMeta,
  });

  factory LaundryDashboardState.initial() {
    return LaundryDashboardState(
      isLoading: false,
      selectedLocationId: 'current',
      selectedDifficulty: LaundryDifficulty.normal,
      savedLocations: const [],
      recentSearches: const [],
      searchedLocation: null,
      currentLocation: const CurrentLocationSummary(
        displayText: '현재 위치 확인 중...',
      ),
      preferences: const UserPreferenceSettings(),
      history: const [],
      patternSummary: const LaundryPatternSummary(
        preferredStartHours: <int>{},
        nightLaundryAffinity: 0,
        extraHeavyUsageRatio: 0,
        recommendationAcceptanceRate: 0.5,
      ),
      currentWeather: null,
      hourlyForecasts: const [],
      recommendation: null,
      alerts: const [],
      selectedLaundromat: null,
      weatherMeta: const WeatherFetchMeta(
        source: 'uninitialized',
        stage: 'idle',
        userMessage: '날씨 연동을 초기화하는 중입니다.',
      ),
    );
  }

  final bool isLoading;
  final String selectedLocationId;
  final LaundryDifficulty selectedDifficulty;
  final List<SavedLocation> savedLocations;
  final List<RecentLocationSearch> recentSearches;
  final LocationSelection? searchedLocation;
  final CurrentLocationSummary currentLocation;
  final UserPreferenceSettings preferences;
  final List<LaundryHistoryEntry> history;
  final LaundryPatternSummary patternSummary;
  final WeatherSnapshot? currentWeather;
  final List<HourlyWeatherForecast> hourlyForecasts;
  final RecommendationResult? recommendation;
  final List<PlannedLaundryAlert> alerts;
  final SelectedLaundromat? selectedLaundromat;
  final WeatherFetchMeta weatherMeta;

  LaundryDashboardState copyWith({
    bool? isLoading,
    String? selectedLocationId,
    LaundryDifficulty? selectedDifficulty,
    List<SavedLocation>? savedLocations,
    List<RecentLocationSearch>? recentSearches,
    LocationSelection? searchedLocation,
    CurrentLocationSummary? currentLocation,
    UserPreferenceSettings? preferences,
    List<LaundryHistoryEntry>? history,
    LaundryPatternSummary? patternSummary,
    WeatherSnapshot? currentWeather,
    List<HourlyWeatherForecast>? hourlyForecasts,
    RecommendationResult? recommendation,
    List<PlannedLaundryAlert>? alerts,
    SelectedLaundromat? selectedLaundromat,
    WeatherFetchMeta? weatherMeta,
    bool clearSelectedLaundromat = false,
  }) {
    return LaundryDashboardState(
      isLoading: isLoading ?? this.isLoading,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      savedLocations: savedLocations ?? this.savedLocations,
      recentSearches: recentSearches ?? this.recentSearches,
      searchedLocation: searchedLocation ?? this.searchedLocation,
      currentLocation: currentLocation ?? this.currentLocation,
      preferences: preferences ?? this.preferences,
      history: history ?? this.history,
      patternSummary: patternSummary ?? this.patternSummary,
      currentWeather: currentWeather ?? this.currentWeather,
      hourlyForecasts: hourlyForecasts ?? this.hourlyForecasts,
      recommendation: recommendation ?? this.recommendation,
      alerts: alerts ?? this.alerts,
      weatherMeta: weatherMeta ?? this.weatherMeta,
      selectedLaundromat: clearSelectedLaundromat
          ? null
          : (selectedLaundromat ?? this.selectedLaundromat),
    );
  }
}
