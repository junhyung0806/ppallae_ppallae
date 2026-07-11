import '../../api/models/api_models.dart';
import '../../core/kst_time.dart';

/// 타임라인에서 "오늘(지금~자정) 최적 후보"를 고른다.
///
/// 점수 카드·위젯이 공유하는 로직: 홈 컨트롤러는 화면 표시에,
/// 위젯 백그라운드 워커는 앱이 꺼진 상태의 위젯 갱신에 사용한다.
/// "오늘"·자정 경계는 폰 시간대와 무관하게 항상 KST 기준([kst_time.dart]).
TimelineEntryModel? todayBestOf(TimelineEnvelopeModel? env) {
  if (env == null) return null;
  final now = nowKst();
  final tomorrowMidnight = kstStartOfTomorrow();
  TimelineEntryModel? best;
  for (final e in env.timeline) {
    final k = toKst(e.forecastAt);
    if (k.isBefore(now)) continue;
    if (!k.isBefore(tomorrowMidnight)) continue;
    if (best == null || e.overallScore > best.overallScore) best = e;
  }
  return best;
}

// NOTE(2026-07-10): 아래 헬퍼들 제거 — "내일" 판단은 백엔드 recommendTomorrow
// 플래그가 유일한 소스가 되면서 전부 이중 로직/죽은 코드가 됐다.
//   shouldShowTomorrowHintFor (<60 힌트 — UI 사용처 0)
//   bestUpcomingOf / featuredEntryOf (오늘<50 이면 내일로 롤오버 — 백엔드와
//     기준이 달라 "내일 10:00" 구체 시각이 새어나오는 원인)
//   featuredDayOffsetOf / dayOffsetLabel ("내일/모레" 접두)
