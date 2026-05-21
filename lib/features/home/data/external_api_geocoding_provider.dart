import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/geocoding_config.dart';
import 'location_error_code.dart';
import 'reverse_geocoding_provider.dart';

class ExternalApiGeocodingProvider implements ReverseGeocodingProvider {
  ExternalApiGeocodingProvider({
    required GeocodingConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final GeocodingConfig _config;
  final http.Client _client;

  @override
  String get providerName => 'OpenStreetMapExternalGeocodingProvider';

  @override
  Future<ReverseGeocodingProviderResult> reverseGeocode({
    required double latitude,
    required double longitude,
    required Map<String, String> diagnostics,
  }) async {
    diagnostics['externalApiEnabled'] = '${_config.enabled}';
    diagnostics['externalProviderName'] = _config.providerName;

    if (!_config.enabled) {
      return const ReverseGeocodingProviderResult(
        displayText: null,
        stage: 'geocoding_failed',
        usedFallback: false,
        errorCode: LocationErrorCode.geo101,
        debugMessage: 'external geocoding provider is disabled',
      );
    }

    final uri = _buildUri(latitude: latitude, longitude: longitude);

    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'ppallae-ppallae-dev/1.0',
    };

    if (_config.authHeaderName.trim().isNotEmpty) {
      headers[_config.authHeaderName] = _config.apiKey;
    }

    try {
      final response = await _client.get(uri, headers: headers);
      diagnostics['httpStatus'] = '${response.statusCode}';
      diagnostics['rawResponseSummary'] =
          response.body.length > 180 ? response.body.substring(0, 180) : response.body;

      if (response.statusCode != 200) {
        return ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo103,
          debugMessage: 'external geocoding non-200 response',
          httpStatusCode: response.statusCode,
          rawSummary: diagnostics['rawResponseSummary'],
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo104,
          debugMessage: 'external geocoding response parse failed',
        );
      }

      final parseResult = _parseGenericResponse(decoded, diagnostics);

      if (parseResult.displayText == null) {
        return ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: parseResult.errorCode ?? LocationErrorCode.geo105,
          debugMessage:
              parseResult.debugMessage ?? 'external geocoding returned empty region',
          httpStatusCode: response.statusCode,
          rawSummary: diagnostics['rawResponseSummary'],
        );
      }

      return ReverseGeocodingProviderResult(
        displayText: parseResult.displayText,
        stage: 'geocoding_completed',
        usedFallback: false,
        httpStatusCode: response.statusCode,
        rawSummary: diagnostics['rawResponseSummary'],
      );
    } catch (error) {
      return ReverseGeocodingProviderResult(
        displayText: null,
        stage: 'geocoding_failed',
        usedFallback: false,
        errorCode: LocationErrorCode.geo102,
        debugMessage: 'external geocoding http request failed: $error',
      );
    }
  }

  Uri _buildUri({
    required double latitude,
    required double longitude,
  }) {
    return Uri.parse(_config.baseUrl).replace(
      queryParameters: {
        'lat': '$latitude',
        'lon': '$longitude',
        'format': 'jsonv2',
        'accept-language': 'ko',
      },
    );
  }

  _ParsedExternalResult _parseGenericResponse(
    Map<String, dynamic> decoded,
    Map<String, String> diagnostics,
  ) {
    final address = decoded['address'];
    if (address is! Map<String, dynamic>) {
      return const _ParsedExternalResult(
        displayText: null,
        errorCode: LocationErrorCode.geo105,
        debugMessage: 'external geocoding returned empty region',
      );
    }

    final city = _pick(address, ['state', 'province', 'region', 'city']);
    final district = _pick(address, ['city_district', 'county', 'district', 'suburb']);
    diagnostics['externalCity'] = city ?? '';
    diagnostics['externalDistrict'] = district ?? '';

    return _ParsedExternalResult(
      displayText: _composeAddress(city, district),
    );
  }

  String? _pick(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  String? _composeAddress(String? city, String? district) {
    if (city != null && district != null) {
      return '$city $district';
    }

    return city ?? district;
  }
}

class _ParsedExternalResult {
  const _ParsedExternalResult({
    required this.displayText,
    this.errorCode,
    this.debugMessage,
  });

  final String? displayText;
  final LocationErrorCode? errorCode;
  final String? debugMessage;
}
