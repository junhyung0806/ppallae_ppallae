// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../../core/error_codes.dart';

Widget buildKakaoMapView({
  required double latitude,
  required double longitude,
  required void Function(double lat, double lng) onTap,
}) {
  return _KakaoMapViewWeb(
    latitude: latitude,
    longitude: longitude,
    onTap: onTap,
  );
}

class _KakaoMapViewWeb extends StatefulWidget {
  const _KakaoMapViewWeb({
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double latitude;
  final double longitude;
  final void Function(double lat, double lng) onTap;

  @override
  State<_KakaoMapViewWeb> createState() => _KakaoMapViewWebState();
}

class _KakaoMapViewWebState extends State<_KakaoMapViewWeb> {
  static const _maxRetry = 40;

  late final String _viewType;
  late final html.DivElement _container;

  js.JsObject? _map;
  js.JsObject? _marker;
  Timer? _retryTimer;
  Timer? _layoutWatchdog;
  int _retry = 0;
  bool _ready = false;
  String _message = '지도를 불러오는 중입니다';

  @override
  void initState() {
    super.initState();
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    _viewType = 'ppallae-kakao-map-$suffix';
    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.minHeight = '300px'
      ..style.overflow = 'hidden';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return _container;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleInit());

    // 컨테이너 크기가 잡히면 relayout
    _layoutWatchdog = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      if (_map == null &&
          (_container.isConnected ?? false) &&
          _container.clientWidth > 0 &&
          _container.clientHeight > 0) {
        _scheduleInit();
      } else if (_map != null) {
        // 400ms 주기 relayout — 전환 애니메이션 중 일시 실패는 정상이고
        // 매 tick 로깅하면 스팸이 되므로 의도적으로 조용히 무시한다.
        try {
          _map!.callMethod('relayout');
        } catch (_) {}
      }
    });
  }

  @override
  void didUpdateWidget(covariant _KakaoMapViewWeb old) {
    super.didUpdateWidget(old);
    if (old.latitude != widget.latitude || old.longitude != widget.longitude) {
      _recenter();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _layoutWatchdog?.cancel();
    super.dispose();
  }

  void _scheduleInit() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 120), _init);
  }

  void _init() {
    if (_map != null) return;

    final kakao = js.context['kakao'];
    final scriptLoaded = js.context['__kakaoSdkScriptLoaded'] == true;
    final loadError = js.context['__kakaoSdkLoadError'] == true;

    if (loadError) {
      _fail('카카오 지도 SDK 로딩에 실패했어요. (도메인 등록 확인 필요)');
      return;
    }

    final containerReady = (_container.isConnected ?? false) &&
        _container.clientWidth > 0 &&
        _container.clientHeight > 0;

    if (!scriptLoaded || kakao == null || !containerReady) {
      _retryInit();
      return;
    }

    final maps = kakao['maps'];
    if (maps == null) {
      _retryInit();
      return;
    }

    // autoload=false → kakao.maps.load 콜백 후 생성
    final loadFn = maps['load'];
    if (loadFn is js.JsFunction) {
      loadFn.apply([
        js.JsFunction.withThis((_) => _createMap(maps as js.JsObject)),
      ]);
    } else {
      _createMap(maps as js.JsObject);
    }
  }

  void _retryInit() {
    if (_retry >= _maxRetry) {
      _fail('지도 영역 준비가 지연되고 있어요. 새로고침 해보세요.');
      return;
    }
    _retry += 1;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 200), _init);
  }

  void _createMap(js.JsObject maps) {
    try {
      final center = js.JsObject(maps['LatLng'] as js.JsFunction, [
        widget.latitude,
        widget.longitude,
      ]);
      final options = js.JsObject.jsify({'center': center, 'level': 5});
      _map = js.JsObject(maps['Map'] as js.JsFunction, [_container, options]);
      _placeMarker(maps, widget.latitude, widget.longitude);

      // 지도 클릭 → 좌표 콜백
      final event = maps['event'] as js.JsObject;
      event.callMethod('addListener', [
        _map,
        'click',
        js.JsFunction.withThis((_, mouseEvent) {
          final latlng = (mouseEvent as js.JsObject)['latLng'] as js.JsObject;
          final lat = (latlng.callMethod('getLat') as num).toDouble();
          final lng = (latlng.callMethod('getLng') as num).toDouble();
          _placeMarker(maps, lat, lng);
          widget.onTap(lat, lng);
        }),
      ]);

      _map!.callMethod('relayout');
      _retry = 0;
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      _fail('지도 생성 중 오류가 발생했어요: $e');
    }
  }

  void _placeMarker(js.JsObject maps, double lat, double lng) {
    final pos = js.JsObject(maps['LatLng'] as js.JsFunction, [lat, lng]);
    if (_marker == null) {
      _marker = js.JsObject(maps['Marker'] as js.JsFunction, [
        js.JsObject.jsify({'position': pos}),
      ]);
      _marker!.callMethod('setMap', [_map]);
    } else {
      _marker!.callMethod('setPosition', [pos]);
    }
  }

  void _recenter() {
    final kakao = js.context['kakao'];
    final maps = kakao?['maps'];
    if (_map == null || maps == null) return;
    try {
      final center = js.JsObject(maps['LatLng'] as js.JsFunction, [
        widget.latitude,
        widget.longitude,
      ]);
      _map!.callMethod('setCenter', [center]);
      _placeMarker(maps as js.JsObject, widget.latitude, widget.longitude);
    } catch (e) {
      PpallaeError(ErrorCodes.mapMarker, '지도 위치 갱신에 실패했어요.', e.toString())
          .log();
    }
  }

  void _fail(String message) {
    PpallaeError(ErrorCodes.mapInit, message).log();
    if (mounted) {
      setState(() {
        _ready = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_ready)
          ColoredBox(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    const SizedBox(height: 12),
                    Text(_message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
