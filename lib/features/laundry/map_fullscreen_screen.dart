import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/api_models.dart';
import 'laundry_home_controller.dart';
import 'map/kakao_map_view.dart';
import 'region_search_screen.dart';

class MapFullscreenScreen extends StatelessWidget {
  const MapFullscreenScreen({super.key, required this.controller});

  final LaundryHomeController controller;

  Future<void> _openPlace(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSearch(BuildContext context) async {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
        title: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return _AppBarRow(
              region: controller.region.displayName,
              onSearch: () => _openSearch(context),
            );
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: KakaoMapView(
                  latitude: controller.lat,
                  longitude: controller.lng,
                  onTap: (lat, lng) => controller.selectByCoords(lat, lng),
                ),
              ),
              // 화면 중앙 따라다니는 핀은 제거. 카카오 플러그인의 마커가
              // 실제 lat/lng 좌표에 박혀 지도와 함께 이동 (=내 위치를 알려줌).
              // 내 위치로 재이동 버튼 (좌측 하단)
              Positioned(
                left: 14,
                bottom: controller.laundromats.isNotEmpty ? 136 : 24,
                child: GestureDetector(
                  onTap: controller.locating
                      ? null
                      : () => controller.useCurrentLocation(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: controller.locating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location,
                            color: Color(0xFF3A7BD5), size: 22),
                  ),
                ),
              ),
              if (controller.laundromats.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.laundromats.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final m = controller.laundromats[index];
                          return _LaundromatCard(
                            laundromat: m,
                            onTap: () => _openPlace(m.placeUrl),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// AppBar 안: 좌측 짧은 지역명 + 우측에 흰 검색바 (불투명, 잘 보임)
class _AppBarRow extends StatelessWidget {
  const _AppBarRow({required this.region, required this.onSearch});
  final String region;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.place,
          size: 16,
          color: Colors.white,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
        const SizedBox(width: 4),
        Text(
          _shortRegion(region),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onSearch,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 16, color: Color(0xFF4A5763)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '지역 검색',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7B8794),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _shortRegion(String full) {
  // "서울특별시 종로구 청운동" → "종로구 청운동"
  final parts = full.split(' ');
  if (parts.length >= 3) return '${parts[1]} ${parts[2]}';
  return full;
}

class _LaundromatCard extends StatelessWidget {
  const _LaundromatCard({required this.laundromat, required this.onTap});
  final LaundromatModel laundromat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: laundromat.placeUrl != null ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 184,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/icons/256/laundry_room.png',
                    width: 20, height: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    laundromat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (laundromat.placeUrl != null)
                  const Icon(Icons.open_in_new,
                      size: 14, color: Colors.black26),
              ],
            ),
            Text(
              laundromat.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              laundromat.distanceMeters >= 1000
                  ? '${(laundromat.distanceMeters / 1000).toStringAsFixed(1)}km'
                  : '${laundromat.distanceMeters}m',
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
  }
}

