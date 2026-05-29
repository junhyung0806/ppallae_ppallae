import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/models/api_models.dart';
import '../../api/ppallae_api_client.dart';
import 'widget_service.dart';

enum DryingPlace {
  outdoor('OUTDOOR', '실외'),
  balcony('BALCONY', '베란다'),
  indoor('INDOOR', '실내'),
  indoorDehumidifier('INDOOR_DEHUMIDIFIER', '제습기'),
  dryer('DRYER', '건조기');

  const DryingPlace(this.code, this.label);
  final String code;
  final String label;
}

enum LaundryAmount {
  small('SMALL', '소량'),
  medium('MEDIUM', '보통'),
  large('LARGE', '많음'),
  extraLarge('EXTRA_LARGE', '아주 많음');

  const LaundryAmount(this.code, this.label);
  final String code;
  final String label;
}

const _favoritesKey = 'ppallae_favorites';

class LaundryHomeController extends ChangeNotifier {
  LaundryHomeController({PpallaeApiClient? apiClient})
      : _api = apiClient ?? PpallaeApiClient();

  final PpallaeApiClient _api;

  // 기본 지역: 서울 시청 부근 (GPS 실패 시 폴백)
  RegionModel _region = const RegionModel(
    admCode: '1111010100',
    sido: '서울특별시',
    sigungu: '종로구',
    eupmyeondong: '청운동',
    nx: 60,
    ny: 127,
    displayName: '서울특별시 종로구 청운동',
  );

  // 지도 중심/현재 위치 좌표 (기본 서울 시청)
  double _lat = 37.5665;
  double _lng = 126.978;

  List<LaundryTypeModel> _laundryTypes = [];
  String _laundryTypeCode = 'LIGHT';
  DryingPlace _dryingPlace = DryingPlace.outdoor;
  LaundryAmount _laundryAmount = LaundryAmount.medium;

  ScoreEnvelopeModel? _scoreEnvelope;
  TimelineEnvelopeModel? _timeline;
  List<LaundromatModel> _laundromats = [];
  List<RegionModel> _favorites = [];

  bool _loading = false;
  bool _locating = false;
  bool _laundromatsLoading = false;
  String? _error;
  String? _locationNotice;

  RegionModel get region => _region;
  double get lat => _lat;
  double get lng => _lng;
  List<LaundryTypeModel> get laundryTypes => _laundryTypes;
  String get laundryTypeCode => _laundryTypeCode;
  DryingPlace get dryingPlace => _dryingPlace;
  LaundryAmount get laundryAmount => _laundryAmount;
  ScoreEnvelopeModel? get scoreEnvelope => _scoreEnvelope;
  TimelineEnvelopeModel? get timeline => _timeline;
  List<LaundromatModel> get laundromats => _laundromats;
  List<RegionModel> get favorites => _favorites;
  bool get loading => _loading;
  bool get locating => _locating;
  bool get laundromatsLoading => _laundromatsLoading;
  String? get error => _error;
  String? get locationNotice => _locationNotice;

  void dismissLocationNotice() {
    _locationNotice = null;
    notifyListeners();
  }

  bool get isCurrentFavorite =>
      _favorites.any((f) => f.admCode == _region.admCode);

  PpallaeApiClient get api => _api;

  Future<void> initialize() async {
    await _loadFavorites();
    try {
      _laundryTypes = await _api.laundryTypes();
    } catch (_) {
      // 빨래 종류 로드 실패해도 점수 조회는 시도
    }
    // 앱 시작 시 현재 위치 자동 시도 (실패하면 기본 지역으로)
    await useCurrentLocation(silent: true);
    await refresh();
  }

  /// GPS로 현재 위치 → 지역 변환. silent면 권한 거부 등 조용히 폴백.
  Future<void> useCurrentLocation({bool silent = false}) async {
    _locating = true;
    _locationNotice = null;
    notifyListeners();
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locationNotice = '위치 권한이 거부되어 기본 지역으로 표시 중이에요.';
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;
      final region = await _api.currentRegion(_lat, _lng);
      _region = region;
    } catch (e) {
      _locationNotice = '현재 위치를 가져오지 못해 기본 지역으로 표시 중이에요.';
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  /// 지도에서 좌표를 선택했을 때
  Future<void> selectByCoords(double lat, double lng) async {
    _lat = lat;
    _lng = lng;
    try {
      _region = await _api.currentRegion(lat, lng);
    } catch (_) {}
    await refresh();
  }

  Future<void> selectRegion(RegionModel region) async {
    _region = region;
    await refresh();
  }

  Future<void> selectLaundryType(String code) async {
    if (_laundryTypeCode == code) return;
    _laundryTypeCode = code;
    await refresh();
  }

  Future<void> selectDryingPlace(DryingPlace place) async {
    if (_dryingPlace == place) return;
    _dryingPlace = place;
    await refresh();
  }

  Future<void> selectAmount(LaundryAmount amount) async {
    if (_laundryAmount == amount) return;
    _laundryAmount = amount;
    await refresh();
  }

  // ── 즐겨찾기 ──

  Future<void> toggleFavorite() async {
    final exists = _favorites.indexWhere((f) => f.admCode == _region.admCode);
    if (exists >= 0) {
      _favorites.removeAt(exists);
    } else {
      _favorites.add(_region);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String admCode) async {
    _favorites.removeWhere((f) => f.admCode == admCode);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_favoritesKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _favorites = list
            .map((e) => RegionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _favoritesKey,
        jsonEncode(_favorites.map((f) => f.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final score = await _api.currentScore(
        regionCode: _region.admCode,
        laundryTypeCode: _laundryTypeCode,
        dryingPlace: _dryingPlace.code,
        laundryAmount: _laundryAmount.code,
      );
      final timeline = await _api.timeline(
        regionCode: _region.admCode,
        laundryTypeCode: _laundryTypeCode,
        dryingPlace: _dryingPlace.code,
      );
      _scoreEnvelope = score;
      _timeline = timeline;
      WidgetService.update(
        envelope: score,
        bestStartTimeRange: timeline.bestStartTimeRange,
      );
    } on PpallaeApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '알 수 없는 오류: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }

    // 주변 빨래방은 실패해도 무방 (별도 로드)
    _loadLaundromats();
  }

  Future<void> _loadLaundromats() async {
    _laundromatsLoading = true;
    notifyListeners();
    try {
      _laundromats = await _api.nearbyLaundromats(_lat, _lng);
    } catch (_) {
    } finally {
      _laundromatsLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
