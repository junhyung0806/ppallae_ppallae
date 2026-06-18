import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../api/models/api_models.dart';
import 'data_source_screen.dart';
import 'laundry_home_controller.dart';
import 'legal_screen.dart';
import 'notices_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVersion();
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
                const Divider(),
                _SectionHeader('정보'),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('공지사항'),
                  subtitle: const Text('업데이트·점검 안내'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          NoticesScreen(apiClient: controller.api),
                    ),
                  ),
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
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: const Text('데이터 출처'),
                  subtitle: const Text('기상청 · 에어코리아 · 카카오'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DataSourceScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('정책 · 약관 · 문의'),
                  subtitle: const Text('개인정보처리방침 · 이용약관 · 위치기반 · 문의 · 오픈소스'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          LegalScreen(appConfig: controller.appConfig),
                    ),
                  ),
                ),
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
