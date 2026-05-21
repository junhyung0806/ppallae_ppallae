enum LaundryAlertType {
  bestTime,
  rainWarning,
  humiditySurge,
}

class PlannedLaundryAlert {
  const PlannedLaundryAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });

  final String id;
  final LaundryAlertType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final Map<String, String> payload;
}
