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

/// 오늘 최적 점수가 60 미만이거나 오늘 후보 자체가 없으면 "내일 추천" 라벨 표시.
bool shouldShowTomorrowHintFor(TimelineEntryModel? todayBest) {
  return todayBest == null || todayBest.overallScore < 60;
}

/// 지금(KST) 이후 전체 타임라인에서 점수 최고 후보. 오늘/내일/모레 무관.
/// 밤이나 악천후로 오늘이 가망 없을 때 "다음 좋은 시간대"를 찾는 데 쓴다.
TimelineEntryModel? bestUpcomingOf(TimelineEnvelopeModel? env) {
  if (env == null) return null;
  final now = nowKst();
  TimelineEntryModel? best;
  for (final e in env.timeline) {
    if (toKst(e.forecastAt).isBefore(now)) continue;
    if (best == null || e.overallScore > best.overallScore) best = e;
  }
  return best;
}

/// 헤드라인(홈 큰 숫자·위젯)에 보여줄 후보 결정.
///
/// 오늘 남은 시간에 NORMAL(50점) 이상 후보가 있으면 오늘 최고를 보여준다
/// (오늘 빨래할 만하면 오늘 하라는 뜻). 그렇지 않으면(밤/비 등 오늘 가망 없음)
/// 다음 좋은 시간대(보통 내일 아침)로 롤오버한다.
///
/// 위젯 우선 앱에서 밤마다 "0점·최악"이 뜨는 문제를 막는 핵심 로직.
const int kTodayViableThreshold = 50;

TimelineEntryModel? featuredEntryOf(TimelineEnvelopeModel? env) {
  final today = todayBestOf(env);
  if (today != null && today.overallScore >= kTodayViableThreshold) {
    return today;
  }
  return bestUpcomingOf(env) ?? today;
}

/// featured 후보가 며칠 뒤인지 (0=오늘, 1=내일, 2=모레…). KST 달력 기준.
int featuredDayOffsetOf(TimelineEntryModel? featured) {
  if (featured == null) return 0;
  final todayMidnight = kstStartOfToday();
  final f = toKst(featured.forecastAt);
  final fMidnight = DateTime.utc(f.year, f.month, f.day);
  final days = fMidnight.difference(todayMidnight).inDays;
  return days < 0 ? 0 : days;
}

/// dayOffset → 한글 라벨 접두 (0=빈문자열, 1=내일, 2=모레, 그 외 N일 뒤).
String dayOffsetLabel(int offset) {
  switch (offset) {
    case 0:
      return '';
    case 1:
      return '내일';
    case 2:
      return '모레';
    default:
      return '$offset일 뒤';
  }
}
