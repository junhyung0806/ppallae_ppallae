import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

// 웹 index.html과 동일한 카카오 JavaScript 키 (공개 키, 도메인 등록으로 보호).
// TODO(release): 출시 전 비즈니스 채널의 JS 키로 교체.
//   - 카카오 개발자 콘솔의 "Web 플랫폼 사이트 도메인" 에
//     아래 baseUrl(_KakaoMapMobileState.initState)이 등록돼야 SDK가 로드됨.
//   - 키 값은 채팅/PR에 평문 노출 금지, 보안 채널로 전달.
//   - web/index.html 의 appkey 2곳도 함께 갱신.
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
      // TODO(release): baseUrl 을 운영 도메인(예: https://ppallae.app)으로 교체하고
      //   카카오 개발자 콘솔의 Web 플랫폼 등록 도메인과 정확히 일치시킬 것.
      //   값 mismatch 시 모바일 지도는 빈 화면이 된다.
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
    try {
      await c.clearMarker();
      await c.addMarker(
        markers: [Marker(markerId: _markerId, latLng: ll)],
      );
    } catch (e) {
      // kakao_map_plugin이 일부 환경에서 JS 초기화 늦어 clearMarker/addMarker
      // not defined 에러를 던지는 경우 있음. 초기 markers prop으로 이미 그려진
      // 마커가 있으므로 무시. 다음 didUpdateWidget에서 재시도됨.
      debugPrint('PpallaeMap _placeMarker skip: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);
    return KakaoMap(
      center: center,
      currentLevel: 4, // 더 가깝게 보여 마커가 잘 보이도록 (5 → 4)
      markers: [Marker(markerId: _markerId, latLng: center)],
      onMapCreated: (controller) {
        _controller = controller;
      },
      onMapTap: (latLng) {
        // 탭 시 _placeMarker 직접 호출 X. controller.selectByCoords가 lat/lng를
        // 갱신하면 didUpdateWidget이 setCenter+_placeMarker를 호출해 핀이 이동함.
        widget.onTap(latLng.latitude, latLng.longitude);
      },
    );
  }
}
