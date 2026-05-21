class KmaWeatherApiConfig {
  const KmaWeatherApiConfig({
    required this.providerName,
    required this.ultraSrtNcstUrl,
    required this.ultraSrtFcstUrl,
    required this.vilageFcstUrl,
    required this.authKey,
    required this.requestTimeoutSeconds,
    required this.enabled,
  });

  factory KmaWeatherApiConfig.fromEnvironment() {
    return const KmaWeatherApiConfig(
      providerName: String.fromEnvironment(
        'KMA_PROVIDER_NAME',
        defaultValue: 'KMA API Hub',
      ),
      ultraSrtNcstUrl: String.fromEnvironment(
        'KMA_ULTRA_SRT_NCST_URL',
        defaultValue:
            'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtNcst',
      ),
      ultraSrtFcstUrl: String.fromEnvironment(
        'KMA_ULTRA_SRT_FCST_URL',
        defaultValue:
            'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtFcst',
      ),
      vilageFcstUrl: String.fromEnvironment(
        'KMA_VILAGE_FCST_URL',
        defaultValue:
            'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst',
      ),
      authKey: String.fromEnvironment(
        'KMA_AUTH_KEY',
        defaultValue: 'uXwUAn5eSMC8FAJ-XvjAeg',
      ),
      requestTimeoutSeconds: int.fromEnvironment(
        'KMA_REQUEST_TIMEOUT_SECONDS',
        defaultValue: 15,
      ),
      enabled: bool.fromEnvironment(
        'KMA_ENABLED',
        defaultValue: true,
      ),
    );
  }

  final String providerName;
  final String ultraSrtNcstUrl;
  final String ultraSrtFcstUrl;
  final String vilageFcstUrl;
  final String authKey;
  final int requestTimeoutSeconds;
  final bool enabled;

  bool get hasAuthKey => authKey.trim().isNotEmpty;
}

class BackendWeatherApiConfig {
  const BackendWeatherApiConfig({
    required this.providerName,
    required this.baseUrl,
    required this.apiKey,
    required this.requestTimeoutSeconds,
    required this.enabled,
  });

  factory BackendWeatherApiConfig.fromEnvironment() {
    return const BackendWeatherApiConfig(
      providerName: String.fromEnvironment(
        'WEATHER_BACKEND_PROVIDER_NAME',
        defaultValue: 'External Weather Backend',
      ),
      baseUrl: String.fromEnvironment(
        'WEATHER_BACKEND_BASE_URL',
        defaultValue: '',
      ),
      apiKey: String.fromEnvironment(
        'WEATHER_BACKEND_API_KEY',
        defaultValue: '',
      ),
      requestTimeoutSeconds: int.fromEnvironment(
        'WEATHER_BACKEND_TIMEOUT_SECONDS',
        defaultValue: 10,
      ),
      enabled: bool.fromEnvironment(
        'WEATHER_BACKEND_ENABLED',
        defaultValue: true,
      ),
    );
  }

  final String providerName;
  final String baseUrl;
  final String apiKey;
  final int requestTimeoutSeconds;
  final bool enabled;

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;
  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
