import 'package:flutter/foundation.dart';

import '../../map/models/laundromat.dart';
import '../../home/data/recent_location_search_repository.dart';
import '../../home/data/location_result.dart';
import '../../home/data/location_service.dart';
import '../../home/models/recent_location_search.dart';
import '../models/current_location_summary.dart';
import '../models/laundry_difficulty.dart';
import '../models/laundry_history.dart';
import '../models/saved_location.dart';
import '../models/user_preference_settings.dart';
import '../services/laundry_pattern_analyzer.dart';
import '../services/notification_service.dart';
import '../services/recommendation_alert_planner.dart';
import '../services/recommendation_engine.dart';
import '../services/repositories.dart';
import 'laundry_dashboard_state.dart';

class LaundryDashboardController extends ChangeNotifier {
  LaundryDashboardController({
    required WeatherRepository weatherRepository,
    required UserPreferenceRepository preferenceRepository,
    required LaundryHistoryRepository historyRepository,
    required SavedLocationRepository savedLocationRepository,
    required NotificationService notificationService,
    RecentLocationSearchRepository? recentLocationSearchRepository,
    LocationService? locationService,
    this.patternAnalyzer = const LaundryPatternAnalyzer(),
    this.recommendationEngine = const RecommendationEngine(),
    this.alertPlanner = const RecommendationAlertPlanner(),
  })  : _weatherRepository = weatherRepository,
        _preferenceRepository = preferenceRepository,
        _historyRepository = historyRepository,
        _savedLocationRepository = savedLocationRepository,
        _notificationService = notificationService,
        _recentLocationSearchRepository =
            recentLocationSearchRepository ?? RecentLocationSearchRepository(),
        _locationService = locationService ?? LocationService();

  final WeatherRepository _weatherRepository;
  final UserPreferenceRepository _preferenceRepository;
  final LaundryHistoryRepository _historyRepository;
  final SavedLocationRepository _savedLocationRepository;
  final NotificationService _notificationService;
  final RecentLocationSearchRepository _recentLocationSearchRepository;
  final LocationService _locationService;
  final LaundryPatternAnalyzer patternAnalyzer;
  final RecommendationEngine recommendationEngine;
  final RecommendationAlertPlanner alertPlanner;

  LaundryDashboardState _state = LaundryDashboardState.initial();
  LaundryDashboardState get state => _state;

  Future<void> initialize() async {
    _updateState(_state.copyWith(isLoading: true));

    final preferences = await _preferenceRepository.load();
    final history = await _historyRepository.load();
    final savedLocations = await _savedLocationRepository.load();
    final recentSearches = await _recentLocationSearchRepository.load();
    final currentLocation = await _loadCurrentLocationSummary();
    final patternSummary = patternAnalyzer.summarize(history);

    _updateState(
      _state.copyWith(
        isLoading: false,
        savedLocations: savedLocations,
        recentSearches: recentSearches,
        currentLocation: currentLocation,
        preferences: preferences,
        history: history,
        patternSummary: patternSummary,
      ),
    );

    await refresh();
  }

  Future<void> refresh() async {
    _updateState(_state.copyWith(isLoading: true));

    final weatherBundle = await _weatherRepository.fetchWeather(
      _weatherRequestContext(),
    );
    final recommendation = recommendationEngine.evaluate(
      RecommendationEngineInput(
        weather: weatherBundle.current,
        preferences: _state.preferences,
        patternSummary: _state.patternSummary,
        difficulty: _state.selectedDifficulty,
        startTime: DateTime.now(),
      ),
    );

    final alerts = alertPlanner.plan(
      now: DateTime.now(),
      forecasts: weatherBundle.hourly,
      preferences: _state.preferences,
      patternSummary: _state.patternSummary,
      difficulty: _state.selectedDifficulty,
    );

    await _notificationService.syncAlerts(alerts);

    _updateState(
      _state.copyWith(
        isLoading: false,
        currentWeather: weatherBundle.current,
        hourlyForecasts: weatherBundle.hourly,
        recommendation: recommendation,
        alerts: alerts,
        weatherMeta: weatherBundle.meta,
      ),
    );
  }

  Future<void> updatePreferences(UserPreferenceSettings settings) async {
    await _preferenceRepository.save(settings);
    _updateState(_state.copyWith(preferences: settings));
    await refresh();
  }

  Future<void> changeDifficulty(LaundryDifficulty difficulty) async {
    _updateState(_state.copyWith(selectedDifficulty: difficulty));
    await refresh();
  }

  Future<void> refreshCurrentLocation() async {
    final currentLocation = await _loadCurrentLocationSummary();
    _updateState(_state.copyWith(currentLocation: currentLocation));
    if (_state.selectedLocationId == 'current') {
      await refresh();
    }
  }

  Future<void> selectCurrentLocation() async {
    _updateState(
      _state.copyWith(
        selectedLocationId: 'current',
        clearSelectedLaundromat: true,
      ),
    );
    await refresh();
  }

  Future<void> selectSavedLocation(String id) async {
    _updateState(
      _state.copyWith(
        selectedLocationId: id,
        clearSelectedLaundromat: true,
      ),
    );
    await refresh();
  }

  Future<void> selectSearchLocation(LocationSelection selection) async {
    _updateState(
      _state.copyWith(
        searchedLocation: selection,
        selectedLocationId: selection.id,
        clearSelectedLaundromat: true,
      ),
    );
    await refresh();
  }

  Future<void> applySearchSelection(
    LocationSelection selection, {
    required String query,
  }) async {
    final recentSearches = await _recentLocationSearchRepository.add(
      RecentLocationSearch.fromSelection(selection, query: query),
    );
    _updateState(_state.copyWith(recentSearches: recentSearches));
    await selectSearchLocation(selection);
  }

  Future<void> selectRecentSearch(RecentLocationSearch recentSearch) async {
    await selectSearchLocation(recentSearch.toLocationSelection());
  }

  Future<void> deleteRecentSearch(String id) async {
    final recentSearches = await _recentLocationSearchRepository.delete(id);
    _updateState(_state.copyWith(recentSearches: recentSearches));
  }

  Future<void> clearRecentSearches() async {
    final recentSearches = await _recentLocationSearchRepository.clear();
    _updateState(_state.copyWith(recentSearches: recentSearches));
  }

  Future<void> saveLocation(SavedLocation location) async {
    final savedLocations = await _savedLocationRepository.upsert(location);
    _updateState(_state.copyWith(savedLocations: savedLocations));
  }

  Future<void> deleteLocation(String id) async {
    final savedLocations = await _savedLocationRepository.delete(id);
    final nextSelected = _state.selectedLocationId == id ? 'current' : _state.selectedLocationId;
    _updateState(
      _state.copyWith(
        savedLocations: savedLocations,
        selectedLocationId: nextSelected,
      ),
    );
    if (nextSelected == 'current') {
      await refresh();
    }
  }

  Future<void> recordLaundryStart(LaundryHistoryEntry entry) async {
    await _historyRepository.append(entry);
    final history = [..._state.history, entry];
    final patternSummary = patternAnalyzer.summarize(history);
    _updateState(_state.copyWith(history: history, patternSummary: patternSummary));
    await refresh();
  }

  void selectLaundromat(SelectedLaundromat? laundromat) {
    _updateState(_state.copyWith(selectedLaundromat: laundromat));
  }

  void _updateState(LaundryDashboardState next) {
    _state = next;
    notifyListeners();
  }

  Future<CurrentLocationSummary> _loadCurrentLocationSummary() async {
    final result = await _locationService.fetchCurrentLocation();
    return _toCurrentLocationSummary(result);
  }

  CurrentLocationSummary _toCurrentLocationSummary(LocationResult result) {
    return CurrentLocationSummary(
      displayText: result.displayText,
      latitude: result.latitude,
      longitude: result.longitude,
      errorCode: result.errorCode,
    );
  }

  WeatherRequestContext _weatherRequestContext() {
    final activeLocation = resolveSelectedLocation();
    if (activeLocation == null) {
      return WeatherRequestContext(
        selectionId: 'current',
        sourceType: LocationSourceType.current,
        selectionLabel: '현재 위치',
        latitude: _state.currentLocation.latitude,
        longitude: _state.currentLocation.longitude,
      );
    }

    return WeatherRequestContext(
      selectionId: activeLocation.id,
      sourceType: activeLocation.sourceType,
      selectionLabel: activeLocation.label,
      latitude: activeLocation.latitude,
      longitude: activeLocation.longitude,
    );
  }

  LocationSelection? resolveSelectedLocation() {
    if (_state.selectedLocationId == 'current') {
      return LocationSelection.current(_state.currentLocation);
    }

    if (_state.searchedLocation != null &&
        _state.searchedLocation!.id == _state.selectedLocationId) {
      return _state.searchedLocation;
    }

    for (final saved in _state.savedLocations) {
      if (saved.id == _state.selectedLocationId) {
        return LocationSelection.saved(saved);
      }
    }

    return LocationSelection.current(_state.currentLocation);
  }

  List<LocationSelection> buildLocationSelections() {
    final selections = <LocationSelection>[
      LocationSelection.current(_state.currentLocation),
      ..._state.savedLocations.map(LocationSelection.saved),
    ];

    if (_state.searchedLocation != null) {
      selections.add(_state.searchedLocation!);
    }

    return selections;
  }
}
