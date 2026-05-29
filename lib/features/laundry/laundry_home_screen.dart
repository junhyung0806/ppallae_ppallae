import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/api_models.dart';
import 'laundry_home_controller.dart';
import 'map/kakao_map_view.dart';
import 'region_search_screen.dart';

class LaundryHomeScreen extends StatelessWidget {
  const LaundryHomeScreen({super.key, required this.controller});

  final LaundryHomeController controller;

  LaundryHomeController get _controller => controller;

  Future<void> _openRegionSearch(BuildContext context) async {
    final region = await Navigator.of(context).push<RegionModel>(
      MaterialPageRoute(
        builder: (_) => RegionSearchScreen(apiClient: _controller.api),
      ),
    );
    if (region != null) {
      await _controller.selectRegion(region);
    }
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
              onRefresh: _controller.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _AppHeader(),
                  const SizedBox(height: 12),
                  _RegionHeader(
                    controller: _controller,
                    onSearch: () => _openRegionSearch(context),
                  ),
                  if (_controller.favorites.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _FavoritesBar(controller: _controller),
                  ],
                  if (_controller.locationNotice != null) ...[
                    const SizedBox(height: 12),
                    _LocationNoticeBanner(controller: _controller),
                  ],
                  const SizedBox(height: 16),
                  if (_controller.error != null)
                    _ErrorCard(
                      message: _controller.error!,
                      onRetry: _controller.refresh,
                    )
                  else if (_controller.scoreEnvelope == null)
                    const _LoadingState()
                  else ...[
                    _ScoreCard(
                      envelope: _controller.scoreEnvelope,
                      loading: _controller.loading,
                    ),
                    const SizedBox(height: 12),
                    _WeatherSummaryCard(
                      weather: _controller.scoreEnvelope!.weather,
                    ),
                    const SizedBox(height: 16),
                    _RecommendedTimeCard(
                      timeline: _controller.timeline,
                      score: _controller.scoreEnvelope?.score,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MapSection(controller: _controller),
                  const SizedBox(height: 16),
                  _LaundryTypeSelector(controller: _controller),
                  const SizedBox(height: 16),
                  _DryingPlaceSelector(controller: _controller),
                  const SizedBox(height: 16),
                  _AmountSelector(controller: _controller),
                  const SizedBox(height: 16),
                  if (_controller.timeline != null)
                    _TimelineCard(timeline: _controller.timeline!),
                  const SizedBox(height: 16),
                  _LaundromatsSection(controller: _controller),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF3A7BD5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.local_laundry_service,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          '빨래빨래',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A2230),
          ),
        ),
        const Spacer(),
        Text(
          _todayLabel(),
          style: const TextStyle(fontSize: 13, color: Colors.black45),
        ),
      ],
    );
  }
}

String _todayLabel() {
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  final now = DateTime.now();
  return '${now.month}월 ${now.day}일 (${week[now.weekday - 1]})';
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
                _WeatherChip(
                    icon: Icons.blur_on,
                    label: '미세먼지',
                    value: _pmLabel(weather.pm10Grade),
                    valueColor: _pmColor(weather.pm10Grade)),
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

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.controller, required this.onSearch});
  final LaundryHomeController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.place, color: Color(0xFF3A7BD5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            controller.region.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: controller.isCurrentFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
          onPressed: controller.toggleFavorite,
          icon: Icon(
            controller.isCurrentFavorite ? Icons.star : Icons.star_border,
            color: const Color(0xFFE0A100),
          ),
        ),
        IconButton(
          tooltip: '현재 위치',
          onPressed: controller.locating
              ? null
              : () => controller.useCurrentLocation(),
          icon: controller.locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, color: Colors.black54),
        ),
        IconButton(
          tooltip: '지역 검색',
          onPressed: onSearch,
          icon: const Icon(Icons.search, color: Colors.black54),
        ),
      ],
    );
  }
}

class _FavoritesBar extends StatelessWidget {
  const _FavoritesBar({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fav = controller.favorites[index];
          final selected = fav.admCode == controller.region.admCode;
          return InputChip(
            label: Text('${fav.sigungu} ${fav.eupmyeondong}'),
            selected: selected,
            onPressed: () => controller.selectRegion(fav),
            onDeleted: () => controller.removeFavorite(fav.admCode),
            deleteIcon: const Icon(Icons.close, size: 16),
          );
        },
      ),
    );
  }
}

class _RecommendedTimeCard extends StatelessWidget {
  const _RecommendedTimeCard({required this.timeline, required this.score});
  final TimelineEnvelopeModel? timeline;
  final LaundryScoreModel? score;

  @override
  Widget build(BuildContext context) {
    final range = timeline?.bestStartTimeRange;
    final hasRecommendation = range != null;
    final color =
        hasRecommendation ? const Color(0xFF1FA463) : const Color(0xFFE8743B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasRecommendation
              ? [const Color(0xFF2FB36F), const Color(0xFF1FA463)]
              : [const Color(0xFFF0954B), const Color(0xFFE8743B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '추천 빨래 시간',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRecommendation ? range : '오늘은 빨래 추천이 어려워요',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRecommendation
                      ? '이 시간에 널면 가장 잘 말라요'
                      : '실내 건조나 건조기를 추천해요',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('지도에서 위치 선택',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 6),
            const Text('지도를 탭하면 그 지역으로 바뀌어요',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: KakaoMapView(
              latitude: controller.lat,
              longitude: controller.lng,
              onTap: (lat, lng) => controller.selectByCoords(lat, lng),
            ),
          ),
        ),
      ],
    );
  }
}

class _LaundromatsSection extends StatelessWidget {
  const _LaundromatsSection({required this.controller});
  final LaundryHomeController controller;

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = controller.laundromats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내 주변 빨래방',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
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
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final m = list[index];
                return InkWell(
                  onTap: m.placeUrl != null ? () => _open(m.placeUrl) : null,
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
                            const Icon(Icons.local_laundry_service,
                                size: 18, color: Color(0xFF3A7BD5)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
                          style: const TextStyle(
                            color: Color(0xFF3A7BD5),
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
          ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.envelope, required this.loading});
  final ScoreEnvelopeModel? envelope;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (envelope == null) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final score = envelope!.score;
    final color = _gradeColor(score.grade);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${score.overallScore}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text('점', style: TextStyle(fontSize: 24)),
                if (loading) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _gradeLabel(score.grade),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              score.recommendationText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Metric(
                  icon: Icons.timer_outlined,
                  label: '예상 건조',
                  value: _formatDryTime(
                    score.estimatedDryHoursMin,
                    score.estimatedDryHoursMax,
                  ),
                ),
                _Metric(
                  icon: Icons.wb_sunny_outlined,
                  label: '실외/실내',
                  value: '${score.outdoorScore}/${score.indoorScore}',
                ),
              ],
            ),
            if (score.warningTexts.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...score.warningTexts.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (envelope!.stale)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('업데이트 지연',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                Text(
                  '기준: ${_fmtTime(envelope!.generatedAt)}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3A7BD5)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LaundryTypeSelector extends StatelessWidget {
  const _LaundryTypeSelector({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    final types = controller.laundryTypes;
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
      child: Wrap(
        spacing: 8,
        children: items.map((item) {
          final selected = controller.laundryTypeCode == item.$1;
          return ChoiceChip(
            label: Text(item.$2),
            selected: selected,
            onSelected: (_) => controller.selectLaundryType(item.$1),
          );
        }).toList(),
      ),
    );
  }
}

class _DryingPlaceSelector extends StatelessWidget {
  const _DryingPlaceSelector({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return _SelectorSection(
      title: '건조 장소',
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: DryingPlace.values.map((place) {
          final selected = controller.dryingPlace == place;
          return ChoiceChip(
            label: Text(place.label),
            selected: selected,
            onSelected: (_) => controller.selectDryingPlace(place),
          );
        }).toList(),
      ),
    );
  }
}

class _AmountSelector extends StatelessWidget {
  const _AmountSelector({required this.controller});
  final LaundryHomeController controller;

  @override
  Widget build(BuildContext context) {
    return _SelectorSection(
      title: '빨래 양',
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: LaundryAmount.values.map((amount) {
          final selected = controller.laundryAmount == amount;
          return ChoiceChip(
            label: Text(amount.label),
            selected: selected,
            onSelected: (_) => controller.selectAmount(amount),
          );
        }).toList(),
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
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.timeline});
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
            const Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Color(0xFF3A7BD5)),
                SizedBox(width: 6),
                Text('시간별 예보',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
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
    final color = _gradeColor(entry.grade);
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${entry.hourOfDay}시',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Icon(_weatherIcon(entry.precipType, entry.skyCondition),
              color: _weatherColor(entry.precipType, entry.skyCondition),
              size: 26),
          Text('${entry.temperatureC.round()}°',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
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
        ],
      ),
    );
  }
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
    case 'EXCELLENT':
      return const Color(0xFF1FA463);
    case 'GOOD':
      return const Color(0xFF3A7BD5);
    case 'NORMAL':
      return const Color(0xFFE0A100);
    case 'BAD':
      return const Color(0xFFE8743B);
    case 'VERY_BAD':
      return const Color(0xFFD23B3B);
    default:
      return Colors.grey;
  }
}

String _gradeLabel(String grade) {
  switch (grade) {
    case 'EXCELLENT':
      return '최고';
    case 'GOOD':
      return '좋음';
    case 'NORMAL':
      return '보통';
    case 'BAD':
      return '나쁨';
    case 'VERY_BAD':
      return '매우 나쁨';
    default:
      return grade;
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

String _fmtTime(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
