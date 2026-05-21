import 'package:geocoding/geocoding.dart';

import 'location_error_code.dart';
import 'reverse_geocoding_provider.dart';

class GeocodingPluginProvider implements ReverseGeocodingProvider {
  @override
  String get providerName => 'GeocodingPluginProvider';

  @override
  Future<ReverseGeocodingProviderResult> reverseGeocode({
    required double latitude,
    required double longitude,
    required Map<String, String> diagnostics,
  }) async {
    try {
      await setLocaleIdentifier('ko_KR');
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      diagnostics['placemarkCount'] = '${placemarks.length}';

      if (placemarks.isEmpty) {
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo001,
          debugMessage: 'geocoding plugin 결과가 비어 있습니다.',
        );
      }

      final placemark = placemarks.first;
      final administrativeArea = _normalizeText(placemark.administrativeArea);
      final subAdministrativeArea =
          _normalizeText(placemark.subAdministrativeArea);
      final locality = _normalizeText(placemark.locality);
      final subLocality = _normalizeText(placemark.subLocality);
      final thoroughfare = _normalizeText(placemark.thoroughfare);

      diagnostics['administrativeArea'] = administrativeArea ?? '';
      diagnostics['subAdministrativeArea'] = subAdministrativeArea ?? '';
      diagnostics['locality'] = locality ?? '';
      diagnostics['subLocality'] = subLocality ?? '';
      diagnostics['thoroughfare'] = thoroughfare ?? '';

      final displayText = _composeAddress(
        administrativeArea: administrativeArea,
        subAdministrativeArea: subAdministrativeArea,
        locality: locality,
        subLocality: subLocality,
        thoroughfare: thoroughfare,
      );

      if (displayText == null) {
        return const ReverseGeocodingProviderResult(
          displayText: null,
          stage: 'geocoding_failed',
          usedFallback: false,
          errorCode: LocationErrorCode.geo002,
          debugMessage: 'placemark 필드가 모두 비어 있어 주소를 조합할 수 없습니다.',
        );
      }

      return ReverseGeocodingProviderResult(
        displayText: displayText,
        stage: 'geocoding_completed',
        usedFallback: false,
        rawSummary:
            'admin=$administrativeArea subAdmin=$subAdministrativeArea locality=$locality',
      );
    } catch (error) {
      return ReverseGeocodingProviderResult(
        displayText: null,
        stage: 'geocoding_failed',
        usedFallback: false,
        errorCode: LocationErrorCode.geo003,
        debugMessage: 'geocoding plugin 예외: $error',
      );
    }
  }

  String? _composeAddress({
    required String? administrativeArea,
    required String? subAdministrativeArea,
    required String? locality,
    required String? subLocality,
    required String? thoroughfare,
  }) {
    if (administrativeArea != null && subAdministrativeArea != null) {
      return '$administrativeArea $subAdministrativeArea';
    }

    if (locality != null && subLocality != null) {
      return '$locality $subLocality';
    }

    if (administrativeArea != null && locality != null) {
      return '$administrativeArea $locality';
    }

    if (locality != null && thoroughfare != null) {
      return '$locality $thoroughfare';
    }

    if (administrativeArea != null && thoroughfare != null) {
      return '$administrativeArea $thoroughfare';
    }

    return administrativeArea ??
        locality ??
        subAdministrativeArea ??
        subLocality ??
        thoroughfare;
  }

  String? _normalizeText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '대한민국') {
      return null;
    }

    return trimmed;
  }
}
