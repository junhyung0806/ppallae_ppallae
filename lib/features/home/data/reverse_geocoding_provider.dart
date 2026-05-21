import 'location_error_code.dart';

abstract class ReverseGeocodingProvider {
  String get providerName;

  Future<ReverseGeocodingProviderResult> reverseGeocode({
    required double latitude,
    required double longitude,
    required Map<String, String> diagnostics,
  });
}

class ReverseGeocodingProviderResult {
  const ReverseGeocodingProviderResult({
    required this.displayText,
    required this.stage,
    required this.usedFallback,
    this.errorCode,
    this.debugMessage,
    this.httpStatusCode,
    this.rawSummary,
  });

  final String? displayText;
  final String stage;
  final bool usedFallback;
  final LocationErrorCode? errorCode;
  final String? debugMessage;
  final int? httpStatusCode;
  final String? rawSummary;
}
