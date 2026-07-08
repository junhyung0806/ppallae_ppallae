import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'error_codes.dart';

/// Android 네이티브(MainActivity) 다리.
///
/// - 배터리 최적화 예외 상태 조회 / 설정 화면 열기 (위젯 백그라운드 갱신 보호)
/// - 홈에 위젯 고정(requestPinAppWidget) (위젯 발견성)
///
/// 웹/비-Android/미지원 기기에서는 안전하게 no-op 또는 보수적 기본값을 반환한다.
class PpallaeNative {
  static const MethodChannel _channel = MethodChannel('ppallae/native');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 배터리 최적화 예외 상태. Android 아니면 true(문제 없음)로 간주.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isAndroid) return true;
    try {
      final v =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return v ?? true;
    } catch (e) {
      PpallaeError(ErrorCodes.batOptCheck, '배터리 최적화 상태를 확인하지 못했어요.',
              e.toString())
          .log();
      return true; // 모르면 경고를 띄우지 않는 쪽(오탐 방지)
    }
  }

  /// 배터리 최적화 설정 화면 열기. 성공 여부 반환.
  static Future<bool> openBatteryOptimizationSettings() async {
    if (!_isAndroid) return false;
    try {
      final v =
          await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
      return v ?? false;
    } catch (e) {
      PpallaeError(ErrorCodes.batOptCheck, '배터리 설정 화면을 열지 못했어요.', e.toString())
          .log();
      return false;
    }
  }

  /// requestPinAppWidget 지원 여부.
  static Future<bool> isPinWidgetSupported() async {
    if (!_isAndroid) return false;
    try {
      final v = await _channel.invokeMethod<bool>('isPinWidgetSupported');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 홈에 위젯 고정 요청. size: '1x1' | '2x1'. 지원 안 하면 false.
  static Future<bool> requestPinWidget({String size = '2x1'}) async {
    if (!_isAndroid) return false;
    try {
      final v = await _channel
          .invokeMethod<bool>('requestPinWidget', {'size': size});
      return v ?? false;
    } catch (e) {
      PpallaeError(ErrorCodes.wgtPinRequest, '홈에 위젯을 추가하지 못했어요.', e.toString())
          .log();
      return false;
    }
  }
}
