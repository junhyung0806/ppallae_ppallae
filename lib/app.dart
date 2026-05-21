import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'core/config/weather_api_config.dart';
import 'features/recommendation/data/backend_weather_repository.dart';
import 'features/recommendation/data/mock_dashboard_repositories.dart';
import 'features/recommendation/data/kma_weather_repository.dart';
import 'features/recommendation/state/laundry_dashboard_controller.dart';
import 'features/navigation/presentation/main_navigation_shell.dart';

class PpallaeApp extends StatefulWidget {
  const PpallaeApp({super.key});

  @override
  State<PpallaeApp> createState() => _PpallaeAppState();
}

class _PpallaeAppState extends State<PpallaeApp> {
  late final LaundryDashboardController _controller;

  @override
  void initState() {
    super.initState();
    final fallbackWeatherRepository = MockWeatherRepository();
    final primaryWeatherRepository = kIsWeb
        ? BackendWeatherRepository(
            config: BackendWeatherApiConfig.fromEnvironment(),
          )
        : KmaWeatherRepository(
            config: KmaWeatherApiConfig.fromEnvironment(),
          );
    _controller = LaundryDashboardController(
      weatherRepository: FallbackWeatherRepository(
        primary: primaryWeatherRepository,
        fallback: fallbackWeatherRepository,
      ),
      preferenceRepository: InMemoryUserPreferenceRepository(),
      historyRepository: InMemoryLaundryHistoryRepository(),
      savedLocationRepository: InMemorySavedLocationRepository(),
      notificationService: DebugNotificationService(),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '빨래빨래',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: MainNavigationShell(controller: _controller),
    );
  }
}
