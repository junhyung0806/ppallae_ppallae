/// KST(Asia/Seoul, UTC+9) 고정 시간 유틸.
///
/// 앱은 한국 전용 서비스이고 백엔드도 KST 고정으로 계산한다([kst-time.ts]).
/// 그런데 클라이언트가 `DateTime.now()` / `toLocal()` 을 쓰면 **폰의 시간대**에
/// 의존한다 — 사용자가 해외에 있거나 폰 시간대를 잘못 설정하면 "오늘" 판정,
/// 추천시각 표시, 위젯 자정 경계가 전부 틀어진다.
///
/// 이 유틸은 폰 시간대와 무관하게 항상 KST 기준으로 계산한다.
/// UTC 절대시각(서버가 내려주는 ISO)은 그대로 두고, "벽시계 표시/자정 판정"에만 쓴다.
library;

const Duration _kstOffset = Duration(hours: 9);

/// 지금(현재 순간)을 KST 벽시계로 본 DateTime (UTC 플래그가 붙지만 값은 KST 벽시계).
/// 비교·자정 계산 전용 — 표시용 포맷은 [formatKstHm] 사용.
DateTime nowKst() => DateTime.now().toUtc().add(_kstOffset);

/// 임의의 시각을 KST 벽시계 DateTime 으로 변환.
DateTime toKst(DateTime dt) => dt.toUtc().add(_kstOffset);

/// 오늘 KST 자정(00:00) — 벽시계 기준. `isBefore` 비교용.
DateTime kstStartOfToday() {
  final k = nowKst();
  return DateTime.utc(k.year, k.month, k.day);
}

/// 내일 KST 자정(다음 날 00:00).
DateTime kstStartOfTomorrow() =>
    kstStartOfToday().add(const Duration(days: 1));

/// HH:mm (KST) 포맷. 위젯·홈 카드 추천시각 표시용.
String formatKstHm(DateTime dt) {
  final k = toKst(dt);
  final h = k.hour.toString().padLeft(2, '0');
  final m = k.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
