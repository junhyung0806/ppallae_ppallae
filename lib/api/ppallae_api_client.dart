import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/api_models.dart';

class PpallaeApiException implements Exception {
  PpallaeApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'PpallaeApiException($statusCode): $message';
}

class PpallaeApiClient {
  PpallaeApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _http = httpClient ?? http.Client();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'PPALLAE_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );

  final String baseUrl;
  final http.Client _http;

  Future<List<RegionModel>> searchRegions(String keyword) async {
    final uri = Uri.parse('$baseUrl/regions/search')
        .replace(queryParameters: {'keyword': keyword});
    final json = await _getJson(uri);
    return (json as List<dynamic>)
        .map((e) => RegionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RegionModel> currentRegion(double lat, double lng) async {
    final uri = Uri.parse('$baseUrl/regions/current').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng'},
    );
    final json = await _getJson(uri);
    return RegionModel.fromJson(json as Map<String, dynamic>);
  }

  Future<List<LaundryTypeModel>> laundryTypes() async {
    final uri = Uri.parse('$baseUrl/laundry-types');
    final json = await _getJson(uri);
    return (json as List<dynamic>)
        .map((e) => LaundryTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScoreEnvelopeModel> currentScore({
    required String regionCode,
    required String laundryTypeCode,
    required String dryingPlace,
    required String laundryAmount,
  }) async {
    final uri = Uri.parse('$baseUrl/laundry-score/current').replace(
      queryParameters: {
        'regionCode': regionCode,
        'laundryTypeCode': laundryTypeCode,
        'dryingPlace': dryingPlace,
        'laundryAmount': laundryAmount,
      },
    );
    final json = await _getJson(uri);
    return ScoreEnvelopeModel.fromJson(json as Map<String, dynamic>);
  }

  Future<TimelineEnvelopeModel> timeline({
    required String regionCode,
    required String laundryTypeCode,
    required String dryingPlace,
  }) async {
    final uri = Uri.parse('$baseUrl/laundry-score/timeline').replace(
      queryParameters: {
        'regionCode': regionCode,
        'laundryTypeCode': laundryTypeCode,
        'dryingPlace': dryingPlace,
      },
    );
    final json = await _getJson(uri);
    return TimelineEnvelopeModel.fromJson(json as Map<String, dynamic>);
  }

  Future<List<LaundromatModel>> nearbyLaundromats(
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse('$baseUrl/laundromats/nearby').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng'},
    );
    final json = await _getJson(uri);
    final items = (json as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((e) => LaundromatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw PpallaeApiException('네트워크 오류: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PpallaeApiException(
        '요청 실패 (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void dispose() => _http.close();
}
