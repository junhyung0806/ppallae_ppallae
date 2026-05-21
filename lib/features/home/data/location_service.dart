import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_error_code.dart';
import 'location_result.dart';
import 'reverse_geocoding_service.dart';

class LocationService {
  LocationService({
    ReverseGeocodingService? reverseGeocodingService,
  }) : _reverseGeocodingService =
            reverseGeocodingService ?? ReverseGeocodingService();

  final ReverseGeocodingService _reverseGeocodingService;

  Future<LocationResult> fetchCurrentLocation() async {
    final diagnostics = <String, String>{
      'platform': _platformLabel,
    };

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      diagnostics['serviceEnabled'] = '$serviceEnabled';
      debugPrint('[LocationService] serviceEnabled=$serviceEnabled');

      if (!serviceEnabled) {
        return _failureResult(
          displayText: '위치 정보를 불러올 수 없어요',
          stage: 'permission_checked',
          errorCode: LocationErrorCode.loc001,
          debugMessage: '위치 서비스가 비활성화되어 있습니다.',
          diagnostics: diagnostics,
        );
      }

      var permission = await Geolocator.checkPermission();
      diagnostics['initialPermission'] = '$permission';
      debugPrint('[LocationService] initialPermission=$permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        diagnostics['requestedPermission'] = '$permission';
        debugPrint('[LocationService] requestedPermission=$permission');
      }

      if (permission == LocationPermission.denied) {
        return _failureResult(
          displayText: '위치 정보를 불러올 수 없어요',
          stage: 'permission_checked',
          errorCode: LocationErrorCode.loc002,
          debugMessage: '위치 권한이 거부되었습니다.',
          diagnostics: diagnostics,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return _failureResult(
          displayText: '위치 정보를 불러올 수 없어요',
          stage: 'permission_checked',
          errorCode: LocationErrorCode.loc003,
          debugMessage: '위치 권한이 영구적으로 거부되었습니다.',
          diagnostics: diagnostics,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latitude = position.latitude;
      final longitude = position.longitude;
      diagnostics['latitude'] = latitude.toStringAsFixed(5);
      diagnostics['longitude'] = longitude.toStringAsFixed(5);
      debugPrint('[LocationService] latitude=$latitude longitude=$longitude');

      final geocodingResult = await _reverseGeocodingService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
        diagnostics: diagnostics,
      );

      final displayText = _safeDisplayText(
        geocodingResult.displayText,
        fallback: _coordinateText(latitude, longitude),
      );

      diagnostics['displayText'] = displayText;
      diagnostics['fallbackUsed'] = '${geocodingResult.usedFallback}';
      diagnostics['finalErrorCode'] = geocodingResult.errorCode?.code ?? '';
      diagnostics['rawResponseSummary'] = geocodingResult.rawSummary ?? '';
      diagnostics['httpStatus'] = '${geocodingResult.httpStatusCode ?? ''}';

      debugPrint(
        '[LocationService] finalDisplayText=$displayText fallback=${geocodingResult.usedFallback}',
      );

      return LocationResult(
        isSuccess: geocodingResult.errorCode == null,
        latitude: latitude,
        longitude: longitude,
        displayText: displayText,
        errorCode: geocodingResult.errorCode?.code,
        debugMessage: geocodingResult.debugMessage,
        stage: geocodingResult.stage,
        usedFallback: geocodingResult.usedFallback,
        diagnostics: Map.unmodifiable(Map<String, String>.from(diagnostics)),
      );
    } catch (error, stackTrace) {
      diagnostics['exception'] = '$error';
      debugPrint('[LocationService] fetchCurrentLocation error=$error');
      debugPrint('[LocationService] fetchCurrentLocation stackTrace=$stackTrace');

      return _failureResult(
        displayText: '위치 정보를 불러올 수 없어요',
        stage: 'position_failed',
        errorCode: LocationErrorCode.loc004,
        debugMessage: '현재 위치를 가져오는 중 예외가 발생했습니다: $error',
        diagnostics: diagnostics,
      );
    }
  }

  LocationResult _failureResult({
    required String displayText,
    required String stage,
    required LocationErrorCode errorCode,
    required String debugMessage,
    required Map<String, String> diagnostics,
  }) {
    diagnostics['errorCode'] = errorCode.code;
    diagnostics['stage'] = stage;
    diagnostics['displayText'] = displayText;

    return LocationResult(
      isSuccess: false,
      displayText: displayText,
      errorCode: errorCode.code,
      debugMessage: debugMessage,
      stage: stage,
      usedFallback: false,
      diagnostics: Map.unmodifiable(Map<String, String>.from(diagnostics)),
    );
  }

  String _coordinateText(double latitude, double longitude) {
    return '위도: ${latitude.toStringAsFixed(5)}, 경도: ${longitude.toStringAsFixed(5)}';
  }

  String _safeDisplayText(String? value, {required String fallback}) {
    if (value == null) {
      return fallback;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    return trimmed;
  }
  String get _platformLabel {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
