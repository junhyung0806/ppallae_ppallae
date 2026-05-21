class UserPreferenceSettings {
  const UserPreferenceSettings({
    this.prioritizeFastDrying = false,
    this.avoidRainExposure = true,
    this.useIndoorDryingMode = false,
    this.notificationsEnabled = true,
    this.bestTimeAlertsEnabled = true,
    this.rainAlertsEnabled = true,
  });

  final bool prioritizeFastDrying;
  final bool avoidRainExposure;
  final bool useIndoorDryingMode;
  final bool notificationsEnabled;
  final bool bestTimeAlertsEnabled;
  final bool rainAlertsEnabled;

  UserPreferenceSettings copyWith({
    bool? prioritizeFastDrying,
    bool? avoidRainExposure,
    bool? useIndoorDryingMode,
    bool? notificationsEnabled,
    bool? bestTimeAlertsEnabled,
    bool? rainAlertsEnabled,
  }) {
    return UserPreferenceSettings(
      prioritizeFastDrying:
          prioritizeFastDrying ?? this.prioritizeFastDrying,
      avoidRainExposure: avoidRainExposure ?? this.avoidRainExposure,
      useIndoorDryingMode:
          useIndoorDryingMode ?? this.useIndoorDryingMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      bestTimeAlertsEnabled:
          bestTimeAlertsEnabled ?? this.bestTimeAlertsEnabled,
      rainAlertsEnabled: rainAlertsEnabled ?? this.rainAlertsEnabled,
    );
  }
}
