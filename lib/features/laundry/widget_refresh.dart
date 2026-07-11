import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../api/ppallae_api_client.dart';
import '../../core/error_codes.dart';
import 'laundry_prefs.dart';
import 'timeline_best.dart';
import 'widget_service.dart';

/// 홈 위젯 백그라운드 갱신 (Android WorkManager).
///
/// 배경: 위젯 Provider 의 `onUpdate` 는 SharedPreferences 에 저장된 값을
/// 다시 그리기만 한다. 앱을 열지 않으면 위젯이 어제 점수를 계속 보여주는
/// 문제가 있어, 30분 주기 백그라운드 작업이 마지막 조건(지역/종류/장소)으로
/// 점수를 다시 조회해 위젯 데이터를 갱신한다.
///
/// - 등록은 앱 시작 시 항상 수행 (idempotent). 위젯 토글이 꺼져 있으면
///   작업 자체가 no-op 으로 끝나므로 등록/해제 상태가 꼬일 여지가 없다.
/// - 실패(네트워크 등)해도 true 를 반환해 backoff 재시도 없이 다음 주기를
///   기다린다 — 위젯은 최신성이 목표라 지난 시도를 따라잡을 이유가 없다.

const String kWidgetRefreshUniqueName = 'ppallae-widget-refresh';
const String kWidgetRefreshTaskName = 'ppallae.widget.refresh';

/// 앱 시작 시 호출. 웹/미지원 플랫폼에서는 아무것도 하지 않는다.
Future<void> registerWidgetBackgroundRefresh() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await Workmanager().initialize(widgetRefreshDispatcher);
    await Workmanager().registerPeriodicTask(
      kWidgetRefreshUniqueName,
      kWidgetRefreshTaskName,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(networkType: NetworkType.connected),
      // update: 주기/제약 변경이 재설치 없이 반영되도록. (keep 은 옛 스펙 고착)
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (e) {
    // 등록 실패는 앱 동작에 영향 없음 — 위젯이 앱 실행 시에만 갱신되는
    // 기존 동작으로 자연 폴백된다.
    debugPrint('PpallaeWidget background refresh register failed: $e');
  }
}

/// WorkManager 가 백그라운드 isolate 에서 실행하는 진입점.
@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(kWidgetEnabledKey) ?? true;
      if (!enabled) return true; // 토글 꺼짐 — 조용히 종료

      final regionCode =
          prefs.getString(kRegionCodeKey) ?? kDefaultRegionCode;
      final laundryTypeCode =
          prefs.getString(kLaundryTypeCodeKey) ?? 'LIGHT';
      final dryingPlace = prefs.getString(kDryingPlaceKey) ?? 'OUTDOOR';

      final api = PpallaeApiClient();
      try {
        // 홈 번들 1콜 (앱과 동일 경로) — 백그라운드에서도 왕복 최소화.
        final bundle = await api.homeBundle(
          regionCode: regionCode,
          laundryTypeCode: laundryTypeCode,
          dryingPlace: dryingPlace,
          laundryAmount: kFixedLaundryAmount,
        );
        // 오늘 후보만 사용 — "내일" 판단은 백엔드 recommendTomorrow 가 유일한
        // 소스 (envelope.score 에 실려 오고 WidgetService 가 라벨을 바꾼다).
        await WidgetService.update(
          envelope: bundle.current,
          featured: todayBestOf(bundle.timeline),
        );
      } finally {
        api.dispose();
      }
      return true;
    } catch (e) {
      PpallaeError(ErrorCodes.wgtBackgroundRefresh, '위젯 백그라운드 갱신 실패.',
              e.toString())
          .log();
      return true; // 다음 주기에 자연 재시도
    }
  });
}
