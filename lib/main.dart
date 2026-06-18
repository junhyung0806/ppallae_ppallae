import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/laundry/laundry_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LaundryShell(),
    );
  }
}
