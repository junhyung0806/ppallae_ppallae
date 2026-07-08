import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/error_codes.dart';

// 카카오 JavaScript 키 — API base URL과 동일하게 빌드타임 주입.
//   flutter run/build ... --dart-define=PPALLAE_KAKAO_JS_KEY=<키>
// 미지정 시 개발용 테스트 키로 폴백(로컬 개발 편의). 운영 release 빌드는
// scripts/build_release.ps1 이 비즈니스 키를 강제 주입한다.
// TODO(release): 카카오 개발자 콘솔의 "Web 플랫폼 사이트 도메인" 에
//   아래 baseUrl(_KakaoMapMobileState.initState)이 등록돼야 SDK가 로드됨.
//   web/index.html 의 appkey 2곳도 같은 키로 갱신 (정적 파일이라 별도 치환).
const _kakaoJsKey = String.fromEnvironment(
  'PPALLAE_KAKAO_JS_KEY',
  defaultValue: '028e4dd5f3256a25d2e9e11ae30a9eb3',
);
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
      PpallaeError(ErrorCodes.mapMarker, '지도 마커 갱신을 건너뛰었어요(재시도 예정).',
              e.toString())
          .log();
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
