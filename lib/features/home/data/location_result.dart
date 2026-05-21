class LocationResult {
  const LocationResult({
    required this.isSuccess,
    required this.displayText,
    required this.stage,
    required this.diagnostics,
    this.latitude,
    this.longitude,
    this.errorCode,
    this.debugMessage,
    this.usedFallback = false,
  });

  factory LocationResult.loading({required String platform}) {
    return LocationResult(
      isSuccess: false,
      displayText: '현재 위치 확인 중...',
      stage: 'loading',
      diagnostics: {
        'platform': platform,
        'providerChain': '-',
      },
      debugMessage: '위치 정보를 요청하는 중입니다.',
    );
  }

  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  final String displayText;
  final String? errorCode;
  final String? debugMessage;
  final String stage;
  final bool usedFallback;
  final Map<String, String> diagnostics;
}
