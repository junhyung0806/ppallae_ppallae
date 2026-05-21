import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/weather_api_config.dart';
import '../models/saved_location.dart';
import '../models/weather_snapshot.dart';
import '../services/repositories.dart';
import 'kma_grid_converter.dart';

class KmaWeatherRepository implements WeatherRepository {
  KmaWeatherRepository({
    required KmaWeatherApiConfig config,
    http.Client? client,
    KmaGridConverter? gridConverter,
  })  : _config = config,
        _client = client ?? http.Client(),
        _gridConverter = gridConverter ?? const KmaGridConverter();

  final KmaWeatherApiConfig _config;
  final http.Client _client;
  final KmaGridConverter _gridConverter;
  final Map<String, _CachedWeatherEntry> _cache = {};

  @override
  Future<WeatherBundle> fetchWeather(WeatherRequestContext context) async {
    if (!_config.enabled || !_config.hasAuthKey) {
      throw const KmaWeatherException(
        code: 'KMA-001',
        stage: 'config_check',
        message: '기상청 인증키가 없거나 비활성화 상태입니다.',
      );
    }

    final cached = _cache[context.cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <
            const Duration(minutes: 10)) {
      return cached.bundle;
    }

    final diagnostics = <String, String>{
      'provider': _config.providerName,
      'selectionLabel': context.selectionLabel,
      'sourceType': context.sourceType.name,
      'runtimePlatform': kIsWeb ? 'web' : 'native',
      'requestTarget': 'kma',
      'forecastStrategy': 'ultra_fcst_then_village_fcst',
      'authConfigured': '${_config.hasAuthKey}',
      'requestTimeoutSeconds': '${_config.requestTimeoutSeconds}',
      'ultraNcstHost': Uri.tryParse(_config.ultraSrtNcstUrl)?.host ?? '-',
      'ultraFcstHost': Uri.tryParse(_config.ultraSrtFcstUrl)?.host ?? '-',
      'villageFcstHost': Uri.tryParse(_config.vilageFcstUrl)?.host ?? '-',
    };

    try {
      final location = _locationFor(context);
      late final KmaGridPoint grid;
      try {
        grid = _gridConverter.fromLatLng(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (error) {
        throw KmaWeatherException(
          code: 'KMA-007',
          stage: 'grid_convert',
          message: '격자 좌표 변환에 실패했습니다.',
          debugMessage: '$error',
        );
      }

      diagnostics['latitude'] = location.latitude.toStringAsFixed(5);
      diagnostics['longitude'] = location.longitude.toStringAsFixed(5);
      diagnostics['nx'] = '${grid.nx}';
      diagnostics['ny'] = '${grid.ny}';

      final now = DateTime.now();
      final ncstBase = _latestUltraSrtNcstBase(now);
      final ultraBase = _latestUltraSrtFcstBase(now);
      diagnostics['ncstBaseDate'] = _formatDate(ncstBase);
      diagnostics['ncstBaseTime'] = _formatTime(ncstBase);
      diagnostics['ultraBaseDate'] = _formatDate(ultraBase);
      diagnostics['ultraBaseTime'] = _formatTime(ultraBase);

      final currentItems = await _fetchCurrentItems(
        base: ncstBase,
        grid: grid,
        diagnostics: diagnostics,
      );
      final forecastResponse = await _fetchForecastItems(
        now: now,
        grid: grid,
        ultraBase: ultraBase,
        diagnostics: diagnostics,
      );
      final forecastItems = forecastResponse.items;
      diagnostics['forecastEndpointUsed'] = forecastResponse.requestName;

      diagnostics['currentItemCount'] = '${currentItems.length}';
      diagnostics['forecastItemCount'] = '${forecastItems.length}';

      final hourly = _buildHourlyForecasts(
        forecastItems,
        now: now,
        diagnostics: diagnostics,
        source: forecastResponse.source,
      );

      if (hourly.isEmpty) {
        throw const KmaWeatherException(
          code: 'KMA-006',
          stage: 'forecast_categories',
          message: '초단기예보에서 사용할 필수 카테고리를 찾지 못했습니다.',
        );
      }

      final current = _buildCurrentSnapshot(
        currentItems: currentItems,
        fallbackForecast: hourly.first.weather,
        diagnostics: diagnostics,
      );

      final bundle = WeatherBundle(
        current: current,
        hourly: hourly.take(5).toList(),
        meta: WeatherFetchMeta.success(
          source: 'KMA',
          stage: 'kma_success',
          userMessage: '기상청 실시간 데이터로 추천을 표시 중입니다.',
          details: diagnostics,
        ),
      );
      _cache[context.cacheKey] = _CachedWeatherEntry(
        bundle: bundle,
        fetchedAt: DateTime.now(),
      );
      return bundle;
    } on WeatherRepositoryException catch (error) {
      throw error.withMergedDetails(diagnostics);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItems({
    required String requestName,
    required String url,
    required Map<String, String> query,
    required Map<String, String> diagnostics,
  }) async {
    final safeQuery = Map<String, String>.from(query);
    safeQuery['authKey'] = '****';
    diagnostics['${requestName}Request'] =
        Uri.parse(url).replace(queryParameters: safeQuery).toString();
    debugPrint('[KMA][$requestName] request=${diagnostics['${requestName}Request']}');

    Uri uri;
    try {
      uri = Uri.parse(url).replace(queryParameters: query);
    } catch (error) {
      throw KmaWeatherException(
        code: 'KMA-002',
        stage: '${requestName}_request_build',
        message: '기상청 요청 URL 생성에 실패했습니다.',
        debugMessage: '$error',
      );
    }

    http.Response response;
    try {
      response = await _client
          .get(uri)
          .timeout(Duration(seconds: _config.requestTimeoutSeconds), onTimeout: () {
        throw KmaWeatherException(
          code: 'KMA-003',
          stage: '${requestName}_http_timeout',
          message:
              '기상청 API 응답 시간이 ${_config.requestTimeoutSeconds}초를 초과했습니다.',
        );
      });
    } on KmaWeatherException {
      rethrow;
    } catch (error) {
      final errorText = '$error';
      final browserBlocked = kIsWeb && _looksLikeBrowserFetchFailure(errorText);
      throw KmaWeatherException(
        code: browserBlocked ? 'KMA-009' : 'KMA-003',
        stage: browserBlocked
            ? '${requestName}_browser_fetch_blocked'
            : '${requestName}_http_request',
        message: browserBlocked
            ? '웹 브라우저에서 기상청 API 직접 호출이 차단되었습니다. 프록시 또는 백엔드 경유가 필요합니다.'
            : '기상청 HTTP 요청에 실패했습니다.',
        debugMessage: errorText,
        details: {
          'requestName': requestName,
          'requestMethod': 'GET',
          'requestRuntime': kIsWeb ? 'browser_fetch' : 'dart_http',
          'browserDirectCall': '${kIsWeb}',
        },
      );
    }

    diagnostics['${requestName}Status'] = '${response.statusCode}';
    diagnostics['${requestName}BodyPreview'] =
        response.body.length > 180 ? response.body.substring(0, 180) : response.body;
    debugPrint(
      '[KMA][$requestName] status=${response.statusCode} bodyPreview=${diagnostics['${requestName}BodyPreview']}',
    );

    if (response.statusCode != 200) {
      throw KmaWeatherException(
        code: 'KMA-004',
        stage: '${requestName}_http_response',
        message: '기상청 API가 200이 아닌 상태코드를 반환했습니다.',
        debugMessage: 'HTTP ${response.statusCode}',
      );
    }

    late final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      throw KmaWeatherException(
        code: 'KMA-005',
        stage: '${requestName}_response_parse',
        message: '기상청 응답 파싱에 실패했습니다.',
        debugMessage: '$error',
      );
    }

    final responseNode = decoded['response'] as Map<String, dynamic>?;
    final headerNode = responseNode?['header'] as Map<String, dynamic>?;
    final resultCode = '${headerNode?['resultCode'] ?? ''}';
    diagnostics['${requestName}ResultCode'] = resultCode;
    diagnostics['${requestName}ResultMsg'] =
        '${headerNode?['resultMsg'] ?? ''}';

    if (resultCode.isNotEmpty && resultCode != '00') {
      final resultMessage = '${headerNode?['resultMsg'] ?? 'unknown'}';
      final authRejected = _looksLikeAuthFailure(resultCode, resultMessage);
      throw KmaWeatherException(
        code: authRejected ? 'KMA-010' : 'KMA-005',
        stage: '${requestName}_response_header',
        message: authRejected
            ? '기상청 API 인증 또는 접근 권한이 거부되었습니다.'
            : '기상청 API가 오류 응답을 반환했습니다.',
        debugMessage: resultMessage,
        details: {
          'requestName': requestName,
          'resultCode': resultCode,
          'resultMessage': resultMessage,
        },
      );
    }

    final bodyNode = responseNode?['body'] as Map<String, dynamic>?;
    final itemsNode = bodyNode?['items'] as Map<String, dynamic>?;
    final rawItems = itemsNode?['item'];

    if (rawItems is List) {
      return rawItems.whereType<Map>().map((item) {
        return item.map((key, value) => MapEntry('$key', value));
      }).toList();
    }

    if (rawItems is Map) {
      return [rawItems.map((key, value) => MapEntry('$key', value))];
    }

    throw const KmaWeatherException(
      code: 'KMA-006',
      stage: 'response_items_missing',
      message: '응답에 items 데이터가 없습니다.',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentItems({
    required DateTime base,
    required KmaGridPoint grid,
    required Map<String, String> diagnostics,
  }) async {
    try {
      final items = await _fetchItems(
        requestName: 'ultra_ncst',
        url: _config.ultraSrtNcstUrl,
        query: {
          'pageNo': '1',
          'numOfRows': '100',
          'dataType': 'JSON',
          'base_date': _formatDate(base),
          'base_time': _formatTime(base),
          'nx': '${grid.nx}',
          'ny': '${grid.ny}',
          'authKey': _config.authKey,
        },
        diagnostics: diagnostics,
      );
      diagnostics['ultra_ncstOutcome'] = 'success';
      return items;
    } on WeatherRepositoryException catch (error) {
      diagnostics['ultra_ncstOutcome'] = 'failed';
      diagnostics['ultra_ncstErrorCode'] = error.code;
      diagnostics['ultra_ncstErrorStage'] = error.stage;
      throw error;
    }
  }

  Future<_ForecastFetchResponse> _fetchForecastItems({
    required DateTime now,
    required KmaGridPoint grid,
    required DateTime ultraBase,
    required Map<String, String> diagnostics,
  }) async {
    try {
      final items = await _fetchItems(
        requestName: 'ultra_fcst',
        url: _config.ultraSrtFcstUrl,
        query: {
          'pageNo': '1',
          'numOfRows': '120',
          'dataType': 'JSON',
          'base_date': _formatDate(ultraBase),
          'base_time': _formatTime(ultraBase),
          'nx': '${grid.nx}',
          'ny': '${grid.ny}',
          'authKey': _config.authKey,
        },
        diagnostics: diagnostics,
      );
      diagnostics['ultra_fcstOutcome'] = 'success';
      diagnostics['forecastRequestSummary'] = 'ultra_ncst 성공 / ultra_fcst 성공';
      return _ForecastFetchResponse(
        requestName: 'ultra_fcst',
        source: _ForecastSource.ultraShort,
        items: items,
      );
    } on WeatherRepositoryException catch (ultraError) {
      diagnostics['ultra_fcstOutcome'] = 'failed';
      diagnostics['ultra_fcstErrorCode'] = ultraError.code;
      diagnostics['ultra_fcstErrorStage'] = ultraError.stage;
      if ((ultraError.debugMessage ?? '').isNotEmpty) {
        diagnostics['ultra_fcstDebug'] = ultraError.debugMessage!;
      }

      final villageBase = _latestVilageFcstBase(now);
      diagnostics['villageBaseDate'] = _formatDate(villageBase);
      diagnostics['villageBaseTime'] = _formatTime(villageBase);

      try {
        final items = await _fetchItems(
          requestName: 'village_fcst',
          url: _config.vilageFcstUrl,
          query: {
            'pageNo': '1',
            'numOfRows': '300',
            'dataType': 'JSON',
            'base_date': _formatDate(villageBase),
            'base_time': _formatTime(villageBase),
            'nx': '${grid.nx}',
            'ny': '${grid.ny}',
            'authKey': _config.authKey,
          },
          diagnostics: diagnostics,
        );
        diagnostics['village_fcstOutcome'] = 'success';
        diagnostics['forecastRequestSummary'] =
            'ultra_ncst 성공 / ultra_fcst 실패 / village_fcst 성공';
        return _ForecastFetchResponse(
          requestName: 'village_fcst',
          source: _ForecastSource.village,
          items: items,
        );
      } on WeatherRepositoryException catch (villageError) {
        diagnostics['village_fcstOutcome'] = 'failed';
        diagnostics['village_fcstErrorCode'] = villageError.code;
        diagnostics['village_fcstErrorStage'] = villageError.stage;
        if ((villageError.debugMessage ?? '').isNotEmpty) {
          diagnostics['village_fcstDebug'] = villageError.debugMessage!;
        }
        diagnostics['forecastRequestSummary'] =
            'ultra_ncst 성공 / ultra_fcst 실패 / village_fcst 실패';

        if (_isBrowserFetchFailure(ultraError) || _isBrowserFetchFailure(villageError)) {
          diagnostics['failureClass'] = 'browser_fetch_blocked';
          diagnostics['fallbackReason'] =
              '웹 브라우저에서 기상청 예보 API 직접 호출이 차단되어 fallback을 사용했습니다.';
          throw KmaWeatherException(
            code: 'KMA-009',
            stage: 'forecast_browser_fetch_blocked',
            message: '웹 브라우저에서 기상청 예보 API 직접 호출이 차단되었습니다. 프록시 또는 백엔드 경유가 필요합니다.',
            debugMessage:
                'ultra_fcst=${ultraError.debugMessage ?? ultraError.message}; village_fcst=${villageError.debugMessage ?? villageError.message}',
            details: {
              'forecastStrategy': 'ultra_fcst_then_village_fcst',
              'webDirectCallLimit': 'true',
              'proxyRequired': 'true',
            },
          );
        }

        diagnostics['fallbackReason'] = '예보 API 응답 확보에 실패해 fallback을 사용했습니다.';
        throw villageError;
      }
    }
  }

  List<HourlyWeatherForecast> _buildHourlyForecasts(
    List<Map<String, dynamic>> items, {
    required DateTime now,
    required Map<String, String> diagnostics,
    required _ForecastSource source,
  }) {
    final grouped = <String, Map<String, String>>{};

    for (final item in items) {
      final fcstDate = '${item['fcstDate'] ?? ''}';
      final fcstTime = '${item['fcstTime'] ?? ''}';
      final category = '${item['category'] ?? ''}';
      final fcstValue = '${item['fcstValue'] ?? ''}';

      if (fcstDate.isEmpty || fcstTime.isEmpty || category.isEmpty) {
        continue;
      }

      final key = '$fcstDate$fcstTime';
      grouped.putIfAbsent(key, () => <String, String>{});
      grouped[key]![category] = fcstValue;
    }

    final results = <HourlyWeatherForecast>[];
    final keys = grouped.keys.toList()..sort();
    for (final key in keys) {
      final forecastAt = _parseForecastDateTime(key);
      if (forecastAt == null || forecastAt.isBefore(now)) {
        continue;
      }

      final values = grouped[key]!;
      if (!_hasForecastCategories(values)) {
        continue;
      }

      results.add(
        HourlyWeatherForecast(
          at: forecastAt,
          weather: WeatherSnapshot(
            temperatureCelsius: _doubleValue(
              _temperatureValue(values, source),
              fallback: 20,
            ),
            humidity: _intValue(values['REH'], fallback: 55),
            windSpeedMps: _doubleValue(values['WSD'], fallback: 1.5),
            skyCondition: _skyCondition(
              skyValue: values['SKY'],
              ptyValue: values['PTY'],
            ),
            rainProbability: _intValue(values['POP'], fallback: 20),
          ),
        ),
      );
    }

    diagnostics['forecastGroupCount'] = '${grouped.length}';
    diagnostics['usableForecastCount'] = '${results.length}';
    return results;
  }

  WeatherSnapshot _buildCurrentSnapshot({
    required List<Map<String, dynamic>> currentItems,
    required WeatherSnapshot fallbackForecast,
    required Map<String, String> diagnostics,
  }) {
    final values = <String, String>{};
    for (final item in currentItems) {
      final category = '${item['category'] ?? ''}';
      final obsrValue = '${item['obsrValue'] ?? ''}';
      if (category.isEmpty) {
        continue;
      }
      values[category] = obsrValue;
    }

    diagnostics['currentCategories'] = values.keys.join(', ');
    return WeatherSnapshot(
      temperatureCelsius:
          _doubleValue(values['T1H'], fallback: fallbackForecast.temperatureCelsius),
      humidity: _intValue(values['REH'], fallback: fallbackForecast.humidity),
      windSpeedMps:
          _doubleValue(values['WSD'], fallback: fallbackForecast.windSpeedMps),
      skyCondition: _skyCondition(
        skyValue: _skyCodeFor(fallbackForecast.skyCondition),
        ptyValue: values['PTY'],
      ),
      rainProbability: fallbackForecast.rainProbability,
    );
  }

  bool _hasForecastCategories(Map<String, String> values) {
    return (values.containsKey('T1H') || values.containsKey('TMP')) &&
        values.containsKey('REH') &&
        values.containsKey('WSD') &&
        values.containsKey('PTY') &&
        values.containsKey('SKY') &&
        values.containsKey('POP');
  }

  _KmaLocation _locationFor(WeatherRequestContext context) {
    if (context.latitude != null && context.longitude != null) {
      return _KmaLocation(
        latitude: context.latitude!,
        longitude: context.longitude!,
      );
    }

    switch (context.sourceType) {
      case LocationSourceType.current:
        return const _KmaLocation(
          latitude: 37.3417,
          longitude: 127.1112,
        );
      case LocationSourceType.saved:
      case LocationSourceType.search:
        return const _KmaLocation(
          latitude: 37.5665,
          longitude: 126.9780,
        );
    }
  }

  DateTime _latestUltraSrtNcstBase(DateTime now) {
    final aligned = DateTime(now.year, now.month, now.day, now.hour);
    if (now.minute < 45) {
      return aligned.subtract(const Duration(hours: 1));
    }
    return aligned;
  }

  DateTime _latestUltraSrtFcstBase(DateTime now) {
    final hour = now.minute < 45 ? now.hour - 1 : now.hour;
    return DateTime(now.year, now.month, now.day, hour, 30);
  }

  DateTime _latestVilageFcstBase(DateTime now) {
    final candidates = <int>[23, 20, 17, 14, 11, 8, 5, 2];
    final adjustedDay = now.minute < 10 ? now.subtract(const Duration(hours: 1)) : now;
    final currentHour = adjustedDay.hour;
    for (final hour in candidates) {
      if (currentHour > hour || (currentHour == hour && adjustedDay.minute >= 10)) {
        return DateTime(adjustedDay.year, adjustedDay.month, adjustedDay.day, hour);
      }
    }
    final previousDay = adjustedDay.subtract(const Duration(days: 1));
    return DateTime(previousDay.year, previousDay.month, previousDay.day, 23);
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour$minute';
  }

  DateTime? _parseForecastDateTime(String key) {
    if (key.length != 12) {
      return null;
    }
    final year = int.tryParse(key.substring(0, 4));
    final month = int.tryParse(key.substring(4, 6));
    final day = int.tryParse(key.substring(6, 8));
    final hour = int.tryParse(key.substring(8, 10));
    final minute = int.tryParse(key.substring(10, 12));
    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null) {
      return null;
    }
    return DateTime(year, month, day, hour, minute);
  }

  int _intValue(String? value, {required int fallback}) {
    return int.tryParse(value ?? '') ?? fallback;
  }

  double _doubleValue(String? value, {required double fallback}) {
    return double.tryParse(value ?? '') ?? fallback;
  }

  String? _temperatureValue(
    Map<String, String> values,
    _ForecastSource source,
  ) {
    if (source == _ForecastSource.village) {
      return values['TMP'] ?? values['T1H'];
    }
    return values['T1H'] ?? values['TMP'];
  }

  bool _isBrowserFetchFailure(WeatherRepositoryException error) {
    final debug = (error.debugMessage ?? '').toLowerCase();
    return (error.code == 'KMA-009') ||
        (error.stage.endsWith('_http_request') && debug.contains('failed to fetch')) ||
        (error.stage.contains('browser_fetch_blocked'));
  }

  bool _looksLikeBrowserFetchFailure(String debugText) {
    final normalized = debugText.toLowerCase();
    return normalized.contains('failed to fetch') ||
        normalized.contains('xmlhttprequest error') ||
        normalized.contains('networkerror');
  }

  bool _looksLikeAuthFailure(String resultCode, String resultMessage) {
    final normalizedMessage = resultMessage.toLowerCase();
    return resultCode == '30' ||
        normalizedMessage.contains('servicekey') ||
        normalizedMessage.contains('auth') ||
        normalizedMessage.contains('key') ||
        normalizedMessage.contains('unauthorized') ||
        normalizedMessage.contains('forbidden');
  }

  SkyCondition _skyCondition({
    required String? skyValue,
    required String? ptyValue,
  }) {
    if (ptyValue != null && ptyValue != '0' && ptyValue.isNotEmpty) {
      return SkyCondition.rainy;
    }

    switch (skyValue) {
      case '1':
        return SkyCondition.sunny;
      case '3':
        return SkyCondition.partlyCloudy;
      case '4':
        return SkyCondition.cloudy;
      default:
        return SkyCondition.partlyCloudy;
    }
  }

  String _skyCodeFor(SkyCondition condition) {
    switch (condition) {
      case SkyCondition.sunny:
        return '1';
      case SkyCondition.partlyCloudy:
        return '3';
      case SkyCondition.cloudy:
      case SkyCondition.rainy:
        return '4';
    }
  }
}

class FallbackWeatherRepository implements WeatherRepository {
  const FallbackWeatherRepository({
    required this.primary,
    required this.fallback,
  });

  final WeatherRepository primary;
  final WeatherRepository fallback;

  @override
  Future<WeatherBundle> fetchWeather(WeatherRequestContext context) async {
    try {
      return await primary.fetchWeather(context);
    } on WeatherRepositoryException catch (error) {
      debugPrint(
        '[FallbackWeatherRepository] code=${error.code} stage=${error.stage} message=${error.message} debug=${error.debugMessage ?? '-'}',
      );
      final fallbackBundle = await fallback.fetchWeather(context);
      return WeatherBundle(
        current: fallbackBundle.current,
        hourly: fallbackBundle.hourly,
        meta: WeatherFetchMeta(
          source: 'fallback',
          stage: error.stage,
          userMessage:
              '날씨 연동 실패(${error.code})로 fallback 데이터를 표시 중입니다.',
          errorCode: 'KMA-008',
          debugMessage: error.message,
          usedFallback: true,
          details: {
            ...fallbackBundle.meta.details,
            ...error.details,
            'requestTarget': error.details['requestTarget'] ?? _requestTargetFor(error),
            'retryAttempted': 'false',
            'upstreamErrorCode': error.code,
            'upstreamStage': error.stage,
            'upstreamMessage': error.message,
            'fallbackReason': error.details['fallbackReason'] ?? _fallbackReasonFor(error),
            if ((error.debugMessage ?? '').isNotEmpty)
              'upstreamDebug': error.debugMessage!,
          },
        ),
      );
    } catch (error) {
      debugPrint('[FallbackWeatherRepository] unexpected=$error');
      final fallbackBundle = await fallback.fetchWeather(context);
      return WeatherBundle(
        current: fallbackBundle.current,
        hourly: fallbackBundle.hourly,
        meta: WeatherFetchMeta(
          source: 'fallback',
          stage: 'unexpected_failure',
          userMessage: '예상치 못한 실패로 fallback 데이터를 표시 중입니다.',
          errorCode: 'KMA-008',
          debugMessage: '$error',
          usedFallback: true,
          details: {
            ...fallbackBundle.meta.details,
            'runtimePlatform': kIsWeb ? 'web' : 'native',
            'requestTarget': 'unknown',
            'retryAttempted': 'false',
            'upstreamErrorCode': 'KMA-999',
            'upstreamStage': 'unexpected_failure',
            'upstreamMessage': '$error',
            'fallbackReason': '예상치 못한 날씨 연동 실패로 fallback을 사용했습니다.',
          },
        ),
      );
    }
  }

  String _requestTargetFor(WeatherRepositoryException error) {
    if (error.code.startsWith('BACKEND-')) {
      return 'backend';
    }
    return 'kma';
  }

  String _fallbackReasonFor(WeatherRepositoryException error) {
    if (error.code.startsWith('BACKEND-')) {
      return '외부 날씨 백엔드 응답 확보에 실패해 fallback을 사용했습니다.';
    }
    return '기상청 응답 확보에 실패해 fallback을 사용했습니다.';
  }
}

class KmaWeatherException extends WeatherRepositoryException {
  const KmaWeatherException({
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

  final String code;
  final String stage;
  final String message;
  final String? debugMessage;
  final Map<String, String> details;

  @override
  KmaWeatherException withMergedDetails(Map<String, String> nextDetails) {
    return KmaWeatherException(
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

class _KmaLocation {
  const _KmaLocation({
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

enum _ForecastSource {
  ultraShort,
  village,
}

class _ForecastFetchResponse {
  const _ForecastFetchResponse({
    required this.requestName,
    required this.source,
    required this.items,
  });

  final String requestName;
  final _ForecastSource source;
  final List<Map<String, dynamic>> items;
}
