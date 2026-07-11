import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../api/models/api_models.dart';
import '../../core/error_codes.dart';
import '../../core/kst_time.dart';
import 'grade_utils.dart';

/// 홈 위젯(Android)에 빨래지수 요약을 전달한다. 웹/미지원 플랫폼에서는 무시.
class WidgetService {
  /// 안드로이드 위젯 provider 클래스명.
  /// - 1x1 / 2x1 두 종류. 같은 SharedPreferences 데이터를 공유하지만 각 provider 에
  ///   갱신 브로드캐스트를 보내야 한다.
  /// - `PpallaeWidget3x1Provider` 는 실제로는 **2x1** 위젯을 가리킨다. 사용자 라벨/
  ///   레이아웃은 2x1 이지만, 초기 작명을 그대로 유지해 Manifest receiver name 과
  ///   호환을 깨지 않는다. 클래스명 rename 은 출시 전엔 가능하나 회귀 영향이 커서
  ///   미루는 중 — 출시 후엔 영구 불가 (사용자 홈에 박힌 위젯이 끊김).
  static const _androidProviders = [
    'PpallaeWidget1x1Provider',
    'PpallaeWidget3x1Provider',
  ];

  static Future<void> update({
    required ScoreEnvelopeModel envelope,
    TimelineEntryModel? featured,
  }) async {
    if (kIsWeb) {
      const PpallaeError(
        ErrorCodes.wgtUnsupported,
        '웹 플랫폼은 홈 위젯을 지원하지 않아요.',
      ).log();
      return;
    }
    // 1) SharedPreferences 저장
    //
    // 저장 키는 Kotlin Provider 와 layout XML 이 실제로 읽는 것만 둔다.
    // (`region`/`grade`(label)/`updatedAt`/`currentDate`/`currentTime` 은
    // 과거 디자인 잔재로 죽은 저장이라 제거.)
    //
    // 제품 결정(2026-07-10): 위젯도 **오늘 기준**. 오늘 안에 추천 시간이 없으면
    // (recommendTomorrow) 내일 시각으로 롤오버하지 않고 오늘 점수 그대로 +
    // 등급 라벨 자리에 "내일추천" 을 표시한다 (색/레이아웃은 등급 스타일 유지).
    final recommendTomorrow = envelope.score.recommendTomorrow;
    final effFeatured = recommendTomorrow ? null : featured;
    try {
      final int overallScore =
          effFeatured?.overallScore ?? envelope.score.overallScore;
      final String serverGrade =
          (effFeatured?.grade.isNotEmpty ?? false)
              ? effFeatured!.grade
              : envelope.score.grade;
      final grade = serverGrade.isNotEmpty
          ? serverGrade
          : gradeFromScore(overallScore);
      if (kDebugMode) {
        final recomputed = gradeFromScore(overallScore);
        if (serverGrade.isNotEmpty && recomputed != serverGrade) {
          debugPrint(
              '[PpallaeWidget] grade mismatch: server=$serverGrade local=$recomputed score=$overallScore');
        }
      }
      await HomeWidget.saveWidgetData<String>('score', '$overallScore');
      await HomeWidget.saveWidgetData<String>('gradeCode', grade);
      // Kotlin Provider 가 '1' 이면 등급 라벨 대신 "내일추천" 을 렌더.
      await HomeWidget.saveWidgetData<String>(
        'tomorrow',
        recommendTomorrow ? '1' : '',
      );
      if (recommendTomorrow) {
        // 내일의 구체 시각은 표시하지 않음 → "추천 시간 : 내일"
        await HomeWidget.saveWidgetData<String>('recoStart', '내일');
        await HomeWidget.saveWidgetData<String>('recoEnd', '');
      } else {
        // featured 는 항상 **오늘** 후보 (앱 자체 내일 롤오버는 제거됨 —
        // "내일" 판단은 백엔드 recommendTomorrow 가 유일한 소스).
        final (recoStart, recoEnd) = _recoFromFeatured(effFeatured);
        await HomeWidget.saveWidgetData<String>('recoStart', recoStart);
        await HomeWidget.saveWidgetData<String>('recoEnd', recoEnd);
      }
      // 갱신 시각(신선도) — 위젯이 "n분 전" 을 렌더하고, 오래되면(예: 3h+)
      // 회색 처리해 stale 데이터를 사용자가 눈치채게 한다. epoch millis(UTC).
      await HomeWidget.saveWidgetData<String>(
        'updatedAtMs',
        '${DateTime.now().toUtc().millisecondsSinceEpoch}',
      );
    } catch (e) {
      PpallaeError(
        ErrorCodes.wgtSaveData,
        '위젯 데이터를 저장하지 못했어요.',
        e.toString(),
      ).log();
      return;
    }
    // 2) 위젯 갱신 트리거 (RemoteViews 렌더 실패 포함)
    for (final provider in _androidProviders) {
      try {
        final ok = await HomeWidget.updateWidget(androidName: provider);
        debugPrint('PpallaeWidget update $provider result: $ok');
      } catch (e) {
        PpallaeError(
          ErrorCodes.wgtUpdate,
          '$provider 갱신 실패. 위젯 등록 여부 확인.',
          e.toString(),
        ).log();
      }
    }
  }

  /// 위젯을 비활성화 상태로 표시. (사용자가 설정에서 끔)
  /// Kotlin Provider 가 실제로 읽는 키만 비운다.
  static Future<void> disable() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('score', '–');
      await HomeWidget.saveWidgetData<String>('gradeCode', '');
      await HomeWidget.saveWidgetData<String>('tomorrow', '');
      await HomeWidget.saveWidgetData<String>('recoStart', '꺼짐');
      await HomeWidget.saveWidgetData<String>('recoEnd', '');
      // 비활성 시엔 갱신 시각을 비워 위젯이 "n분 전" 을 숨기도록.
      await HomeWidget.saveWidgetData<String>('updatedAtMs', '');
      for (final provider in _androidProviders) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } catch (e) {
      PpallaeError(
        ErrorCodes.wgtDisable,
        '위젯 비활성화 처리에 실패했어요.',
        e.toString(),
      ).log();
    }
  }
}

/// 오늘 후보의 시작/종료 시각 라벨 (KST 벽시계 기준).
/// recoStart = HH:MM, recoEnd = 시작 + 세탁 45분 (hangAt 추정).
/// ("내일/모레" 접두는 제거 — 내일 판단은 백엔드 recommendTomorrow 가 유일한 소스)
/// best 가 null 이면 ("지금은", "비추천") 폴백.
(String, String) _recoFromFeatured(TimelineEntryModel? best) {
  if (best == null) return ('지금은', '비추천');
  final hang = best.forecastAt.add(const Duration(minutes: 45));
  return (formatKstHm(best.forecastAt), formatKstHm(hang));
}

