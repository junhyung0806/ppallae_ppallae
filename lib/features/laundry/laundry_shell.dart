import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'laundry_home_controller.dart';
import 'laundry_home_screen.dart';

class LaundryShell extends StatefulWidget {
  const LaundryShell({super.key});

  @override
  State<LaundryShell> createState() => _LaundryShellState();
}

class _LaundryShellState extends State<LaundryShell> {
  late final LaundryHomeController _controller;
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    _controller = LaundryHomeController();
    _controller.initialize().then((_) {
      if (!mounted) return;
      _checkAppConfigGate();
    });
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    // 첫 appConfig 로드 후에만 게이트 평가. 이후 갱신은 무시 (다시 띄우지 않음).
    if (_gateChecked || _controller.appConfig == null) return;
    _checkAppConfigGate();
  }

  /// 점검 모드 → 강제 업데이트 순으로 평가. 둘 다 아니면 일반 화면.
  Future<void> _checkAppConfigGate() async {
    final config = _controller.appConfig;
    if (config == null) return;
    _gateChecked = true;
    if (!mounted) return;

    if (config.maintenance.enabled) {
      _showBlockingDialog(
        title: '점검 중',
        message: config.maintenance.message.isEmpty
            ? '서비스 점검 중입니다. 잠시 후 다시 시도해주세요.'
            : config.maintenance.message,
        actionLabel: null,
      );
      return;
    }

    if (!config.versions.forceUpdate) return;

    final current = await _currentAppVersion();
    if (_isVersionBelow(current, config.versions.minimumSupported)) {
      _showBlockingDialog(
        title: '업데이트 필요',
        message: '앱을 사용하려면 최신 버전($current → ${config.versions.latest})으로'
            ' 업데이트해야 해요.',
        actionLabel: '스토어 열기',
        onAction: () async {
          final url = Uri.tryParse(config.urls.support.isNotEmpty
              ? config.urls.support
              : 'https://play.google.com/store/apps/');
          if (url != null) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      );
    }
  }

  Future<String> _currentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  /// "1.2.3" vs "1.2.4" 형태의 단순 semver 비교.
  /// a < b 면 true. 잘못된 형식은 false (=차단 안 함, 안전쪽으로).
  bool _isVersionBelow(String a, String b) {
    final aa = _parseVer(a);
    final bb = _parseVer(b);
    if (aa == null || bb == null) return false;
    for (var i = 0; i < 3; i++) {
      if (aa[i] != bb[i]) return aa[i] < bb[i];
    }
    return false;
  }

  List<int>? _parseVer(String v) {
    final parts = v.split('.').take(3).toList();
    if (parts.isEmpty) return null;
    while (parts.length < 3) {
      parts.add('0');
    }
    final ints = parts.map(int.tryParse).toList();
    if (ints.any((e) => e == null)) return null;
    return ints.cast<int>();
  }

  void _showBlockingDialog({
    required String title,
    required String message,
    required String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (actionLabel != null)
              TextButton(
                onPressed: onAction == null ? null : () => onAction(),
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LaundryHomeScreen(controller: _controller);
  }
}

