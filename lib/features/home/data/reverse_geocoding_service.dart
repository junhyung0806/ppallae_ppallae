import 'package:flutter/foundation.dart';

import '../../../core/config/geocoding_config.dart';
import 'external_api_geocoding_provider.dart';
import 'geocoding_plugin_provider.dart';
import 'kakao_external_geocoding_provider.dart';
import 'location_error_code.dart';
import 'reverse_geocoding_provider.dart';

class ReverseGeocodingService {
  ReverseGeocodingService({
    GeocodingConfig? kakaoConfig,
    GeocodingConfig? openStreetMapConfig,
  })  : _kakaoConfig = kakaoConfig ?? GeocodingConfig.kakaoFromEnvironment(),
        _openStreetMapConfig =
            openStreetMapConfig ?? GeocodingConfig.openStreetMapFromEnvironment();

  final GeocodingConfig _kakaoConfig;
  final GeocodingConfig _openStreetMapConfig;

  Future<ReverseGeocodingProviderResult> reverseGeocode({
    required double latitude,
    required double longitude,
    required Map<String, String> diagnostics,
  }) async {
    final providers = _providerChain;
    diagnostics['providerChain'] = providers.map((e) => e.providerName).join(' -> ');
    diagnostics['externalApiEnabled'] = '${_kakaoConfig.enabled || _openStreetMapConfig.enabled}';

    ReverseGeocodingProviderResult? lastFailure;

    for (var index = 0; index < providers.length; index++) {
      final provider = providers[index];
      diagnostics['activeProvider'] = provider.providerName;
      debugPrint('[ReverseGeocodingService] trying provider=${provider.providerName}');

      if (kIsWeb && provider is GeocodingPluginProvider) {
        lastFailure = const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo106,
          debugMessage: 'web platform geocoding package unsupported',
        );
        continue;
      }

      final result = await provider.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
        diagnostics: diagnostics,
      );

      if (result.displayText != null && result.displayText!.trim().isNotEmpty) {
        debugPrint('[ReverseGeocodingService] selected provider=${provider.providerName}');
        if (index > 0) {
          diagnostics['providerFallbackSucceeded'] = 'true';
          diagnostics['activeProvider'] = provider.providerName;
          return ReverseGeocodingProviderResult(
            displayText: result.displayText,
            stage: result.stage,
            usedFallback: result.usedFallback,
            errorCode: LocationErrorCode.geo107,
            debugMessage: 'provider fallback succeeded',
            httpStatusCode: result.httpStatusCode,
            rawSummary: result.rawSummary,
          );
        }

        return result;
      }

      lastFailure = result;
    }

    return ReverseGeocodingProviderResult(
      displayText: null,
      stage: 'fallback_used',
      usedFallback: true,
      errorCode: LocationErrorCode.geo108,
      debugMessage: lastFailure?.debugMessage ?? 'all reverse geocoding providers failed',
      httpStatusCode: lastFailure?.httpStatusCode,
      rawSummary: lastFailure?.rawSummary,
    );
  }

  List<ReverseGeocodingProvider> get _providerChain {
    final plugin = GeocodingPluginProvider();
    final kakao = KakaoExternalGeocodingProvider(config: _kakaoConfig);
    final openStreetMap =
        ExternalApiGeocodingProvider(config: _openStreetMapConfig);

    if (kIsWeb) {
      return [kakao, openStreetMap];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return [plugin];
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return [plugin, kakao, openStreetMap];
      case TargetPlatform.fuchsia:
        return [kakao, openStreetMap];
    }
  }
}
