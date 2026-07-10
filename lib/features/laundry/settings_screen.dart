import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/api_models.dart';
import '../../core/ppallae_native.dart';
import 'laundry_home_controller.dart';
import 'region_search_screen.dart';
import 'score_criteria_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final LaundryHomeController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionLine = '버전 …';
  // null = 확인 전/미지원. false = 최적화 켜짐(갱신 죽을 수 있음). true = 예외 처리됨.
  bool? _batteryExcluded;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _refreshBatteryStatus();
  }

  Future<void> _refreshBatteryStatus() async {
    final excluded = await PpallaeNative.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _batteryExcluded = excluded);
  }

  Future<void> _openBatterySettings() async {
    final ok = await PpallaeNative.openBatteryOptimizationSettings();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 화면을 열 수 없어요. 폰 설정 → 배터리에서 직접 변경해주세요.')),
      );
    }
    // 설정에서 돌아오면 상태 재확인 (약간의 지연 후).
    await Future.delayed(const Duration(seconds: 1));
    await _refreshBatteryStatus();
  }

  Future<void> _addWidgetToHome() async {
    final supported = await PpallaeNative.isPinWidgetSupported();
    if (!supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이 기기는 자동 추가를 지원하지 않아요. 홈 화면을 길게 눌러 "빨래빨래" 위젯을 추가해주세요.'),
          ),
        );
      }
      return;
    }
    await PpallaeNative.requestPinWidget(size: '2x1');
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // pubspec.yaml 의 version: 1.0.0+1 → "버전 1.0.0 (1)"
      if (mounted) {
        setState(() {
          _versionLine = '버전 ${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _versionLine = '버전 확인 불가');
    }
  }

  /// 고객센터 웹 열기. 백엔드 app-config 의 customerCenter URL 우선,
  /// 비어 있으면 운영 도메인 폴백 (호스팅 확정 전까지 placeholder).
  Future<void> _openCustomerCenter(BuildContext context) async {
    final urls = widget.controller.appConfig?.urls;
    final raw = (urls != null && urls.customerCenter.isNotEmpty)
        ? urls.customerCenter
        : 'https://ppallae.app/support';
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('고객센터 준비 중이에요. 곧 열릴 예정입니다.')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객센터를 열 수 없어요. 잠시 후 다시 시도해주세요.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객센터를 열 수 없어요. 잠시 후 다시 시도해주세요.')),
        );
      }
    }
  }

  Future<void> _changeRegion(BuildContext context) async {
    final region = await Navigator.of(context).push<RegionModel>(
      MaterialPageRoute(
        builder: (_) => RegionSearchScreen(apiClient: widget.controller.api),
      ),
    );
    if (region != null) {
      await widget.controller.selectRegion(region);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ListView(
              children: [
                _SectionHeader('기본 지역'),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(controller.region.displayName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changeRegion(context),
                ),
                const Divider(),
                _SectionHeader('홈 위젯'),
                SwitchListTile(
                  secondary: const Icon(Icons.widgets_outlined),
                  title: const Text('홈 화면 위젯 사용'),
                  subtitle: const Text('빨래지수와 추천 시간을 홈 위젯에 표시 (Android)'),
                  value: controller.widgetEnabled,
                  onChanged: (v) => controller.setWidgetEnabled(v),
                ),
                if (controller.widgetEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.add_to_home_screen_outlined),
                    title: const Text('홈에 위젯 추가'),
                    subtitle: const Text('빨래빨래 위젯을 홈 화면에 바로 올려요'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _addWidgetToHome,
                  ),
                  // 배터리 최적화가 켜져 있으면 위젯 자동 갱신이 죽을 수 있음 → 경고 유도.
                  if (_batteryExcluded == false)
                    ListTile(
                      leading: const Icon(Icons.battery_alert_outlined,
                          color: Color(0xFFD9822B)),
                      title: const Text('위젯이 자동 갱신되게 하기'),
                      subtitle: const Text(
                          '배터리 최적화가 켜져 있어 위젯이 오래된 정보를 보일 수 있어요. '
                          '"제한 없음"으로 바꾸면 30분마다 자동 갱신됩니다.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openBatterySettings,
                    )
                  else if (_batteryExcluded == true)
                    const ListTile(
                      leading: Icon(Icons.check_circle_outline,
                          color: Color(0xFF3A9E6E)),
                      title: Text('위젯 자동 갱신 켜짐'),
                      subtitle: Text('배터리 최적화 예외로 지정돼 있어요.'),
                    ),
                ],
                const Divider(),
                _SectionHeader('정보'),
                // 공지·FAQ·문의·약관은 고객센터 웹으로 일원화 (2026-07-06 결정).
                // 앱 내 중복 화면을 제거하고 한 곳에서 운영한다.
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('고객센터'),
                  subtitle: const Text('공지 · FAQ · 문의 · 약관/개인정보처리방침'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openCustomerCenter(context),
                ),
                ListTile(
                  leading: const Icon(Icons.rule_folder_outlined),
                  title: const Text('빨래빨래 기준'),
                  subtitle: const Text('등급 5단계 설명 · 점수 계산법'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ScoreCriteriaScreen(),
                    ),
                  ),
                ),
                // NOTE(2026-07-10): 데이터 출처·오픈소스 타일 제거 — 고객센터 웹
                // (/data-source, /opensource)으로 일원화. 겹치는 정보는 앱에 두지
                // 않는다(제품 결정). Play 심사에서 인앱 라이선스 고지를 요구하면
                // showLicensePage 한 줄로 복원 가능.
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('위치 정보'),
                  subtitle: Text('현재 위치는 지역 변환에만 사용되며 서버에 저장되지 않습니다.'),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('빨래빨래'),
                  subtitle: Text(_versionLine),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A7BD5),
          fontSize: 14,
        ),
      ),
    );
  }
}
