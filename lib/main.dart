import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/crash_report.dart';
import 'core/theme/app_theme.dart';
import 'features/laundry/laundry_shell.dart';
import 'features/laundry/widget_refresh.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 미처리 예외 전역 수집 (Crashlytics 통합 시 crash_report.dart 만 교체).
  installGlobalErrorHandlers();
  // 홈 위젯 30분 주기 백그라운드 갱신 (Android 전용, 실패해도 앱 동작 무관).
  unawaited(registerWidgetBackgroundRefresh());
  // 세로 고정 — 가로 회전 비허용
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const PpallaeApp()));
}

class PpallaeApp extends StatelessWidget {
  const PpallaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '빨래빨래',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // 1.0 은 라이트 테마 고정 (의도된 결정 — 2026-07-04).
      // 등급색 시스템이 라이트 배경 기준으로 설계돼 있어 다크 대응은 1.1 에서
      // 등급 팔레트 재검증과 함께 진행. darkTheme 미지정 시에도 라이트가 쓰이지만
      // themeMode 를 명시해 "빠뜨린 것"이 아니라 "결정"임을 코드에 남긴다.
      themeMode: ThemeMode.light,
      home: const LaundryShell(),
    );
  }
}
