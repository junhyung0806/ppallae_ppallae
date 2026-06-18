import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/error_codes.dart';
import 'models/api_models.dart';

class PpallaeApiException implements Exception {
  PpallaeApiException(
    this.message, {
    this.statusCode,
    this.code = ErrorCodes.generic,
  });

  final String message;
  final int? statusCode;
  final String code;

  @override
  String toString() =>
      '[$code] $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

class PpallaeApiClient {
  PpallaeApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _http = httpClient ?? http.Client() {
    // 디버그 빌드에서만 실제 연결 중인 API base URL을 1회 출력.
    // release 빌드에선 출력되지 않아 민감 URL 노출 없음.
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('[PpallaeApi] base=$baseUrl');
    }
  }

  /// 기본 base URL. 실기기 테스트 시 반드시 `--dart-define=PPALLAE_API_BASE_URL=http://<PC-LAN-IP>:4000/api/v1`
  /// 으로 PC LAN IP를 주입해야 한다. localhost는 Android 실기기에서 폰 자신을 가리킨다.
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
    required String laundryAmount,
  }) async {
    final uri = Uri.parse('$baseUrl/laundry-score/timeline').replace(
      queryParameters: {
        'regionCode': regionCode,
        'laundryTypeCode': laundryTypeCode,
        'dryingPlace': dryingPlace,
        'laundryAmount': laundryAmount,
      },
    );
    final json = await _getJson(uri);
    return TimelineEnvelopeModel.fromJson(json as Map<String, dynamic>);
  }

  /// 활성 공지 목록. priority desc → createdAt desc.
  Future<List<NoticeModel>> activeNotices() async {
    final uri = Uri.parse('$baseUrl/notices/active');
    final json = await _getJson(uri);
    return (json as List<dynamic>)
        .map((e) => NoticeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 공개 앱 설정 — 강제 업데이트, 점검 모드, 정책 URL, 피처 플래그.
  /// 시작 시 1회 호출, 실패 시 앱은 그대로 진행하고 정책 URL 등은 로컬 폴백 사용.
  /// docs `AppConfig_API_계약서.md` 권장 경로(`/public/app-config`) 사용.
  Future<AppConfigModel> appConfig() async {
    final uri = Uri.parse('$baseUrl/public/app-config');
    final json = await _getJson(uri);
    return AppConfigModel.fromJson(json as Map<String, dynamic>);
  }

  /// 주변 빨래방. source(mock/카카오)도 같이 반환해야 화면이 mock 여부 구분 가능.
  Future<LaundromatsEnvelopeModel> nearbyLaundromats(
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse('$baseUrl/laundromats/nearby').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng'},
    );
    final json = await _getJson(uri);
    return LaundromatsEnvelopeModel.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } on http.ClientException catch (e) {
      throw PpallaeApiException(
        '서버에 연결할 수 없어요. 백엔드/Wi-Fi/방화벽을 확인해주세요. ($e)',
        code: ErrorCodes.apiNetwork,
      );
    } catch (e) {
      // 타임아웃 등
      throw PpallaeApiException(
        '응답 시간 초과: $e',
        code: ErrorCodes.apiTimeout,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PpallaeApiException(
        '요청 실패',
        statusCode: response.statusCode,
        code: ErrorCodes.apiHttp,
      );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw PpallaeApiException(
        '응답을 해석하지 못했어요: $e',
        code: ErrorCodes.apiParse,
      );
    }
  }

  void dispose() => _http.close();
}
