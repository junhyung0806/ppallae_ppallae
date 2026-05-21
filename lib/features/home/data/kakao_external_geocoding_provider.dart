import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/geocoding_config.dart';
import 'location_error_code.dart';
import 'reverse_geocoding_provider.dart';

class KakaoExternalGeocodingProvider implements ReverseGeocodingProvider {
  KakaoExternalGeocodingProvider({
    required GeocodingConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final GeocodingConfig _config;
  final http.Client _client;

  @override
  String get providerName => 'KakaoExternalGeocodingProvider';

  @override
  Future<ReverseGeocodingProviderResult> reverseGeocode({
    required double latitude,
    required double longitude,
    required Map<String, String> diagnostics,
  }) async {
    diagnostics['kakaoAttempted'] = 'true';
    diagnostics['externalApiEnabled'] = '${_config.enabled}';
    diagnostics['externalProviderName'] = _config.providerName;
    diagnostics['kakaoApiKeyPresent'] = '${_config.hasApiKey}';
    diagnostics['kakaoAuthHeaderName'] = _config.authHeaderName;

    if (!_config.enabled || !_config.hasApiKey) {
      diagnostics['kakaoStatusCode'] = '';
      diagnostics['kakaoErrorMessage'] = 'Kakao REST API key is missing';
      diagnostics['kakaoResponsePreview'] = '';
      debugPrint(
        '[KakaoExternalGeocodingProvider] config provider=${_config.providerName} '
        'enabled=${_config.enabled} apiKeyPresent=${_config.hasApiKey} '
        'authHeaderName=${_config.authHeaderName}',
      );
      return const ReverseGeocodingProviderResult(
        displayText: null,
        stage: 'geocoding_failed',
        usedFallback: false,
        errorCode: LocationErrorCode.geo101,
        debugMessage: 'Kakao REST API key is missing',
      );
    }

    final uri = Uri.parse(_config.baseUrl).replace(
      queryParameters: {
        'x': '$longitude',
        'y': '$latitude',
      },
    );
    diagnostics['kakaoRequestUrl'] = uri.toString();
    diagnostics['kakaoQueryParams'] = 'x=$longitude, y=$latitude';

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'KakaoAK ${_config.apiKey}',
    };
    final maskedAuthHeader = 'KakaoAK ****';
    diagnostics['kakaoAuthHeaderPreview'] = maskedAuthHeader;

    debugPrint(
      '[KakaoExternalGeocodingProvider] config provider=${_config.providerName} '
      'enabled=${_config.enabled} apiKeyPresent=${_config.hasApiKey} '
      'authHeaderName=${_config.authHeaderName}',
    );
    debugPrint('[KakaoExternalGeocodingProvider] requestUrl=$uri');
    debugPrint(
      '[KakaoExternalGeocodingProvider] queryParams=x=$longitude, y=$latitude',
    );
    debugPrint(
      '[KakaoExternalGeocodingProvider] headerName=${_config.authHeaderName}',
    );
    debugPrint(
      '[KakaoExternalGeocodingProvider] Authorization: $maskedAuthHeader',
    );

    try {
      final response = await _client.get(uri, headers: headers);
      diagnostics['httpStatus'] = '${response.statusCode}';
      diagnostics['kakaoStatusCode'] = '${response.statusCode}';
      diagnostics['rawResponseSummary'] = response.body.length > 180
          ? response.body.substring(0, 180)
          : response.body;
      diagnostics['kakaoResponsePreview'] = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;

      debugPrint(
        '[KakaoExternalGeocodingProvider] responseStatusCode=${response.statusCode}',
      );
      debugPrint(
        '[KakaoExternalGeocodingProvider] responseBodyPreview=${diagnostics['kakaoResponsePreview']}',
      );

      if (response.statusCode != 200) {
        diagnostics['kakaoErrorMessage'] =
            'Kakao Local API returned ${response.statusCode}. Local API 사용 권한 또는 키를 확인해주세요.';
        return ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo103,
          debugMessage:
              'Kakao Local API returned ${response.statusCode}. Local API 사용 권한 또는 키를 확인해주세요.',
          httpStatusCode: response.statusCode,
          rawSummary: diagnostics['rawResponseSummary'],
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        diagnostics['kakaoErrorMessage'] = 'Kakao response parse failed';
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo104,
          debugMessage: 'Kakao response parse failed',
        );
      }

      final documents = decoded['documents'];
      if (documents is! List || documents.isEmpty) {
        diagnostics['kakaoErrorMessage'] =
            'Kakao coord2regioncode returned empty documents';
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo105,
          debugMessage: 'Kakao coord2regioncode returned empty documents',
        );
      }

      final typedDocs = documents.whereType<Map<String, dynamic>>().toList();
      final hasBRegion =
          typedDocs.any((doc) => _readString(doc['region_type']) == 'B');
      diagnostics['whetherBRegionFound'] = '$hasBRegion';

      final bRegion = typedDocs.cast<Map<String, dynamic>?>().firstWhere(
            (doc) => _readString(doc?['region_type']) == 'B',
            orElse: () => null,
          );
      final hRegion = typedDocs.cast<Map<String, dynamic>?>().firstWhere(
            (doc) => _readString(doc?['region_type']) == 'H',
            orElse: () => null,
          );

      final selected = bRegion ?? hRegion;
      if (selected == null) {
        diagnostics['kakaoErrorMessage'] =
            'Kakao region documents had no usable B/H region';
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo105,
          debugMessage: 'Kakao region documents had no usable B/H region',
        );
      }

      final region1 = _normalizeText(_readString(selected['region_1depth_name']));
      final region2 = _normalizeText(_readString(selected['region_2depth_name']));
      final region3 = _normalizeText(_readString(selected['region_3depth_name']));
      final regionType = _normalizeText(_readString(selected['region_type']));

      diagnostics['selectedRegionType'] = regionType ?? '';
      diagnostics['selectedRegion3Depth'] = region3 ?? '';
      diagnostics['externalCity'] = region1 ?? '';
      diagnostics['externalDistrict'] = region2 ?? '';
      diagnostics['kakaoErrorMessage'] = '';

      final displayText = _joinNonEmpty([region1, region2, region3]);
      if (displayText == null) {
        diagnostics['kakaoErrorMessage'] =
            'Kakao selected region did not contain usable names';
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo105,
          debugMessage: 'Kakao selected region did not contain usable names',
        );
      }

      return ReverseGeocodingProviderResult(
        displayText: displayText,
        stage: 'geocoding_completed',
        usedFallback: false,
        httpStatusCode: response.statusCode,
        rawSummary:
            'type=$regionType region1=$region1 region2=$region2 region3=$region3',
      );
    } catch (error) {
      diagnostics['kakaoStatusCode'] = '';
      diagnostics['kakaoErrorMessage'] =
          'Kakao external geocoding request failed: $error';
      diagnostics['kakaoResponsePreview'] = '';
      debugPrint(
        '[KakaoExternalGeocodingProvider] exception=$error',
      );
      return ReverseGeocodingProviderResult(
        displayText: null,
        stage: 'geocoding_failed',
        usedFallback: false,
        errorCode: LocationErrorCode.geo102,
        debugMessage: 'Kakao external geocoding request failed: $error',
      );
    }
  }

  String? _joinNonEmpty(List<String?> parts) {
    final normalized = <String>[];

    for (final part in parts) {
      final trimmed = _normalizeText(part);
      if (trimmed != null && !normalized.contains(trimmed)) {
        normalized.add(trimmed);
      }
    }

    if (normalized.isEmpty) {
      return null;
    }

    return normalized.join(' ');
  }

  String? _normalizeText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String? _readString(Object? value) {
    return value is String ? value : null;
  }
}
