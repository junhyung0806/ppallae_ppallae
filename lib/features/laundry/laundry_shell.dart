import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'consent_screen.dart';
import 'laundry_home_controller.dart';
import 'laundry_home_screen.dart';

class LaundryShell extends StatefulWidget {
  const LaundryShell({super.key});

  @override
  State<LaundryShell> createState() => _LaundryShellState();
}

class _LaundryShellState extends State<LaundryShell>
    with WidgetsBindingObserver {
  // 컨트롤러는 동의 완료 후에만 생성한다 (위치 접근을 동의 전에 하지 않기 위해).
  LaundryHomeController? _controller;
  bool _gateChecked = false;

  // 동의 게이트 상태: null=확인중, false=미동의(동의화면), true=동의완료(앱시작).
  bool? _consented;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveConsent();
  }

  Future<void> _resolveConsent() async {
    final ok = await ConsentScreen.hasConsented();
    if (!mounted) return;
    if (ok) {
      _startApp();
    } else {
      setState(() => _consented = false);
    }
  }

  /// 동의 완료 후(또는 이미 동의 상태) 컨트롤러를 생성·초기화하고 앱을 시작.
  void _startApp() {
    final controller = LaundryHomeController();
    _controller = controller;
    // 위치 권한 시스템 팝업 전 사전 설명 다이얼로그.
    controller.requestLocationRationale = _showLocationRationale;
    controller.initialize().then((_) {
      if (!mounted) return;
      _checkAppConfigGate();
    });
    controller.addListener(_onControllerChanged);
    setState(() => _consented = true);
  }

  /// "왜 위치가 필요한지" 사전 설명. 허용하면 true(→ 시스템 팝업), 나중에면 false.
  Future<bool> _showLocationRationale() async {
    if (!mounted) return true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('위치 권한이 필요해요'),
        content: const Text(
          '내 지역의 날씨로 빨래 지수를 정확히 계산하기 위해 현재 위치를 사용해요.\n'
          '좌표는 지역(동) 변환에만 쓰고 저장하지 않아요.\n\n'
          '허용하지 않아도 기본 지역으로 이용할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('위치 허용'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onConsentAgreed() {
    _startApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 위젯 우선 앱: 앱을 오래 백그라운드에 뒀다 열면 데이터가 stale 할 수 있다.
    // 복귀 시 마지막 갱신이 오래됐으면(기본 30분+) 자동 새로고침해 항상 최신을 보게 한다.
    final controller = _controller;
    if (controller == null) return; // 동의 전엔 컨트롤러 없음
    if (state == AppLifecycleState.resumed && controller.isDataStale()) {
      controller.refresh();
    }
  }

  void _onControllerChanged() {
    // 첫 appConfig 로드 후에만 게이트 평가. 이후 갱신은 무시 (다시 띄우지 않음).
    if (_gateChecked || _controller?.appConfig == null) return;
    _checkAppConfigGate();
  }

  /// 점검 모드 → 강제 업데이트 순으로 평가. 둘 다 아니면 일반 화면.
  Future<void> _checkAppConfigGate() async {
    final config = _controller?.appConfig;
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
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 동의 확인 중: 짧은 로딩. 미동의: 동의 화면. 동의 완료: 앱 본체.
    if (_consented == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final controller = _controller;
    if (_consented == false || controller == null) {
      return ConsentScreen(onAgreed: _onConsentAgreed);
    }
    return LaundryHomeScreen(controller: controller);
  }
}

