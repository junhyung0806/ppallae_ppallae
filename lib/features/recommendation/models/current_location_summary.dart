class CurrentLocationSummary {
  const CurrentLocationSummary({
    required this.displayText,
    this.latitude,
    this.longitude,
    this.errorCode,
  });

  final String displayText;
  final double? latitude;
  final double? longitude;
  final String? errorCode;
}
