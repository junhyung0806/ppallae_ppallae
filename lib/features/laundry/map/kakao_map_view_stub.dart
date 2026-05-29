import 'package:flutter/material.dart';

/// 비-웹 플랫폼 스텁. (실기기 단계에서 네이티브 지도로 교체 예정)
Widget buildKakaoMapView({
  required double latitude,
  required double longitude,
  required void Function(double lat, double lng) onTap,
}) {
  return const ColoredBox(
    color: Color(0xFFEEF2F7),
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '지도는 현재 웹에서만 지원됩니다.\n(실기기는 네이티브 지도 연동 예정)',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
