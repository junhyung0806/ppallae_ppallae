import '../../../core/models/laundry_status.dart';

class HomeSummary {
  const HomeSummary({
    required this.location,
    required this.status,
    required this.recommendation,
    required this.humidity,
    required this.rainChance,
    required this.dryingHours,
    required this.hourlySlots,
    this.errorCode,
  });

  final String location;
  final LaundryStatus status;
  final String recommendation;
  final int humidity;
  final int rainChance;
  final String dryingHours;
  final List<HourlyLaundrySlot> hourlySlots;
  final String? errorCode;
}

class HourlyLaundrySlot {
  const HourlyLaundrySlot({
    required this.timeLabel,
    required this.status,
    required this.message,
  });

  final String timeLabel;
  final LaundryStatus status;
  final String message;
}

const homeDummyData = HomeSummary(
  location: '서울시 성동구 성수동',
  status: LaundryStatus.good,
  recommendation: '지금 빨래 시작해도 괜찮아요',
  humidity: 46,
  rainChance: 10,
  dryingHours: '4시간',
  errorCode: null,
  hourlySlots: [
    HourlyLaundrySlot(
      timeLabel: '지금',
      status: LaundryStatus.good,
      message: '햇볕 좋고 습도 낮아요',
    ),
    HourlyLaundrySlot(
      timeLabel: '13:00',
      status: LaundryStatus.good,
      message: '건조 속도 가장 빨라요',
    ),
    HourlyLaundrySlot(
      timeLabel: '16:00',
      status: LaundryStatus.normal,
      message: '구름이 조금 늘어나요',
    ),
    HourlyLaundrySlot(
      timeLabel: '19:00',
      status: LaundryStatus.normal,
      message: '실내 건조 병행 추천',
    ),
    HourlyLaundrySlot(
      timeLabel: '22:00',
      status: LaundryStatus.bad,
      message: '밤사이 습도가 올라가요',
    ),
  ],
);
