import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/api/models/api_models.dart';
import 'package:ppallae_ppallae/api/ppallae_api_client.dart';
import 'package:ppallae_ppallae/core/kst_time.dart';
import 'package:ppallae_ppallae/features/laundry/consent_screen.dart';
import 'package:ppallae_ppallae/features/laundry/grade_utils.dart';
import 'package:ppallae_ppallae/features/laundry/laundry_home_controller.dart';
import 'package:ppallae_ppallae/features/laundry/laundry_prefs.dart';
import 'package:ppallae_ppallae/features/laundry/timeline_best.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 호출 수를 세는 fake API 클라이언트 — 30분 캐시 검증용.
class _FakeApiClient extends PpallaeApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake.test/api/v1');

  int scoreCalls = 0;
  int timelineCalls = 0;
  int laundromatCalls = 0;

  static const _score = LaundryScoreModel(
    overallScore: 70,
    outdoorScore: 70,
    indoorScore: 55,
    estimatedDryHoursMin: 3,
    estimatedDryHoursMax: 4,
    grade: 'GOOD',
    warningTexts: [],
  );

  static const _weather = WeatherSummaryModel(
    temperatureC: 22,
    humidityPercent: 50,
    windSpeedMps: 2,
    precipType: 'NONE',
    skyCondition: 'CLEAR',
  );

  @override
  Future<ScoreEnvelopeModel> currentScore({
    required String regionCode,
    required String laundryTypeCode,
    required String dryingPlace,
    required String laundryAmount,
  }) async {
    scoreCalls++;
    return ScoreEnvelopeModel(
      regionDisplayName: '테스트 지역',
      admCode: regionCode,
      generatedAt: DateTime.now(),
      sources: const ['test'],
      stale: false,
      weather: _weather,
      score: _score,
    );
  }

  @override
  Future<TimelineEnvelopeModel> timeline({
    required String regionCode,
    required String laundryTypeCode,
    required String dryingPlace,
    required String laundryAmount,
  }) async {
    timelineCalls++;
    return const TimelineEnvelopeModel(
        bestStartTimeRange: null, timeline: []);
  }

  @override
  Future<LaundromatsEnvelopeModel> nearbyLaundromats(
      double lat, double lng) async {
    laundromatCalls++;
    return const LaundromatsEnvelopeModel(items: [], source: 'test');
  }
}

TimelineEntryModel _entry(DateTime forecastAt, int score) {
  return TimelineEntryModel(
    forecastAt: forecastAt,
    hourOfDay: forecastAt.hour,
    displayTime: null,
    overallScore: score,
    grade: gradeFromScore(score),
    estimatedDryHoursMin: 3,
    estimatedDryHoursMax: 4,
    temperatureC: 20,
    humidityPercent: 50,
    precipType: 'NONE',
    skyCondition: 'CLEAR',
  );
}

void main() {
  group('gradeFromScore 경계값', () {
    test('각 등급 임계값에서 올바른 등급을 반환한다', () {
      expect(gradeFromScore(100), 'EXCELLENT');
      expect(gradeFromScore(85), 'EXCELLENT');
      expect(gradeFromScore(84), 'GOOD');
      expect(gradeFromScore(70), 'GOOD');
      expect(gradeFromScore(69), 'NORMAL');
      expect(gradeFromScore(50), 'NORMAL');
      expect(gradeFromScore(49), 'BAD');
      expect(gradeFromScore(30), 'BAD');
      expect(gradeFromScore(29), 'VERY_BAD');
      expect(gradeFromScore(0), 'VERY_BAD');
    });

    test('gradeLabel은 한글 라벨로 매핑된다', () {
      expect(gradeLabel('EXCELLENT'), '최고');
      expect(gradeLabel('GOOD'), '좋음');
      expect(gradeLabel('NORMAL'), '보통');
      expect(gradeLabel('BAD'), '나쁨');
      expect(gradeLabel('VERY_BAD'), '최악');
      expect(gradeLabel('UNKNOWN'), 'UNKNOWN'); // 알 수 없는 등급은 원문 유지
    });
  });

  group('PpallaeApiClient base URL', () {
    test('주입한 baseUrl을 그대로 사용한다', () {
      final client =
          PpallaeApiClient(baseUrl: 'https://api.example.com/api/v1');
      expect(client.baseUrl, 'https://api.example.com/api/v1');
    });

    test('기본 baseUrl은 /api/v1 로 끝난다 (운영 빌드 시 dart-define으로 교체)', () {
      // 운영 release 빌드는 --dart-define=PPALLAE_API_BASE_URL=https://... 로 주입한다.
      // 미주입 시 기본값은 로컬 개발용이며 반드시 /api/v1 접미사를 가진다.
      final client = PpallaeApiClient();
      expect(client.baseUrl, endsWith('/api/v1'));
    });
  });

  group('KST 시간 유틸 (폰 시간대 무관)', () {
    test('toKst 는 UTC+9 벽시계로 변환한다', () {
      // 2026-07-04 00:30 UTC → KST 09:30
      final utc = DateTime.utc(2026, 7, 4, 0, 30);
      expect(formatKstHm(utc), '09:30');
    });

    test('formatKstHm 은 입력의 원래 시간대와 무관하게 동일 결과', () {
      // 같은 절대시각을 UTC/오프셋 다르게 표현해도 KST 벽시계는 같다.
      final a = DateTime.utc(2026, 7, 4, 1, 0); // 10:00 KST
      final b = DateTime.parse('2026-07-04T10:00:00+09:00');
      expect(formatKstHm(a), '10:00');
      expect(formatKstHm(a), formatKstHm(b));
    });

    test('자정 경계: 내일 자정은 오늘 자정보다 정확히 하루 뒤', () {
      final diff = kstStartOfTomorrow().difference(kstStartOfToday());
      expect(diff, const Duration(days: 1));
    });
  });

  group('featured 후보 롤오버 (밤 0점 방지)', () {
    test('dayOffsetLabel 매핑', () {
      expect(dayOffsetLabel(0), '');
      expect(dayOffsetLabel(1), '내일');
      expect(dayOffsetLabel(2), '모레');
      expect(dayOffsetLabel(3), '3일 뒤');
    });

    test('가까운 시간이 낮고(<50) 나중이 높으면(>=50) featured 는 나중 것', () {
      // 지금 이후로만 배치: +1h 30점(가망 없음), +20h 70점(다음 좋은 시간대).
      // 오늘/내일 어느 쪽으로 갈리든 featuredEntryOf 는 항상 70점 후보를 골라야 한다.
      final nowUtc = DateTime.now().toUtc();
      final env = TimelineEnvelopeModel(
        bestStartTimeRange: null,
        timeline: [
          _entry(nowUtc.add(const Duration(hours: 1)), 30),
          _entry(nowUtc.add(const Duration(hours: 20)), 70),
        ],
      );
      final featured = featuredEntryOf(env);
      expect(featured, isNotNull);
      expect(featured!.overallScore, 70);
    });

    test('후보가 없으면 null', () {
      final env = TimelineEnvelopeModel(bestStartTimeRange: null, timeline: []);
      expect(featuredEntryOf(env), isNull);
    });
  });

  group('약관 동의 게이트', () {
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    test('저장된 동의 없으면 미동의 → 동의화면 표시', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ConsentScreen.hasConsented(), false);
    });

    test('현재 버전 동의 저장돼 있으면 스킵', () async {
      SharedPreferences.setMockInitialValues(
          {kConsentVersionKey: kCurrentConsentVersion});
      expect(await ConsentScreen.hasConsented(), true);
    });

    test('과거 버전이면 재동의 필요', () async {
      SharedPreferences.setMockInitialValues(
          {kConsentVersionKey: kCurrentConsentVersion - 1});
      expect(await ConsentScreen.hasConsented(), false);
    });
  });

  group('30분 점수 캐시 (셀렉터 연타 시 API 재호출 방지)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('같은 조합 재갱신=캐시, 조합 변경=1회 추가, force=강제 호출', () async {
      final fake = _FakeApiClient();
      final controller = LaundryHomeController(apiClient: fake);

      await controller.refresh(); // 최초 → 실제 호출
      expect(fake.scoreCalls, 1);
      expect(fake.timelineCalls, 3); // 선택+실외비교+실내비교
      expect(fake.laundromatCalls, 1);

      await controller.refresh(); // 같은 조합 → 캐시 히트, 호출 없음
      expect(fake.scoreCalls, 1);
      expect(fake.laundromatCalls, 1); // 빨래방도 재호출 없음

      await controller.selectDryingPlace(DryingPlace.indoor); // 새 조합
      expect(fake.scoreCalls, 2);

      await controller.selectDryingPlace(DryingPlace.outdoor); // 이전 조합 → 캐시
      expect(fake.scoreCalls, 2);

      await controller.refresh(force: true); // 당겨서 새로고침 → 캐시 무시
      expect(fake.scoreCalls, 3);
    });
  });
}
