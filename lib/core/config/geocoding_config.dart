class GeocodingConfig {
  const GeocodingConfig({
    required this.providerName,
    required this.baseUrl,
    required this.apiKey,
    required this.authHeaderName,
    required this.enabled,
    required this.requiresApiKey,
  });

  factory GeocodingConfig.kakaoFromEnvironment() {
    return const GeocodingConfig(
      providerName: String.fromEnvironment(
        'KAKAO_GEOCODING_PROVIDER_NAME',
        defaultValue: 'Kakao Local API',
      ),
      baseUrl: String.fromEnvironment(
        'KAKAO_GEOCODING_BASE_URL',
        defaultValue: 'https://dapi.kakao.com/v2/local/geo/coord2regioncode.json',
      ),
      apiKey: String.fromEnvironment(
        'KAKAO_REST_API_KEY',
        defaultValue: '',
      ),
      authHeaderName: String.fromEnvironment(
        'KAKAO_AUTH_HEADER_NAME',
        defaultValue: 'Authorization',
      ),
      enabled: bool.fromEnvironment(
        'KAKAO_GEOCODING_ENABLED',
        defaultValue: true,
      ),
      requiresApiKey: true,
    );
  }

  factory GeocodingConfig.openStreetMapFromEnvironment() {
    return const GeocodingConfig(
      providerName: String.fromEnvironment(
        'OSM_GEOCODING_PROVIDER_NAME',
        defaultValue: 'OpenStreetMap Nominatim',
      ),
      baseUrl: String.fromEnvironment(
        'OSM_GEOCODING_BASE_URL',
        defaultValue: 'https://nominatim.openstreetmap.org/reverse',
      ),
      apiKey: String.fromEnvironment(
        'OSM_GEOCODING_API_KEY',
        defaultValue: '',
      ),
      authHeaderName: String.fromEnvironment(
        'OSM_GEOCODING_AUTH_HEADER_NAME',
        defaultValue: '',
      ),
      enabled: bool.fromEnvironment(
        'OSM_GEOCODING_ENABLED',
        defaultValue: true,
      ),
      requiresApiKey: false,
    );
  }

  final String providerName;
  final String baseUrl;
  final String apiKey;
  final String authHeaderName;
  final bool enabled;
  final bool requiresApiKey;

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
