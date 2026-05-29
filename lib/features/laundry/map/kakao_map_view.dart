import 'package:flutter/material.dart';

import 'kakao_map_view_mobile.dart'
    if (dart.library.html) 'kakao_map_view_web.dart';

/// 카카오맵 위치 선택 지도.
/// - [latitude]/[longitude]: 지도 중심 + 마커 위치
/// - [onTap]: 지도를 클릭하면 클릭 좌표(lat, lng)를 전달
class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onTap;

  @override
  Widget build(BuildContext context) {
    return buildKakaoMapView(
      latitude: latitude,
      longitude: longitude,
      onTap: onTap,
    );
  }
}
