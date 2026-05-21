class WebMapDiagnostic {
  const WebMapDiagnostic({
    required this.stage,
    required this.message,
    required this.details,
    this.code,
    this.isReady = false,
  });

  factory WebMapDiagnostic.initial() {
    return const WebMapDiagnostic(
      stage: 'idle',
      message: '웹 지도 초기화 대기 중',
      details: {},
    );
  }

  final String stage;
  final String message;
  final Map<String, String> details;
  final String? code;
  final bool isReady;
}
