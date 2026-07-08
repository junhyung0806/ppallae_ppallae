import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/api_models.dart';
import '../../core/kst_time.dart';
import 'grade_utils.dart';
import 'laundry_home_controller.dart';
import 'timeline_best.dart';
import 'map/kakao_map_view.dart';
import 'map_fullscreen_screen.dart';
import 'settings_screen.dart';

// grade_utils 의 gradeFromScore / gradeLabel 을 같은 파일 식별자처럼 노출.
// 점수→등급 / 라벨은 모바일 모든 곳에서 단일 모듈을 통해서만 접근.

class LaundryHomeScreen extends StatelessWidget {
  const LaundryHomeScreen({super.key, required this.controller});

  final LaundryHomeController controller;

  LaundryHomeController get _controller => controller;

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapFullscreenScreen(controller: _controller),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return RefreshIndicator(
              // 당겨서 새로고침 = 사용자가 명시적으로 최신 요청 → 30분 캐시 무시.
              onRefresh: () => _controller.refresh(force: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _TopBar(
                    controller: _controller,
                    onMap: () => _openMap(context),
                    onSettings: () => _openSettings(context),
                  ),
                  if (_controller.isUsingFallbackRegion) ...[
                    const SizedBox(height: 10),
                    _FallbackRegionBanner(controller: _controller),
                  ],
                  if (_controller.locationNotice != null) ...[
                    const SizedBox(height: 10),
                    _LocationNoticeBanner(controller: _controller),
                  ],
                  const SizedBox(height: 14),
                  if (_controller.error != null)
                    _ErrorCard(
                      message: _controller.error!,
                      // 에러 후 재시도도 강제 갱신 (실패 시 캐시가 없거나 낡음).
                      onRetry: () => _controller.refresh(force: true),
                    )
                  else if (_controller.scoreEnvelope == null)
                    const _LoadingState()
                  else ...[
                    _ScoreCard(controller: _controller),
                    const SizedBox(height: 12),
                    _LaundryTypeSelector(controller: _controller),
                    const SizedBox(height: 8),
                    _DryingPlaceSelector(controller: _controller),
                    const SizedBox(height: 14),
                    _WeatherSummaryCard(
                      weather: _controller.scoreEnvelope!.weather,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_controller.timeline != null)
                    _TimelineCard(
                      timeline: _controller.timeline!,
                      accent: _controller.currentAccentColor,
                    ),
                  const SizedBox(height: 14),
                  _NearbySection(controller: _controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.onMap,
    required this.onSettings,
  });

  final LaundryHomeController controller;
  final VoidCallback onMap;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.place, color: controller.currentAccentColor, size: 22),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            controller.region.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2230),
            ),
          ),
        ),
        _IconBtn(
          tooltip: '현재 위치',
          icon: controller.locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 20),
          onTap: controller.locating
              ? null
              : () => controller.useCurrentLocation(),
        ),
        _IconBtn(
          tooltip: '지도',
          icon: const Icon(Icons.map_outlined, size: 22),
          onTap: onMap,
        ),
        _IconBtn(
          tooltip: '설정',
          icon: const Icon(Icons.settings_outlined, size: 22),
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.tooltip});
  final Widget icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconTheme(
          data: const IconThemeData(color: Color(0xFF4A5763)),
          child: icon,
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

/// "현재 위치를 못 가져왔어요. 기본 지역(서울) 기준 표시 중" 안내 배너.
/// 사용자가 본인 위치 날씨로 오해하지 않게 하는 핵심 표시.
class _FallbackRegionBanner extends StatelessWidget {
  const _FallbackRegionBanner({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D9A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off,
              size: 18, color: Color(0xFFC98A00)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '현재 위치를 가져오지 못해 기본 지역(서울) 기준으로 표시 중입니다.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF7A5A00)),
            ),
          ),
          TextButton(
            onPressed: controller.locating
                ? null
                : () => controller.useCurrentLocation(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }
}

class _LocationNoticeBanner extends StatelessWidget {
  const _LocationNoticeBanner({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D9A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFC98A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.locationNotice!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A5A00)),
            ),
          ),
          TextButton(
            onPressed: controller.locating
                ? null
                : () => controller.useCurrentLocation(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('다시 시도'),
          ),
          IconButton(
            onPressed: controller.dismissLocationNotice,
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            color: const Color(0xFFC98A00),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBox(height: 200, radius: 20),
        const SizedBox(height: 12),
        _SkeletonBox(height: 72, radius: 16),
        const SizedBox(height: 16),
        _SkeletonBox(height: 92, radius: 20),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('현재 위치의 빨래지수를 불러오는 중...',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.height, required this.radius});
  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = 0.4 + _ctrl.value * 0.4;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE8EDF3),
              const Color(0xFFF4F7FB),
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  const _WeatherSummaryCard({required this.weather});
  final WeatherSummaryModel weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Row(
        children: [
          Icon(
            _weatherIcon(weather.precipType, weather.skyCondition),
            color: _weatherColor(weather.precipType, weather.skyCondition),
            size: 36,
          ),
          const SizedBox(width: 14),
          Text(
            '${weather.temperatureC.round()}°',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _WeatherChip(
                    icon: Icons.water_drop_outlined,
                    label: '습도',
                    value: '${weather.humidityPercent}%'),
                _WeatherChip(
                    icon: Icons.air,
                    label: '바람',
                    value: '${weather.windSpeedMps.toStringAsFixed(1)}m/s'),
                // PM10·PM2.5를 별도로 보여줘 둘 중 하나만 나쁠 때도 사용자가 인지할 수 있게 함.
                _WeatherChip(
                    icon: Icons.blur_on,
                    label: 'PM10',
                    value: _pmLabel(weather.pm10Grade),
                    valueColor: _pmColor(weather.pm10Grade)),
                _WeatherChip(
                    icon: Icons.grain,
                    label: 'PM2.5',
                    value: _pmLabel(weather.pm25Grade),
                    valueColor: _pmColor(weather.pm25Grade)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black38),
        const SizedBox(width: 4),
        Text('$label ', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}

String _pmLabel(int? grade) {
  switch (grade) {
    case 1:
      return '좋음';
    case 2:
      return '보통';
    case 3:
      return '나쁨';
    case 4:
      return '매우나쁨';
    default:
      return '-';
  }
}

Color _pmColor(int? grade) {
  switch (grade) {
    case 1:
      return const Color(0xFF1FA463);
    case 2:
      return const Color(0xFF3A7BD5);
    case 3:
      return const Color(0xFFE8743B);
    case 4:
      return const Color(0xFFD23B3B);
    default:
      return Colors.black54;
  }
}

class _NearbySection extends StatelessWidget {
  const _NearbySection({required this.controller});
  final LaundryHomeController controller;

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapFullscreenScreen(controller: controller),
      ),
    );
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/icons/256/laundry_room.png', width: 20, height: 20),
            const SizedBox(width: 6),
            const Text('내 주변 빨래방',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (controller.laundromatsIsMock) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE0B84A)),
                ),
                child: const Text(
                  '예시',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8C6A1F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openFullscreen(context),
              icon: const Icon(Icons.fullscreen, size: 16),
              label: const Text('지도 크게 보기'),
              style: TextButton.styleFrom(
                foregroundColor: controller.currentAccentColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: KakaoMapView(
                      latitude: controller.lat,
                      longitude: controller.lng,
                      onTap: (_, _) {},
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: () => _openFullscreen(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen,
                              size: 16, color: Color(0xFF1A2230)),
                          SizedBox(width: 4),
                          Text('지도보기',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2230),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.laundromatsIsMock)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '카카오 장소 검색을 사용할 수 없어 예시 데이터를 표시 중입니다.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
            ),
          ),
        _LaundromatList(controller: controller, onOpen: _open),
      ],
    );
  }
}

class _LaundromatList extends StatelessWidget {
  const _LaundromatList({required this.controller, required this.onOpen});
  final LaundryHomeController controller;
  final Future<void> Function(String?) onOpen;

  @override
  Widget build(BuildContext context) {
    final list = controller.laundromats;
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3EAF3)),
        ),
        child: Center(
          child: controller.laundromatsLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('주변 빨래방 검색 결과가 없어요',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
        ),
      );
    }
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final m = list[index];
          return InkWell(
            onTap: m.placeUrl != null ? () => onOpen(m.placeUrl) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 184,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3EAF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/icons/256/laundry_room.png',
                          width: 18, height: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (m.placeUrl != null)
                        const Icon(Icons.open_in_new,
                            size: 14, color: Colors.black26),
                    ],
                  ),
                  Text(
                    m.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    m.distanceMeters >= 1000
                        ? '${(m.distanceMeters / 1000).toStringAsFixed(1)}km'
                        : '${m.distanceMeters}m',
                    style: TextStyle(
                      color: controller.currentAccentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 오늘 추천 시각 박스 시작 시각 + 45분(세탁) hangAt 으로 "HH:MM ~ HH:MM" 라벨 생성.
/// 백엔드 timeline entry 에는 hangAt 이 없어 클라이언트에서 +45분 추정. 백엔드의
/// `formatStartRange` 와 동일 식.
String _formatTodayRecoRange(DateTime start) {
  final hang = start.add(const Duration(minutes: 45));
  return '${formatKstHm(start)} ~ ${formatKstHm(hang)}';
}

/// 건조 완료 시각 라벨 — "HH:mm 완료" (오늘 아니면 "내일 HH:mm 완료").
/// null(못 마름/미제공)이면 라벨 없음.
String? _formatCompletion(DateTime? completionAt) {
  if (completionAt == null) return null;
  final c = toKst(completionAt);
  final cMidnight = DateTime.utc(c.year, c.month, c.day);
  final days = cMidnight.difference(kstStartOfToday()).inDays;
  final prefix = days <= 0
      ? ''
      : days == 1
          ? '내일 '
          : days == 2
              ? '모레 '
              : '';
  return '$prefix${formatKstHm(completionAt)} 완료';
}

/// 점수 카드 내부의 라벨+값 한 줄 박스.
/// 추천 시간 / 예상 건조 시간 공용. `tailLabel` 이 지정되면 우측 끝에 작은
/// 보조 라벨이 표시됨 (예: "내일 추천").
class _ScoreInfoRow extends StatelessWidget {
  const _ScoreInfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
    this.tailLabel,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;
  final String? tailLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          if (tailLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              tailLabel!,
              style: TextStyle(
                fontSize: 10,
                color: valueColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 같은 날씨 조건에서 실외/실내 점수를 나란히 비교.
/// 점수 카드의 큰 숫자(overallScore)는 사용자가 고른 건조 장소 기반이므로,
/// 다른 장소를 골랐을 때 얼마나 달라지는지 한눈에 보이게 한다.
class _IndoorOutdoorRow extends StatelessWidget {
  const _IndoorOutdoorRow({
    required this.outdoorScore,
    required this.indoorScore,
  });

  final int outdoorScore;
  final int indoorScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompareChip(
            icon: Icons.wb_sunny_outlined,
            label: '실외',
            score: outdoorScore,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CompareChip(
            icon: Icons.home_outlined,
            label: '실내',
            score: indoorScore,
          ),
        ),
      ],
    );
  }
}

class _CompareChip extends StatelessWidget {
  const _CompareChip({
    required this.icon,
    required this.label,
    required this.score,
  });

  final IconData icon;
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor(gradeFromScore(score));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    final envelope = controller.scoreEnvelope;
    if (envelope == null) {
      return const Card(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 점수 카드는 "featured 후보" 기준 — 오늘이 빨래할 만하면(≥NORMAL) 오늘,
    // 아니면(밤/비 등) 다음 좋은 시간대(내일 아침 등)로 롤오버. 오늘 후보가
    // 아예 없으면 envelope.score(글로벌 best) 로 폴백.
    final featured = controller.featuredEntry;
    final dayOffset = controller.featuredDayOffset;
    final dayLabel = dayOffsetLabel(dayOffset); // '' | 내일 | 모레 …
    final loading = controller.loading;

    final int overallScore =
        featured?.overallScore ?? envelope.score.overallScore;
    final String rawGrade = (featured?.grade.isNotEmpty ?? false)
        ? featured!.grade
        : envelope.score.grade;
    final grade =
        rawGrade.isNotEmpty ? rawGrade : gradeFromScore(overallScore);
    if (kDebugMode) {
      final recomputed = gradeFromScore(overallScore);
      if (rawGrade.isNotEmpty && recomputed != rawGrade) {
        debugPrint(
            '[Ppallae] grade mismatch: server=$rawGrade flutter=$recomputed score=$overallScore');
      }
    }
    final color = _gradeColor(grade);
    final iconAsset = _gradeIconAsset(grade);

    // 추천 시간 박스 라벨 = "(내일) HH:MM ~ HH:MM". 종료 시각은 시작 + 45분(세탁) hangAt 추정.
    final hasRecommendation = featured != null;
    final String range = hasRecommendation
        ? (dayLabel.isEmpty
            ? _formatTodayRecoRange(featured.forecastAt)
            : '$dayLabel ${_formatTodayRecoRange(featured.forecastAt)}')
        : '지금은 빨래 추천이 어려워요';
    final double dryMin =
        featured?.estimatedDryHoursMin ?? envelope.score.estimatedDryHoursMin;
    final double dryMax =
        featured?.estimatedDryHoursMax ?? envelope.score.estimatedDryHoursMax;
    // "몇 시에 다 마른다" — 백엔드 완료 절대시각(KST). 못 마르면 null → 라벨 미표시.
    final completionLabel = _formatCompletion(
      envelope.score.estimatedCompletionAt,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 상단: 큰 이모지 + 점수 + 등급 (한눈에) ──
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(iconAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 보조 라벨: 큰 숫자가 "지금 점수"가 아니라
                    // "30시간 안 최적 시점의 점수"임을 명시.
                    Text(
                      hasRecommendation
                          ? '추천 시점 기준 점수'
                          : '오늘 최고 기준 점수',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          gradeLabel(grade),
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$overallScore점',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (loading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── 추천 빨래 시간 ──
          // featured 시각. 오늘이 가망 없으면 "내일 10:00 ~ …" 처럼 day 접두가 붙는다.
          const SizedBox(height: 14),
          _ScoreInfoRow(
            label: '추천 시간',
            value: range,
            valueColor: color,
            bgColor: color.withValues(alpha: 0.08),
            // range 에 "내일"이 이미 포함되므로 tail 배지는 중복 — 미표시.
            tailLabel: null,
          ),
          // ── 예상 건조 시간 (+ 완료 시각) ──
          const SizedBox(height: 8),
          _ScoreInfoRow(
            label: '예상 건조 시간',
            value: _formatDryTime(dryMin, dryMax),
            valueColor: color,
            bgColor: color.withValues(alpha: 0.08),
            tailLabel: completionLabel, // 예: "12:31 완료"
          ),
          // ── 실외 vs 실내 점수 비교 (featured 시점 기준) ──
          const SizedBox(height: 8),
          _IndoorOutdoorRow(
            outdoorScore: controller.featuredOutdoor?.overallScore ??
                envelope.score.outdoorScore,
            indoorScore: controller.featuredIndoor?.overallScore ??
                envelope.score.indoorScore,
          ),
          if (envelope.score.warningTexts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...envelope.score.warningTexts.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LaundryTypeSelector extends StatelessWidget {
  const _LaundryTypeSelector({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    final types = controller.laundryTypes;
    // 백엔드에서 받은 타입 메타데이터. cautionText/예시/설명을 long-press 시
    // 보여주기 위해 모델 참조를 유지한다.
    final byCode = {for (final t in types) t.code: t};

    final fallback = [
      ('LIGHT', '얇음'),
      ('MEDIUM', '중간'),
      ('HEAVY', '두꺼움'),
    ];
    final items = types.isNotEmpty
        ? types.map((t) => (t.code, t.nameKo)).toList()
        : fallback;

    return _SelectorSection(
      title: '빨래 종류',
      child: Row(
        children: items.map((item) {
          final selected = controller.laundryTypeCode == item.$1;
          final meta = byCode[item.$1];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onLongPress: meta == null
                    ? null
                    : () => _showLaundryTypeSheet(context, meta),
                child: _PpallaePill(
                  iconAsset: _laundryIconByCode[item.$1] ??
                      'assets/icons/256/laundry_room.png',
                  label: item.$2,
                  selected: selected,
                  accent: controller.currentAccentColor,
                  accentLight: controller.currentAccentColorLight,
                  onTap: () => controller.selectLaundryType(item.$1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLaundryTypeSheet(BuildContext context, LaundryTypeModel meta) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  _laundryIconByCode[meta.code] ??
                      'assets/icons/256/laundry_room.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 8),
                Text(meta.nameKo,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(meta.description,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
            if (meta.examples.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('예시: ${meta.examples.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            const SizedBox(height: 10),
            Text(
              '예상 건조 시간 ${meta.baseDryHoursMin.toStringAsFixed(0)}~'
              '${meta.baseDryHoursMax.toStringAsFixed(0)}시간 (날씨 조건에 따라 달라짐)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (meta.cautionText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0B84A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFF8C6A1F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta.cautionText,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8C6A1F)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _laundryIconByCode = {
  'LIGHT': 'assets/icons/256/laundry_light.png',
  'MEDIUM': 'assets/icons/256/laundry_medium.png',
  'HEAVY': 'assets/icons/256/laundry_heavy.png',
};

class _DryingPlaceSelector extends StatelessWidget {
  const _DryingPlaceSelector({required this.controller});
  final LaundryHomeController controller;

  // 실외 → 실내 → 베란다 순 (DryingPlace enum 선언 순서와 동일).
  // 자연 건조만 노출 (제습기/건조기 제외).
  static const Map<DryingPlace, String> _icons = {
    DryingPlace.outdoor: 'assets/icons/256/drying_outdoor.png',
    DryingPlace.indoor: 'assets/icons/256/drying_indoor.png',
    DryingPlace.balcony: 'assets/icons/256/drying_balcony.png',
  };

  @override
  Widget build(BuildContext context) {
    return _SelectorSection(
      title: '건조 장소',
      child: Row(
        children: DryingPlace.values.map((place) {
          final selected = controller.dryingPlace == place;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _PpallaePill(
                iconAsset: _icons[place] ??
                    'assets/icons/256/laundry_room.png',
                label: place.label,
                selected: selected,
                accent: controller.currentAccentColor,
                accentLight: controller.currentAccentColorLight,
                onTap: () => controller.selectDryingPlace(place),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 빨래빨래 전용 셀렉터 필. 좌측 아이콘 PNG + 우측 라벨, 선택 시 등급 색 그라데이션.
/// 액센트 색은 호출자(=controller 의 currentAccentColor)에서 주입.
class _PpallaePill extends StatelessWidget {
  const _PpallaePill({
    required this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.accentLight,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color accentLight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [accentLight, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE3EAF3),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 20, height: 20),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1A2230),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorSection extends StatelessWidget {
  const _SelectorSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.black54)),
        ),
        child,
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.timeline, required this.accent});
  final Color accent;
  final TimelineEnvelopeModel timeline;

  @override
  Widget build(BuildContext context) {
    final entries = timeline.timeline.take(24).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: accent),
                const SizedBox(width: 6),
                const Text('시간별 예보',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _HourCard(entry: entries[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourCard extends StatelessWidget {
  const _HourCard({required this.entry});
  final TimelineEntryModel entry;

  @override
  Widget build(BuildContext context) {
    // 백엔드 grade 우선. 빈 값일 때만 점수 기반 fallback.
    final grade = entry.grade.isNotEmpty
        ? entry.grade
        : gradeFromScore(entry.overallScore);
    final color = _gradeColor(grade);
    // 백엔드 displayTime 은 추천 후보의 시작 시각(5분 ceiling 결과)이라 ":15", ":30"
    // 같은 분이 섞인다. 사용자 직관을 위해 모바일에서 정시로 강제 표기.
    // 실제 후보 시각과 살짝 다를 수 있으나 시간별 예보의 가독성을 우선.
    final timeLabel = _formatTimelineHour(entry.forecastAt);
    // 백엔드가 시간대별 예상 건조 시간도 같이 보내준다. 표시해서
    // "이 시점에 널면 N시간" 정보를 사용자에게 제공.
    final dryRange = _formatTimelineDry(
      entry.estimatedDryHoursMin,
      entry.estimatedDryHoursMax,
    );
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeLabel,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Icon(_weatherIcon(entry.precipType, entry.skyCondition),
              color: _weatherColor(entry.precipType, entry.skyCondition),
              size: 24),
          Text('${entry.temperatureC.round()}°',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${entry.overallScore}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          if (dryRange != null)
            Text(
              dryRange,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
        ],
      ),
    );
  }
}

/// 0~24h 범위의 건조시간 간단 라벨. 값이 0이거나 비현실적이면 숨김.
String? _formatTimelineDry(double min, double max) {
  if (min <= 0 && max <= 0) return null;
  if (max >= 24) return '24h+';
  if ((max - min).abs() < 0.1) return '~${max.toStringAsFixed(0)}h';
  return '${min.toStringAsFixed(0)}~${max.toStringAsFixed(0)}h';
}

/// 시간별 카드 라벨용 — 분 정보 무시하고 정시(HH시)로 표기 (KST 기준).
/// 백엔드 후보가 :15, :30 등 5분 ceiling 시각이라도 사용자에겐 정시로 보임.
String _formatTimelineHour(DateTime dateTime) {
  final hour = toKst(dateTime).hour.toString().padLeft(2, '0');
  return '$hour시';
}

IconData _weatherIcon(String precip, String sky) {
  if (precip == 'RAIN') return Icons.umbrella;
  if (precip == 'SNOW') return Icons.ac_unit;
  if (precip == 'SLEET') return Icons.grain;
  switch (sky) {
    case 'CLEAR':
      return Icons.wb_sunny;
    case 'PARTLY_CLOUDY':
      return Icons.wb_cloudy_outlined;
    case 'CLOUDY':
    case 'OVERCAST':
      return Icons.cloud;
    default:
      return Icons.wb_sunny;
  }
}

Color _weatherColor(String precip, String sky) {
  if (precip != 'NONE') return const Color(0xFF4A90D9);
  if (sky == 'CLEAR') return const Color(0xFFF5A623);
  return const Color(0xFF9AA7B5);
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3F3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text('데이터를 불러오지 못했어요\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

Color _gradeColor(String grade) {
  switch (grade) {
    // 파스텔 톤 — 신호등 스케일 (파랑→초록→노랑→주황→빨강)
    case 'EXCELLENT':
      return const Color(0xFF5BA3D3); // 파스텔 스카이블루
    case 'GOOD':
      return const Color(0xFF5DAB6C); // 세이지 그린
    case 'NORMAL':
      return const Color(0xFFE5B946); // 머스타드 옐로우
    case 'BAD':
      return const Color(0xFFE89464); // 소프트 오렌지
    case 'VERY_BAD':
      return const Color(0xFFD17878); // 로지 레드
    default:
      return Colors.grey;
  }
}

String _gradeIconAsset(String grade) {
  switch (grade) {
    case 'EXCELLENT':
      return 'assets/icons/256/grade_excellent.png';
    case 'GOOD':
      return 'assets/icons/256/grade_good.png';
    case 'NORMAL':
      return 'assets/icons/256/grade_normal.png';
    case 'BAD':
      return 'assets/icons/256/grade_bad.png';
    case 'VERY_BAD':
      return 'assets/icons/256/grade_very_bad.png';
    default:
      return 'assets/icons/256/grade_normal.png';
  }
}


String _fmt(double h) {
  if (h == h.roundToDouble()) return h.toInt().toString();
  return h.toStringAsFixed(1);
}

String _formatDryTime(double min, double max) {
  if (min >= 24) return '하루 이상';
  if (min >= 12) return '12시간 이상';
  final lo = _fmt(min);
  final hi = _fmt(max);
  return lo == hi ? '약 $lo시간' : '$lo~$hi시간';
}
