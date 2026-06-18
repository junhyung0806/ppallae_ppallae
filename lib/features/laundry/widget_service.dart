import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../api/models/api_models.dart';
import '../../core/error_codes.dart';
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
    TimelineEntryModel? todayBest,
    bool showTomorrowHint = false,
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
    // 점수/등급/추천 시각은 오늘(현재~자정) 최적 후보 기준으로 표시.
    // todayBest 가 없으면 (오늘 후보 0개) score envelope 의 글로벌 best 로 폴백.
    try {
      final int overallScore =
          todayBest?.overallScore ?? envelope.score.overallScore;
      final String serverGrade =
          (todayBest?.grade.isNotEmpty ?? false)
              ? todayBest!.grade
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
      final (recoStart, recoEnd) = _recoFromTodayBest(todayBest);
      await HomeWidget.saveWidgetData<String>('recoStart', recoStart);
      // showTomorrowHint 면 recoEnd 자리에 "내일 추천" 보조 라벨을 함께 표시.
      // 위젯 layout 의 widget_reco 가 "추천 시간 : recoStart ~ recoEnd" 로 합치므로
      // 가독성 위해 hangAt 시각 대신 보조 라벨로 대체.
      await HomeWidget.saveWidgetData<String>(
        'recoEnd',
        showTomorrowHint ? '내일 추천' : recoEnd,
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
      await HomeWidget.saveWidgetData<String>('recoStart', '꺼짐');
      await HomeWidget.saveWidgetData<String>('recoEnd', '');
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

/// 오늘 최적 후보의 시작/종료 시각 라벨.
/// recoStart = 시작 HH:MM, recoEnd = 시작 + 세탁 45분 (hangAt 추정).
/// 백엔드의 hangAt 계산식과 동일하지만 timeline entry 에 hangAt 이 없어 클라이언트 추정.
/// todayBest 가 null 이면 ("지금은", "비추천") 폴백.
(String, String) _recoFromTodayBest(TimelineEntryModel? best) {
  if (best == null) return ('지금은', '비추천');
  final start = best.forecastAt.toLocal();
  final hang = start.add(const Duration(minutes: 45));
  String fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return (fmt(start), fmt(hang));
}

