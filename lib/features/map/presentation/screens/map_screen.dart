import 'package:flutter/material.dart';

import '../../../recommendation/state/laundry_dashboard_controller.dart';
import '../widgets/location_map_section.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.controller,
  });

  final LaundryDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            '주변 빨래방 찾기',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '홈으로 통합된 지도 섹션과 같은 기능을 여기에서도 확인할 수 있어요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          LocationMapSection(
            controller: controller,
            showLocationSelector: true,
            onRefreshCurrent: controller.refreshCurrentLocation,
            onSearch: () async {},
            onSaveCurrentSelection: () async {},
          ),
        ],
      ),
    );
  }
}
