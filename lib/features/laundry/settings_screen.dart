import 'package:flutter/material.dart';

import '../../api/models/api_models.dart';
import 'data_source_screen.dart';
import 'laundry_home_controller.dart';
import 'region_search_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final LaundryHomeController controller;

  Future<void> _changeRegion(BuildContext context) async {
    final region = await Navigator.of(context).push<RegionModel>(
      MaterialPageRoute(
        builder: (_) => RegionSearchScreen(apiClient: controller.api),
      ),
    );
    if (region != null) {
      await controller.selectRegion(region);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _SectionHeader('기본 건조 장소'),
                Wrap(
                  spacing: 8,
                  children: DryingPlace.values.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: controller.dryingPlace == p,
                        onSelected: (_) => controller.selectDryingPlace(p),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(),
                _SectionHeader('기본 빨래 양'),
                Wrap(
                  spacing: 8,
                  children: LaundryAmount.values.map((a) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ChoiceChip(
                        label: Text(a.label),
                        selected: controller.laundryAmount == a,
                        onSelected: (_) => controller.selectAmount(a),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(),
                _SectionHeader('정보'),
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
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('위치 정보'),
                  subtitle: Text('현재 위치는 지역 변환에만 사용되며 서버에 저장되지 않습니다.'),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('빨래빨래'),
                  subtitle: Text('버전 0.1.0 (MVP)'),
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
