import '../models/laundry_alert.dart';

abstract class NotificationService {
  Future<void> initialize();

  Future<void> syncAlerts(List<PlannedLaundryAlert> alerts);

  Future<void> cancelAllLaundryAlerts();
}

class NotificationChannelIds {
  static const bestTime = 'laundry_best_time';
  static const warnings = 'laundry_warning';
}

// flutter_local_notifications 연동 시 이 인터페이스를 구현하면 됩니다.
// 앱 로직은 NotificationService만 의존하므로 패키지 교체나 백엔드 푸시
// 도입 시에도 화면과 추천 로직을 거의 건드리지 않아도 됩니다.
