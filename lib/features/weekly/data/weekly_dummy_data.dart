import '../../../core/models/laundry_status.dart';

class WeeklyLaundryForecast {
  const WeeklyLaundryForecast({
    required this.dayLabel,
    required this.dateLabel,
    required this.score,
    required this.status,
    required this.reason,
    this.isBest = false,
  });

  final String dayLabel;
  final String dateLabel;
  final int score;
  final LaundryStatus status;
  final String reason;
  final bool isBest;
}

const weeklyDummyData = [
  WeeklyLaundryForecast(
    dayLabel: '월',
    dateLabel: '4/20',
    score: 91,
    status: LaundryStatus.good,
    reason: '맑고 바람이 적당해서 금방 말라요',
    isBest: true,
  ),
  WeeklyLaundryForecast(
    dayLabel: '화',
    dateLabel: '4/21',
    score: 76,
    status: LaundryStatus.good,
    reason: '오전 햇볕이 좋아서 이불 빨래도 무난해요',
  ),
  WeeklyLaundryForecast(
    dayLabel: '수',
    dateLabel: '4/22',
    score: 59,
    status: LaundryStatus.normal,
    reason: '습도가 조금 높아 실내 건조 보조가 좋아요',
  ),
  WeeklyLaundryForecast(
    dayLabel: '목',
    dateLabel: '4/23',
    score: 48,
    status: LaundryStatus.normal,
    reason: '오후 구름이 늘어나고 건조 속도가 느려져요',
  ),
  WeeklyLaundryForecast(
    dayLabel: '금',
    dateLabel: '4/24',
    score: 28,
    status: LaundryStatus.bad,
    reason: '비 예보가 있어 미루는 편이 안전해요',
  ),
  WeeklyLaundryForecast(
    dayLabel: '토',
    dateLabel: '4/25',
    score: 63,
    status: LaundryStatus.normal,
    reason: '아침 시간대만 비교적 무난해요',
  ),
  WeeklyLaundryForecast(
    dayLabel: '일',
    dateLabel: '4/26',
    score: 84,
    status: LaundryStatus.good,
    reason: '건조한 공기 덕분에 말리기 좋아요',
  ),
];
