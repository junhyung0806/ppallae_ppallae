import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart' show Color;

import '../../api/models/api_models.dart';
import '../../api/ppallae_api_client.dart';
import '../../core/error_codes.dart';
import 'grade_utils.dart';
import 'widget_service.dart';

/// 사용자가 선택할 수 있는 건조 장소.
/// 표시 순서대로 정의 — UI 셀렉터는 이 순서를 그대로 사용한다.
///
/// 백엔드 enum 에는 INDOOR_DEHUMIDIFIER / DRYER 도 있지만, 제품 결정으로
/// 모바일에서는 자연 건조 3종(실외/베란다/실내)만 노출한다. 제습기/건조기는
/// 사용자 직관과 안 맞아 점수 계산 의미가 흐려진다고 판단.
/// 표시 순서: 실외 → 실내 → 베란다. UI 셀렉터는 `DryingPlace.values` 를
/// 그대로 사용하므로 이 enum 의 선언 순서가 곧 사용자가 보는 순서다.
enum DryingPlace {
  outdoor('OUTDOOR', '실외'),
  indoor('INDOOR', '실내'),
  balcony('BALCONY', '베란다');

  const DryingPlace(this.code, this.label);
  final String code;
  final String label;
}

/// 백엔드 score API 에 전송하는 laundryAmount 고정값.
/// 제품 결정으로 사용자 선택 UI는 두지 않고 항상 보통(MEDIUM) 기준으로 계산.
/// 즉 점수 카드는 "보통량 빨래를 가정한 점수" 를 보여준다.
const String kFixedLaundryAmount = 'MEDIUM';

const _widgetEnabledKey = 'ppallae_widget_enabled';
const _laundryTypeCodeKey = 'ppallae_laundry_type_code';
const _dryingPlaceKey = 'ppallae_drying_place';

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

  ScoreEnvelopeModel? _scoreEnvelope;
  TimelineEnvelopeModel? _timeline;
  /// 실외 기준 timeline (비교 칩용). 사용자 선택과 무관하게 항상 fetch.
  TimelineEnvelopeModel? _outdoorTimeline;
  /// 실내 기준 timeline (비교 칩용). 사용자 선택과 무관하게 항상 fetch.
  TimelineEnvelopeModel? _indoorTimeline;
  List<LaundromatModel> _laundromats = [];
  /// 마지막 빨래방 응답이 mock/fallback이면 true. UI에 명시 표시.
  bool _laundromatsIsMock = false;
  bool _widgetEnabled = true;
  /// 백엔드 공개 앱 설정. 시작 시 1회 fetch. 실패하면 null (정책 URL은 legal_screen 로컬 폴백).
  AppConfigModel? _appConfig;

  bool _loading = false;
  bool _locating = false;
  bool _laundromatsLoading = false;
  String? _error;
  String? _locationNotice;

  // ── 위치 해석 상태 ──
  /// 현재 _region이 GPS/지도/검색으로 확정된 게 아니라 앱 기본값(서울 시청)인지.
  /// initialize 진입 시 true, 한 번이라도 GPS/검색/지도로 region 잡히면 false.
  bool _isUsingFallbackRegion = true;

  RegionModel get region => _region;
  double get lat => _lat;
  double get lng => _lng;
  List<LaundryTypeModel> get laundryTypes => _laundryTypes;
  String get laundryTypeCode => _laundryTypeCode;
  DryingPlace get dryingPlace => _dryingPlace;
  ScoreEnvelopeModel? get scoreEnvelope => _scoreEnvelope;
  TimelineEnvelopeModel? get timeline => _timeline;
  List<LaundromatModel> get laundromats => _laundromats;
  bool get laundromatsIsMock => _laundromatsIsMock;
  bool get widgetEnabled => _widgetEnabled;
  bool get loading => _loading;
  bool get locating => _locating;
  bool get laundromatsLoading => _laundromatsLoading;
  String? get error => _error;
  String? get locationNotice => _locationNotice;
  bool get isUsingFallbackRegion => _isUsingFallbackRegion;
  AppConfigModel? get appConfig => _appConfig;

  // ── 추천 시간: 오늘 기준 (현재 시각 ~ 오늘 KST 자정) ──
  //
  // 점수 카드의 큰 숫자/등급/건조시간/추천 시간 박스는 모두 timeline 의 오늘
  // 후보 중 점수 최대값 기준으로 계산한다. 백엔드 score API 의 글로벌 best
  // (30시간 horizon, 보통 내일 새벽)와는 다름.
  //
  // 오늘 후보가 0개 (=자정 직전 등) 거나 오늘 최대 점수가 60 미만이면
  // [shouldShowTomorrowHint] 가 true 가 되어 박스 옆에 "내일 추천" 라벨 표시.

  TimelineEntryModel? _todayBestOf(TimelineEnvelopeModel? env) {
    if (env == null) return null;
    final now = DateTime.now();
    // KST 자정 = 로컬 자정 (Android 폰이 KST 일 때).
    final tomorrowMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    TimelineEntryModel? best;
    for (final e in env.timeline) {
      final local = e.forecastAt.toLocal();
      if (local.isBefore(now)) continue;
      if (!local.isBefore(tomorrowMidnight)) continue;
      if (best == null || e.overallScore > best.overallScore) best = e;
    }
    return best;
  }

  /// 사용자 선택 dryingPlace 기준 오늘 최적 후보. 카드 큰 숫자/추천 박스의 원천.
  TimelineEntryModel? get todayBestEntry => _todayBestOf(_timeline);

  /// 실외 기준 오늘 최적 후보. 비교 칩 OUTDOOR 점수 원천.
  TimelineEntryModel? get todayBestOutdoor => _todayBestOf(_outdoorTimeline);

  /// 실내 기준 오늘 최적 후보. 비교 칩 INDOOR 점수 원천.
  TimelineEntryModel? get todayBestIndoor => _todayBestOf(_indoorTimeline);

  /// 오늘 최적 점수가 60 미만이거나 오늘 후보 자체가 없으면 true.
  /// 박스 옆에 "내일 추천" 작은 라벨을 표시할지 결정.
  bool get shouldShowTomorrowHint {
    final best = todayBestEntry;
    return best == null || best.overallScore < 60;
  }

  /// 현재 점수의 등급 코드.
  /// 점수 카드 큰 숫자가 [todayBestEntry] 기반이므로 액센트 색도 같은 기준.
  /// timeline 데이터가 아직 없을 때만 score API 로 폴백.
  String get currentGradeCode {
    final today = todayBestEntry;
    if (today != null) {
      if (today.grade.isNotEmpty) return today.grade;
      return gradeFromScore(today.overallScore);
    }
    final env = _scoreEnvelope;
    if (env == null) return '';
    if (env.score.grade.isNotEmpty) return env.score.grade;
    return gradeFromScore(env.score.overallScore);
  }

  /// 앱 전체 액센트 색. 점수 결정 전(로딩/에러)에는 브랜드 폴백 색.
  /// 점수가 결정되면 등급 색으로 변환되어 셀렉터/탑바/링크 강조 색이
  /// 한꺼번에 등급에 맞춰 바뀐다.
  Color get currentAccentColor {
    final g = currentGradeCode;
    return g.isEmpty ? kFallbackAccent : gradeColor(g);
  }

  /// 그라데이션 페어 (선택 pill 의 밝은 쪽). 액센트와 같은 폴백 규칙.
  Color get currentAccentColorLight {
    final g = currentGradeCode;
    return g.isEmpty ? kFallbackAccentLight : gradeColorLight(g);
  }

  void dismissLocationNotice() {
    _locationNotice = null;
    notifyListeners();
  }

  PpallaeApiClient get api => _api;

  Future<void> initialize() async {
    await _loadWidgetEnabled();
    await _loadSelectorPrefs();
    // 시작 시 공개 앱 설정 fetch (점검/강제 업데이트/정책 URL/피처 플래그).
    // 실패해도 앱은 계속 진행 — _appConfig 가 null 인 경우 화면들이 로컬 폴백 사용.
    try {
      _appConfig = await _api.appConfig();
    } catch (_) {}
    try {
      _laundryTypes = await _api.laundryTypes();
    } catch (_) {
      // 빨래 종류 로드 실패해도 점수 조회는 시도
    }
    // 앱 시작 시 현재 위치 자동 시도 (실패하면 기본 지역으로)
    await useCurrentLocation(silent: true);
    await refresh();
  }

  /// 빨래 종류 / 건조 장소 마지막 선택값 복원.
  /// 빨래량은 [kFixedLaundryAmount] 로 항상 고정이라 저장/복원 대상이 아니다.
  Future<void> _loadSelectorPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString(_laundryTypeCodeKey);
      if (type != null && type.isNotEmpty) _laundryTypeCode = type;
      final placeCode = prefs.getString(_dryingPlaceKey);
      if (placeCode != null) {
        for (final p in DryingPlace.values) {
          if (p.code == placeCode) {
            _dryingPlace = p;
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _persistSelectorPref(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  /// GPS로 현재 위치 → 지역 변환. silent면 권한 거부 등 조용히 폴백.
  /// 단계별 실패는 [PpallaeError]로 분류해 사용자/로그에 코드를 노출한다.
  Future<void> useCurrentLocation({bool silent = false}) async {
    _locating = true;
    _locationNotice = null;
    notifyListeners();

    final err = await _resolveCurrentLocation();
    if (err != null) {
      err.log();
      _locationNotice = err.displayText;
    }
    _locating = false;
    notifyListeners();
  }

  /// 위치 조회 + 지역 변환. 성공 시 null, 실패 시 [PpallaeError] 반환.
  Future<PpallaeError?> _resolveCurrentLocation() async {
    // 1) 폰의 위치 서비스 자체 점검
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const PpallaeError(
        ErrorCodes.locServiceDisabled,
        '위치 서비스가 꺼져 있어요. 폰 설정에서 켜주세요.',
      );
    }

    // 2) 권한
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return const PpallaeError(
        ErrorCodes.locPermissionForever,
        '위치 권한이 영구 거부됐어요. 폰 설정 → 빨래빨래 → 권한에서 허용해주세요.',
      );
    }
    if (perm == LocationPermission.denied) {
      return const PpallaeError(
        ErrorCodes.locPermissionDenied,
        '위치 권한이 거부됐어요. 다시 시도하면 권한을 다시 요청해요.',
      );
    }

    // 3) 좌표 획득: best 정확도 우선 (FusedLocation 고품질).
    //    1차로 best 시도. accuracy(오차 반경)가 너무 크면 한 번 더 샘플링해서
    //    더 정확한 fix가 들어오는지 본다. 최선의 fix를 선택.
    Position? best;
    final first = await _tryGetPosition(LocationAccuracy.best, 10);
    best = first;
    // 첫 fix가 100m 넘게 부정확하면 2-3초 대기 후 한 번 더 샘플.
    if (first != null && first.accuracy > 100) {
      await Future.delayed(const Duration(seconds: 3));
      final second = await _tryGetPosition(LocationAccuracy.best, 8);
      if (second != null && second.accuracy < first.accuracy) {
        best = second;
      }
    }
    // 그래도 fix가 없으면 high → medium → lastKnown 폴백
    best ??= await _tryGetPosition(LocationAccuracy.high, 8);
    best ??= await _tryGetPosition(LocationAccuracy.medium, 10);
    if (best == null) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null || _isStaleLastKnownPosition(last)) {
        return const PpallaeError(
          ErrorCodes.locTimeout,
          '위치 신호가 약해서 시간 초과됐어요. 야외에서 다시 시도해보세요.',
        );
      }
      best = last;
    }
    final pos = best;

    if (pos.accuracy > 5000) {
      return const PpallaeError(
        ErrorCodes.locTimeout,
        '위치 오차가 너무 커서 현재 위치를 사용할 수 없어요. 야외에서 다시 시도해주세요.',
      );
    }

    if (pos.accuracy > 200) {
      _locationNotice =
          '현재 위치 오차가 커서 실제 위치와 다를 수 있어요. 야외에서 다시 시도하면 더 정확해집니다.';
      if (kDebugMode) {
        debugPrint(
            'PpallaeError [LOC-warn] 위치 정확도 ${pos.accuracy.toStringAsFixed(0)}m — 실내에선 부정확할 수 있음');
      }
    }

    _lat = pos.latitude;
    _lng = pos.longitude;
    // 위치 좌표는 민감정보. release 빌드에는 출력 X.
    if (kDebugMode) {
      debugPrint(
          'PpallaeLocation accuracy=${pos.accuracy.toStringAsFixed(1)}m');
    }

    // 4) 좌표 → 지역 변환
    try {
      _region = await _api.currentRegion(_lat, _lng);
      _isUsingFallbackRegion = false;
    } catch (e) {
      return PpallaeError(
        ErrorCodes.locRegionLookup,
        '좌표를 지역으로 변환하지 못했어요. 백엔드 연결을 확인해주세요.',
        e.toString(),
      );
    }
    return null;
  }

  /// 한 번의 [Geolocator.getCurrentPosition] 시도. 타임아웃/오류 시 null.
  Future<Position?> _tryGetPosition(
      LocationAccuracy accuracy, int timeoutSec) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSec),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isStaleLastKnownPosition(Position position) {
    final timestamp = position.timestamp;
    return DateTime.now().difference(timestamp.toLocal()) >
        const Duration(minutes: 30);
  }

  /// 지도에서 좌표를 선택했을 때. region 변환 실패는 조용히 무시하지 않고
  /// locationNotice로 알린다 (이전 동작: silent catch → 사용자 인지 불가).
  Future<void> selectByCoords(double lat, double lng) async {
    _lat = lat;
    _lng = lng;
    try {
      _region = await _api.currentRegion(lat, lng);
      _isUsingFallbackRegion = false;
    } catch (e) {
      final err = PpallaeError(
        ErrorCodes.locRegionLookup,
        '선택한 위치의 지역 정보를 가져오지 못했어요.',
        e.toString(),
      );
      err.log();
      _locationNotice = err.displayText;
    }
    await refresh();
  }

  Future<void> selectRegion(RegionModel region) async {
    _region = region;
    final representative = _latLngFromKmaGrid(region.nx, region.ny);
    _lat = representative.lat;
    _lng = representative.lng;
    _isUsingFallbackRegion = false;
    _locationNotice =
        '검색한 지역의 대표 좌표 기준으로 지도와 주변 빨래방을 표시합니다.';
    _laundromats = [];
    _laundromatsIsMock = false;
    await refresh();
  }

  Future<void> selectLaundryType(String code) async {
    if (_laundryTypeCode == code) return;
    _laundryTypeCode = code;
    await _persistSelectorPref(_laundryTypeCodeKey, code);
    await refresh();
  }

  Future<void> selectDryingPlace(DryingPlace place) async {
    if (_dryingPlace == place) return;
    _dryingPlace = place;
    await _persistSelectorPref(_dryingPlaceKey, place.code);
    await refresh();
  }

  // ── 위젯 토글 ──

  Future<void> setWidgetEnabled(bool enabled) async {
    if (_widgetEnabled == enabled) return;
    _widgetEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_widgetEnabledKey, enabled);
    } catch (_) {}
    notifyListeners();
    if (enabled) {
      // 다시 켜면 현재 데이터로 즉시 갱신 — 오늘 기준 best 사용.
      final score = _scoreEnvelope;
      if (score != null) {
        await WidgetService.update(
          envelope: score,
          todayBest: todayBestEntry,
          showTomorrowHint: shouldShowTomorrowHint,
        );
      }
    } else {
      await WidgetService.disable();
    }
  }

  Future<void> _loadWidgetEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _widgetEnabled = prefs.getBool(_widgetEnabledKey) ?? true;
    } catch (_) {}
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 빨래량(amount)은 사용자 노출 셀렉터 없이 항상 [kFixedLaundryAmount] 고정.
      // score/timeline + outdoor/indoor 비교용 timeline 까지 병렬로 호출.
      // 비교 칩이 사용자 선택과 무관하게 OUTDOOR/INDOOR 두 장소를 보여주므로
      // 사용자 선택이 그 둘 중 하나여도 별도로 두 번 더 호출한다 (응답 가벼움).
      final results = await Future.wait([
        _api.currentScore(
          regionCode: _region.admCode,
          laundryTypeCode: _laundryTypeCode,
          dryingPlace: _dryingPlace.code,
          laundryAmount: kFixedLaundryAmount,
        ),
        _api.timeline(
          regionCode: _region.admCode,
          laundryTypeCode: _laundryTypeCode,
          dryingPlace: _dryingPlace.code,
          laundryAmount: kFixedLaundryAmount,
        ),
        _api.timeline(
          regionCode: _region.admCode,
          laundryTypeCode: _laundryTypeCode,
          dryingPlace: DryingPlace.outdoor.code,
          laundryAmount: kFixedLaundryAmount,
        ),
        _api.timeline(
          regionCode: _region.admCode,
          laundryTypeCode: _laundryTypeCode,
          dryingPlace: DryingPlace.indoor.code,
          laundryAmount: kFixedLaundryAmount,
        ),
      ]);
      _scoreEnvelope = results[0] as ScoreEnvelopeModel;
      _timeline = results[1] as TimelineEnvelopeModel;
      _outdoorTimeline = results[2] as TimelineEnvelopeModel;
      _indoorTimeline = results[3] as TimelineEnvelopeModel;
      if (_widgetEnabled) {
        WidgetService.update(
          envelope: _scoreEnvelope!,
          todayBest: todayBestEntry,
          showTomorrowHint: shouldShowTomorrowHint,
        );
      }
    } on PpallaeApiException catch (e) {
      debugPrint('PpallaeError $e');
      _error = e.toString(); // [API-xxx] message 형태로 코드 노출
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
      final env = await _api.nearbyLaundromats(_lat, _lng);
      _laundromats = env.items;
      _laundromatsIsMock = env.isMock;
    } catch (_) {
      _laundromats = [];
      _laundromatsIsMock = false;
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

({double lat, double lng}) _latLngFromKmaGrid(int nx, int ny) {
  const re = 6371.00877;
  const grid = 5.0;
  const slat1 = 30.0;
  const slat2 = 60.0;
  const olon = 126.0;
  const olat = 38.0;
  const xo = 43.0;
  const yo = 136.0;
  const degToRad = math.pi / 180.0;
  const radToDeg = 180.0 / math.pi;

  final reGrid = re / grid;
  final slat1Rad = slat1 * degToRad;
  final slat2Rad = slat2 * degToRad;
  final olonRad = olon * degToRad;
  final olatRad = olat * degToRad;

  var sn = math.tan(math.pi * 0.25 + slat2Rad * 0.5) /
      math.tan(math.pi * 0.25 + slat1Rad * 0.5);
  sn = math.log(math.cos(slat1Rad) / math.cos(slat2Rad)) / math.log(sn);

  var sf = math.tan(math.pi * 0.25 + slat1Rad * 0.5);
  sf = math.pow(sf, sn) * math.cos(slat1Rad) / sn;

  var ro = math.tan(math.pi * 0.25 + olatRad * 0.5);
  ro = reGrid * sf / math.pow(ro, sn);

  final xn = nx - xo;
  final yn = ro - ny + yo;
  var ra = math.sqrt(xn * xn + yn * yn);
  if (sn < 0) ra = -ra;

  final alat =
      2.0 * math.atan(math.pow(reGrid * sf / ra, 1.0 / sn)) - math.pi * 0.5;
  var theta = math.atan2(xn, yn);
  theta /= sn;
  final alon = theta + olonRad;

  return (lat: alat * radToDeg, lng: alon * radToDeg);
}
