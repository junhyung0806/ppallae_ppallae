import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

// 웹 index.html과 동일한 카카오 JavaScript 키 (공개 키, 도메인 등록으로 보호)
const _kakaoJsKey = '028e4dd5f3256a25d2e9e11ae30a9eb3';
bool _authInitialized = false;

/// 모바일(Android/iOS)용 카카오맵 — kakao_map_plugin(WebView + JS SDK) 사용.
Widget buildKakaoMapView({
  required double latitude,
  required double longitude,
  required void Function(double lat, double lng) onTap,
}) {
  return _KakaoMapMobile(
    latitude: latitude,
    longitude: longitude,
    onTap: onTap,
  );
}

class _KakaoMapMobile extends StatefulWidget {
  const _KakaoMapMobile({
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onTap;

  @override
  State<_KakaoMapMobile> createState() => _KakaoMapMobileState();
}

class _KakaoMapMobileState extends State<_KakaoMapMobile> {
  KakaoMapController? _controller;

  static const _markerId = 'selected';

  @override
  void initState() {
    super.initState();
    if (!_authInitialized) {
      // baseUrl = WebView origin. 카카오 콘솔에 등록된 도메인이어야 SDK가 로드됨
      // (미지정 시 origin이 about:blank가 되어 지도 JS가 안 뜸).
      AuthRepository.initialize(
        appKey: _kakaoJsKey,
        baseUrl: 'http://localhost:8080',
      );
      _authInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant _KakaoMapMobile old) {
    super.didUpdateWidget(old);
    if (old.latitude != widget.latitude || old.longitude != widget.longitude) {
      final ll = LatLng(widget.latitude, widget.longitude);
      _controller?.setCenter(ll);
      _placeMarker(ll);
    }
  }

  Future<void> _placeMarker(LatLng ll) async {
    final c = _controller;
    if (c == null) return;
    await c.clearMarker();
    await c.addMarker(
      markers: [Marker(markerId: _markerId, latLng: ll)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);
    return KakaoMap(
      center: center,
      currentLevel: 5,
      markers: [Marker(markerId: _markerId, latLng: center)],
      onMapCreated: (controller) {
        _controller = controller;
      },
      onMapTap: (latLng) {
        _placeMarker(latLng);
        widget.onTap(latLng.latitude, latLng.longitude);
      },
    );
  }
}
