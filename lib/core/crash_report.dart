import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/ppallae_api_client.dart' show sendClientErrorReport;

/// 전역 미처리 예외 수집 지점.
///
/// 로그 출력 + (release 빌드에서만) 백엔드 `/client-errors` 로 전송 —
/// Crashlytics 도입 전까지의 최소 크래시 가시성. 도입 시 이 파일 본문만
/// `FirebaseCrashlytics.instance.recordError(...)` 로 교체하면 된다.
/// (연결: [installGlobalErrorHandlers] — main.dart 에서 runApp 전에 설치)

/// 세션당 전송 상한 — 크래시 루프가 서버를 두드리는 것 방지.
const int _kMaxReportsPerSession = 5;
int _sentThisSession = 0;
String? _cachedAppVersion;

void reportUncaughtError(Object error, StackTrace? stack) {
  // release 빌드에서도 최소한 콘솔(logcat)에는 남긴다.
  // ignore: avoid_print
  print('PpallaeError [GEN-001] uncaught: $error');
  if (stack != null) {
    // ignore: avoid_print
    print(stack);
  }

  // 백엔드 전송은 release 만 (디버그 개발 소음이 DB 에 쌓이는 것 방지).
  if (!kReleaseMode) return;
  if (_sentThisSession >= _kMaxReportsPerSession) return;
  _sentThisSession++;
  // fire-and-forget — sendClientErrorReport 는 어떤 경우에도 던지지 않는다.
  _send(error, stack);
}

Future<void> _send(Object error, StackTrace? stack) async {
  try {
    _cachedAppVersion ??= (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // 버전 조회 실패해도 리포트는 보낸다.
  }
  await sendClientErrorReport(
    code: 'GEN-001',
    message: error.toString(),
    stack: stack?.toString(),
    appVersion: _cachedAppVersion,
    platform: defaultTargetPlatform.name,
  );
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
