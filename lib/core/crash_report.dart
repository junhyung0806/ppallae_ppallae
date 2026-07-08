import 'package:flutter/foundation.dart';

/// 전역 미처리 예외 수집 지점.
///
/// 현재는 로그 출력만 한다 — 출시 결정(2026-06-01)대로 Firebase Crashlytics 를
/// 통합하면 이 함수 본문만 `FirebaseCrashlytics.instance.recordError(...)` 로
/// 바꾸면 되도록 앱의 모든 미처리 예외가 이 한 곳을 지나게 해뒀다.
/// (연결: [installGlobalErrorHandlers] — main.dart 에서 runApp 전에 설치)
///
/// TODO(release): Crashlytics 통합 시 recordError 호출로 교체.
void reportUncaughtError(Object error, StackTrace? stack) {
  // release 빌드에서도 최소한 콘솔(logcat)에는 남긴다.
  // ignore: avoid_print
  print('PpallaeError [GEN-001] uncaught: $error');
  if (stack != null) {
    // ignore: avoid_print
    print(stack);
  }
}

/// Flutter 프레임워크 예외 + 플랫폼(async) 미처리 예외를 전역으로 수집.
/// `WidgetsFlutterBinding.ensureInitialized()` 이후, `runApp` 전에 호출할 것.
void installGlobalErrorHandlers() {
  // 1) Flutter 프레임워크 예외 (build/layout/paint 등)
  final defaultHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // 디버그 콘솔의 기본 빨간 에러 출력은 유지
    defaultHandler?.call(details);
    reportUncaughtError(details.exception, details.stack);
  };

  // 2) 프레임워크 밖 미처리 async 예외 (root isolate)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    reportUncaughtError(error, stack);
    return true; // 앱 프로세스 종료 방지 (수집 후 계속 진행)
  };
}
