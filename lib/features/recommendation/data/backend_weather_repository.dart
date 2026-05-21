import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/weather_api_config.dart';
import '../models/saved_location.dart';
import '../models/weather_snapshot.dart';
import '../services/repositories.dart';

class BackendWeatherRepository implements WeatherRepository {
  BackendWeatherRepository({
    required BackendWeatherApiConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final BackendWeatherApiConfig _config;
  final http.Client _client;
  final Map<String, _CachedWeatherEntry> _cache = {};

  @override
  Future<WeatherBundle> fetchWeather(WeatherRequestContext context) async {
    if (!_config.enabled) {
      throw const BackendWeatherException(
        code: 'BACKEND-001',
        stage: 'config_check',
        message: '외부 날씨 백엔드가 비활성화 상태입니다.',
      );
    }
    if (!_config.hasBaseUrl) {
      throw const BackendWeatherException(
        code: 'BACKEND-001',
        stage: 'config_check',
        message: '외부 날씨 백엔드 URL이 설정되지 않았습니다.',
      );
    }

    final cached = _cache[context.cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < const Duration(minutes: 10)) {
      return cached.bundle;
    }

    final location = _locationFor(context);
    final diagnostics = <String, String>{
      'provider': _config.providerName,
      'selectionLabel': context.selectionLabel,
      'sourceType': context.sourceType.name,
      'runtimePlatform': 'backend_proxy',
      'requestTarget': 'backend',
      'requestName': 'weather',
      'backendConfigured': '${_config.hasBaseUrl}',
      'backendApiKeyConfigured': '${_config.hasApiKey}',
      'requestTimeoutSeconds': '${_config.requestTimeoutSeconds}',
      'backendHost': Uri.tryParse(_config.baseUrl)?.host ?? '-',
      'latitude': location.latitude.toStringAsFixed(5),
      'longitude': location.longitude.toStringAsFixed(5),
    };

    Uri uri;
    try {
      uri = Uri.parse(_config.baseUrl).replace(
        queryParameters: {
          'lat': location.latitude.toString(),
          'lng': location.longitude.toString(),
          'sourceType': context.sourceType.name,
          'label': context.selectionLabel,
        },
      );
      diagnostics['backendRequest'] = uri.replace(
        queryParameters: {
          'lat': location.latitude.toString(),
          'lng': location.longitude.toString(),
          'sourceType': context.sourceType.name,
          'label': context.selectionLabel,
        },
      ).toString();
    } catch (error) {
      throw BackendWeatherException(
        code: 'BACKEND-002',
        stage: 'request_build',
        message: '외부 날씨 백엔드 요청 URL 생성에 실패했습니다.',
        debugMessage: '$error',
      ).withMergedDetails(diagnostics);
    }

    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (_config.hasApiKey) {
      headers['x-api-key'] = _config.apiKey;
    }

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: _config.requestTimeoutSeconds), onTimeout: () {
        throw BackendWeatherException(
          code: 'BACKEND-003',
          stage: 'http_timeout',
          message:
              '외부 날씨 백엔드 응답 시간이 ${_config.requestTimeoutSeconds}초를 초과했습니다.',
        );
      });
    } on WeatherRepositoryException catch (error) {
      throw error.withMergedDetails(diagnostics);
    } catch (error) {
      throw BackendWeatherException(
        code: 'BACKEND-003',
        stage: 'http_request',
        message: '외부 날씨 백엔드 요청에 실패했습니다.',
        debugMessage: '$error',
        details: {
          'requestMethod': 'GET',
          'requestRuntime': 'browser_to_backend',
        },
      ).withMergedDetails(diagnostics);
    }

    diagnostics['backendStatus'] = '${response.statusCode}';
    diagnostics['requestRuntime'] = 'browser_to_backend';
    diagnostics['backendBodyPreview'] =
        response.body.length > 180 ? response.body.substring(0, 180) : response.body;

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw BackendWeatherException(
        code: 'BACKEND-004',
        stage: 'http_auth',
        message: '외부 날씨 백엔드 인증 또는 접근 권한이 거부되었습니다.',
        debugMessage: 'HTTP ${response.statusCode}',
      ).withMergedDetails(diagnostics);
    }

    if (response.statusCode >= 500) {
      throw BackendWeatherException(
        code: 'BACKEND-005',
        stage: 'http_server_error',
        message: '외부 날씨 백엔드 서버 오류가 발생했습니다.',
        debugMessage: 'HTTP ${response.statusCode}',
      ).withMergedDetails(diagnostics);
    }

    if (response.statusCode != 200) {
      throw BackendWeatherException(
        code: 'BACKEND-005',
        stage: 'http_response',
        message: '외부 날씨 백엔드가 200이 아닌 상태코드를 반환했습니다.',
        debugMessage: 'HTTP ${response.statusCode}',
      ).withMergedDetails(diagnostics);
    }

    late final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      throw BackendWeatherException(
        code: 'BACKEND-006',
        stage: 'response_parse',
        message: '외부 날씨 백엔드 응답 파싱에 실패했습니다.',
        debugMessage: '$error',
      ).withMergedDetails(diagnostics);
    }

    try {
      final currentNode = Map<String, dynamic>.from(
        decoded['current'] as Map,
      );
      final hourlyNode = decoded['hourly'] as List<dynamic>? ?? const [];
      final metaNode = decoded['meta'] is Map
          ? Map<String, dynamic>.from(decoded['meta'] as Map)
          : <String, dynamic>{};

      final current = _parseSnapshot(currentNode);
      final hourly = hourlyNode
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .map(_parseHourlyForecast)
          .toList();

      final details = <String, String>{
        ...diagnostics,
        'backendMetaSource': '${metaNode['source'] ?? _config.providerName}',
        'backendMetaStage': '${metaNode['stage'] ?? 'backend_success'}',
        if (metaNode['provider'] != null) 'backendMetaProvider': '${metaNode['provider']}',
        if (metaNode['traceId'] != null) 'backendTraceId': '${metaNode['traceId']}',
        if (metaNode['debug'] != null) 'backendDebug': '${metaNode['debug']}',
      };

      final bundle = WeatherBundle(
        current: current,
        hourly: hourly.take(5).toList(),
        meta: WeatherFetchMeta.success(
          source: '${metaNode['source'] ?? 'backend'}',
          stage: '${metaNode['stage'] ?? 'backend_success'}',
          userMessage: '${metaNode['userMessage'] ?? '외부 날씨 백엔드 데이터로 추천을 표시 중입니다.'}',
          details: details,
        ),
      );
      _cache[context.cacheKey] = _CachedWeatherEntry(
        bundle: bundle,
        fetchedAt: DateTime.now(),
      );
      return bundle;
    } catch (error) {
      if (error is WeatherRepositoryException) {
        rethrow;
      }
      throw BackendWeatherException(
        code: 'BACKEND-007',
        stage: 'payload_validate',
        message: '외부 날씨 백엔드 응답 형식이 앱 계약과 다릅니다.',
        debugMessage: '$error',
      ).withMergedDetails(diagnostics);
    }
  }

  _BackendLocation _locationFor(WeatherRequestContext context) {
    if (context.latitude != null && context.longitude != null) {
      return _BackendLocation(
        latitude: context.latitude!,
        longitude: context.longitude!,
      );
    }

    switch (context.sourceType) {
      case LocationSourceType.current:
        return const _BackendLocation(latitude: 37.3417, longitude: 127.1112);
      case LocationSourceType.search:
      case LocationSourceType.saved:
        return const _BackendLocation(latitude: 37.5665, longitude: 126.9780);
    }
  }

  HourlyWeatherForecast _parseHourlyForecast(Map<String, dynamic> node) {
    final at = DateTime.tryParse('${node['at'] ?? ''}');
    if (at == null) {
      throw const BackendWeatherException(
        code: 'BACKEND-007',
        stage: 'payload_validate',
        message: '외부 날씨 백엔드 시간대 예보의 at 값이 유효하지 않습니다.',
      );
    }
    final weatherNode = Map<String, dynamic>.from(node['weather'] as Map);
    return HourlyWeatherForecast(
      at: at,
      weather: _parseSnapshot(weatherNode),
    );
  }

  WeatherSnapshot _parseSnapshot(Map<String, dynamic> node) {
    return WeatherSnapshot(
      temperatureCelsius: _asDouble(node['temperatureCelsius']),
      humidity: _asInt(node['humidity']),
      windSpeedMps: _asDouble(node['windSpeedMps']),
      skyCondition: _parseSkyCondition('${node['skyCondition'] ?? ''}'),
      rainProbability: _asInt(node['rainProbability']),
    );
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse('$value');
    if (parsed == null) {
      throw BackendWeatherException(
        code: 'BACKEND-007',
        stage: 'payload_validate',
        message: '외부 날씨 백엔드 숫자 필드 파싱에 실패했습니다.',
        debugMessage: 'value=$value',
      );
    }
    return parsed;
  }

  int _asInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    final parsed = int.tryParse('$value');
    if (parsed == null) {
      throw BackendWeatherException(
        code: 'BACKEND-007',
        stage: 'payload_validate',
        message: '외부 날씨 백엔드 정수 필드 파싱에 실패했습니다.',
        debugMessage: 'value=$value',
      );
    }
    return parsed;
  }

  SkyCondition _parseSkyCondition(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'sunny':
      case 'clear':
      case '맑음':
        return SkyCondition.sunny;
      case 'partlycloudy':
      case 'partly_cloudy':
      case 'partly-cloudy':
      case '구름 조금':
        return SkyCondition.partlyCloudy;
      case 'cloudy':
      case 'overcast':
      case '흐림':
        return SkyCondition.cloudy;
      case 'rain':
      case 'rainy':
      case '비':
        return SkyCondition.rainy;
      default:
        throw BackendWeatherException(
          code: 'BACKEND-007',
          stage: 'payload_validate',
          message: '외부 날씨 백엔드 skyCondition 값이 앱 계약과 다릅니다.',
          debugMessage: raw,
        );
    }
  }
}

class BackendWeatherException extends WeatherRepositoryException {
  const BackendWeatherException({
    required this.code,
    required this.stage,
    required this.message,
    this.debugMessage,
    this.details = const <String, String>{},
  }) : super(
          code: code,
          stage: stage,
          message: message,
          debugMessage: debugMessage,
          details: details,
        );

  @override
  final String code;

  @override
  final String stage;

  @override
  final String message;

  @override
  final String? debugMessage;

  @override
  final Map<String, String> details;

  @override
  BackendWeatherException withMergedDetails(Map<String, String> nextDetails) {
    return BackendWeatherException(
      code: code,
      stage: stage,
      message: message,
      debugMessage: debugMessage,
      details: {
        ...nextDetails,
        ...details,
      },
    );
  }
}

class _BackendLocation {
  const _BackendLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class _CachedWeatherEntry {
  const _CachedWeatherEntry({
    required this.bundle,
    required this.fetchedAt,
  });

  final WeatherBundle bundle;
  final DateTime fetchedAt;
}
