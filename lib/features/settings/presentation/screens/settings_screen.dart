import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../recommendation/models/saved_location.dart';
import '../../../recommendation/models/user_preference_settings.dart';
import '../../../recommendation/state/laundry_dashboard_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  final LaundryDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.state.preferences;
        final savedLocations = controller.state.savedLocations;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                '개인 설정',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '추천 점수 계산과 저장 위치 구성을 생활 패턴에 맞게 조정해보세요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _SettingToggleCard(
                title: '빠르게 마르는 것이 중요',
                subtitle: '습도, 바람, 일조 조건을 더 민감하게 반영합니다.',
                value: settings.prioritizeFastDrying,
                onChanged: (value) => _updateSettings(
                  settings.copyWith(prioritizeFastDrying: value),
                ),
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                title: '비 맞으면 안됨',
                subtitle: '강수확률 패널티를 더 크게 적용합니다.',
                value: settings.avoidRainExposure,
                onChanged: (value) => _updateSettings(
                  settings.copyWith(avoidRainExposure: value),
                ),
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                title: '실내 건조 기준 사용',
                subtitle: '바람 영향은 줄이고 습도 영향은 더 크게 봅니다.',
                value: settings.useIndoorDryingMode,
                onChanged: (value) => _updateSettings(
                  settings.copyWith(useIndoorDryingMode: value),
                ),
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                title: '알림 받기',
                subtitle: '추천 시간과 날씨 경고 알림을 전체 활성화합니다.',
                value: settings.notificationsEnabled,
                onChanged: (value) => _updateSettings(
                  settings.copyWith(notificationsEnabled: value),
                ),
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                title: '추천 시간 알림 받기',
                subtitle: '향후 24시간 중 가장 좋은 빨래 시간을 알려줍니다.',
                value: settings.bestTimeAlertsEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) => _updateSettings(
                          settings.copyWith(bestTimeAlertsEnabled: value),
                        )
                    : null,
              ),
              const SizedBox(height: 12),
              _SettingToggleCard(
                title: '비 예보 경고 받기',
                subtitle: '비 시작 2시간 전과 1시간 전에 경고합니다.',
                value: settings.rainAlertsEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) => _updateSettings(
                          settings.copyWith(rainAlertsEnabled: value),
                        )
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '저장 위치 관리',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _openLocationEditor(context);
                    },
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('위치 추가'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '집, 회사, 학교처럼 자주 보는 위치를 저장해두고 홈에서 바로 선택하세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...savedLocations.map(
                (location) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(location.address),
                              const SizedBox(height: 6),
                              Text(
                                '위도 ${location.latitude.toStringAsFixed(4)} · 경도 ${location.longitude.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openLocationEditor(context, existing: location);
                            } else if (value == 'delete') {
                              controller.deleteLocation(location.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSettings(UserPreferenceSettings settings) {
    controller.updatePreferences(settings);
  }

  Future<void> _openLocationEditor(
    BuildContext context, {
    SavedLocation? existing,
  }) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final latitudeController = TextEditingController(
      text: existing?.latitude.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: existing?.longitude.toString() ?? '',
    );

    final next = await showDialog<SavedLocation>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? '저장 위치 추가' : '저장 위치 수정'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: '이름'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: '주소'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: latitudeController,
                    decoration: const InputDecoration(labelText: '위도'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: longitudeController,
                    decoration: const InputDecoration(labelText: '경도'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final latitude = double.tryParse(latitudeController.text.trim());
                final longitude = double.tryParse(longitudeController.text.trim());
                if (labelController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty ||
                    latitude == null ||
                    longitude == null) {
                  return;
                }
                final base = existing ??
                    SavedLocation.create(
                      label: labelController.text.trim(),
                      latitude: latitude,
                      longitude: longitude,
                      address: addressController.text.trim(),
                    );
                Navigator.of(context).pop(
                  base.copyWith(
                    label: labelController.text.trim(),
                    address: addressController.text.trim(),
                    latitude: latitude,
                    longitude: longitude,
                    updatedAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (next != null) {
      await controller.saveLocation(next);
    }
  }
}

class _SettingToggleCard extends StatelessWidget {
  const _SettingToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
