// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/web_map_diagnostic.dart';
import '../../models/laundromat.dart';

class WebKakaoMapWidget extends StatefulWidget {
  const WebKakaoMapWidget({
    super.key,
    required this.currentPosition,
    required this.places,
    required this.onPlaceSelected,
    required this.onDiagnosticChanged,
    this.onPointerHoverChanged,
  });

  final LatLng currentPosition;
  final List<SelectedLaundromat> places;
  final ValueChanged<SelectedLaundromat> onPlaceSelected;
  final ValueChanged<WebMapDiagnostic> onDiagnosticChanged;
  final ValueChanged<bool>? onPointerHoverChanged;

  @override
  State<WebKakaoMapWidget> createState() => _WebKakaoMapWidgetState();
}

class _WebKakaoMapWidgetState extends State<WebKakaoMapWidget> {
  static const _maxRetryCount = 30;
  static const _currentLocationMarkerSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="34" height="34" viewBox="0 0 34 34"><circle cx="17" cy="17" r="15" fill="#2D8CFF" stroke="#ffffff" stroke-width="4"/><circle cx="17" cy="17" r="4.5" fill="#ffffff"/></svg>';
  static const _laundromatMarkerSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="34" height="40" viewBox="0 0 34 40"><path d="M17 2C9.268 2 3 8.268 3 16c0 10.2 14 22 14 22s14-11.8 14-22C31 8.268 24.732 2 17 2z" fill="#FF7A59" stroke="#ffffff" stroke-width="3"/><circle cx="17" cy="16" r="7" fill="#ffffff"/><path d="M13 12h8v2h-8zm0 4h3v6h-3zm5 0h3v6h-3z" fill="#FF7A59"/></svg>';

  late final String _viewType;
  late final String _containerId;
  late final html.DivElement _container;
  late final html.EventListener _wheelBlocker;

  js.JsObject? _map;
  final List<js.JsObject> _markers = [];
  Timer? _retryTimer;
  Timer? _layoutWatchdog;
  bool _isInitializing = false;
  bool _isMapReady = false;
  String? _userMessage;
  int _retryCount = 0;
  int _lastKnownWidth = 0;
  int _lastKnownHeight = 0;

  bool get _isContainerConnected => _container.isConnected ?? false;

  bool get _isContainerReady =>
      _isContainerConnected &&
      _container.clientWidth > 0 &&
      _container.clientHeight > 0;

  @override
  void initState() {
    super.initState();
    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch.toString();
    _viewType = 'kakao-map-view-$uniqueSuffix';
    _containerId = 'kakao-map-container-$uniqueSuffix';
    _container = html.DivElement()
      ..id = _containerId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.minHeight = '360px'
      ..style.overflow = 'hidden'
      ..style.setProperty('overscroll-behavior', 'contain');

    _wheelBlocker = (html.Event event) {
      if (event is! html.WheelEvent) {
        return;
      }

      event
        ..preventDefault()
        ..stopPropagation();
      _handleWheelZoom(event);
    };
    _container.addEventListener('wheel', _wheelBlocker, true);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return _container;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportDiagnostic(
        const WebMapDiagnostic(
          stage: 'view_registered',
          message: '웹 지도 view가 등록되었습니다.',
          details: {},
        ),
      );
      _scheduleInitialize(reason: 'first_frame');
    });

    _layoutWatchdog = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) {
        return;
      }

      final width = _container.clientWidth;
      final height = _container.clientHeight;
      final sizeChanged = width != _lastKnownWidth || height != _lastKnownHeight;
      _lastKnownWidth = width;
      _lastKnownHeight = height;

      if (_map == null &&
          !_isInitializing &&
          _isContainerConnected &&
          width > 0 &&
          height > 0) {
        _scheduleInitialize(reason: 'watchdog_ready');
        return;
      }

      if (_map != null && sizeChanged) {
        try {
          _map!.callMethod('relayout');
        } catch (_) {}
      }
    });
  }

  @override
  void didUpdateWidget(covariant WebKakaoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final centerChanged = oldWidget.currentPosition.latitude !=
            widget.currentPosition.latitude ||
        oldWidget.currentPosition.longitude != widget.currentPosition.longitude;
    final placesChanged = oldWidget.places != widget.places;

    if (centerChanged || placesChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_map != null) {
          _updateExistingMap();
        } else {
          _scheduleInitialize(reason: 'widget_updated');
        }
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _layoutWatchdog?.cancel();
    _container.removeEventListener('wheel', _wheelBlocker, true);
    super.dispose();
  }

  void _handleWheelZoom(html.WheelEvent event) {
    if (_map == null) {
      return;
    }

    try {
      final currentLevel = (_map!.callMethod('getLevel') as num?)?.toInt() ?? 4;
      final nextLevel = event.deltaY > 0 ? currentLevel + 1 : currentLevel - 1;
      final clampedLevel = nextLevel.clamp(1, 14);
      if (clampedLevel == currentLevel) {
        return;
      }
      _map!.callMethod('setLevel', [clampedLevel]);
    } catch (_) {}
  }

  void _scheduleInitialize({required String reason}) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 120), () {
      _initializeMap(reason: reason);
    });
  }

  void _initializeMap({required String reason}) {
    if (_isInitializing) {
      return;
    }

    if (_map != null) {
      _updateExistingMap();
      return;
    }

    _isInitializing = true;
    _setUserMessage('지도 영역을 준비하는 중입니다.');

    final scriptTag = _findSdkScriptTag();
    final sdkScriptLoaded = js.context['__kakaoSdkScriptLoaded'] == true;
    final sdkLoadError = js.context['__kakaoSdkLoadError'] == true;
    final sdkLoadErrorMessage =
        (js.context['__kakaoSdkLoadErrorMessage'] ?? '').toString();

    if (scriptTag == null) {
      _failOrRetry(
        stage: 'script_missing',
        code: 'MAP-001',
        message: '카카오 지도 SDK script 태그를 찾지 못했습니다.',
        userMessage: '카카오 지도 SDK script가 로드되지 않았어요.',
        details: _diagnosticDetails(
          scriptTagFound: false,
          scriptSrc: '',
          sdkLoaded: false,
          sdkLoadError: sdkLoadError,
          sdkLoadErrorMessage: sdkLoadErrorMessage,
          hasWindowKakao: false,
          hasWindowKakaoMaps: false,
          containerReady: false,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
        retryReason: reason,
      );
      return;
    }

    if (sdkLoadError) {
      _finalizeFailure(
        stage: 'script_error',
        code: 'MAP-002',
        message: '카카오 지도 SDK script 로딩에 실패했습니다.',
        userMessage: '카카오 지도 SDK script가 로드되지 않았어요.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptTag.src,
          sdkLoaded: false,
          sdkLoadError: sdkLoadError,
          sdkLoadErrorMessage: sdkLoadErrorMessage,
          hasWindowKakao: false,
          hasWindowKakaoMaps: false,
          containerReady: false,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
      );
      return;
    }

    if (!sdkScriptLoaded) {
      _failOrRetry(
        stage: 'waiting_script_load',
        code: 'MAP-003',
        message: '카카오 지도 SDK script onload를 기다리는 중입니다.',
        userMessage: '카카오 지도 SDK를 불러오는 중입니다.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptTag.src,
          sdkLoaded: false,
          sdkLoadError: sdkLoadError,
          sdkLoadErrorMessage: sdkLoadErrorMessage,
          hasWindowKakao: js.context['kakao'] != null,
          hasWindowKakaoMaps: js.context['kakao'] != null &&
              js.context['kakao']['maps'] != null,
          containerReady: false,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
        retryReason: reason,
      );
      return;
    }

    final kakao = js.context['kakao'];
    if (kakao == null) {
      _failOrRetry(
        stage: 'waiting_kakao',
        code: 'MAP-004',
        message: 'window.kakao 객체를 기다리는 중입니다.',
        userMessage: '카카오 지도 초기화를 준비 중입니다.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptTag.src,
          sdkLoaded: false,
          sdkLoadError: sdkLoadError,
          sdkLoadErrorMessage: sdkLoadErrorMessage,
          hasWindowKakao: false,
          hasWindowKakaoMaps: false,
          containerReady: false,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
        retryReason: reason,
      );
      return;
    }

    final maps = kakao['maps'];
    if (maps == null) {
      _failOrRetry(
        stage: 'waiting_maps_namespace',
        code: 'MAP-005',
        message: 'window.kakao.maps 네임스페이스를 기다리는 중입니다.',
        userMessage: '카카오 지도 네임스페이스를 준비 중입니다.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptTag.src,
          sdkLoaded: false,
          sdkLoadError: sdkLoadError,
          sdkLoadErrorMessage: sdkLoadErrorMessage,
          hasWindowKakao: true,
          hasWindowKakaoMaps: false,
          containerReady: false,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
        retryReason: reason,
      );
      return;
    }

    final loadFunction = maps['load'];
    if (_autoloadMode == 'false' && loadFunction is js.JsFunction) {
      loadFunction.apply([
        js.JsFunction.withThis((_) {
          js.context['__kakaoSdkLoaded'] = true;
          _createMapWhenContainerReady(maps as js.JsObject, scriptTag.src);
        }),
      ]);
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted || !_isInitializing || _map != null) {
          return;
        }
        _failOrRetry(
          stage: 'waiting_load_callback',
          code: 'MAP-005',
          message: 'kakao.maps.load 콜백이 아직 호출되지 않았습니다.',
          userMessage: '카카오 지도 콜백을 기다리는 중입니다.',
          details: _diagnosticDetails(
            scriptTagFound: true,
            scriptSrc: scriptTag.src,
            sdkLoaded: js.context['__kakaoSdkScriptLoaded'] == true,
            sdkLoadError: js.context['__kakaoSdkLoadError'] == true,
            sdkLoadErrorMessage:
                (js.context['__kakaoSdkLoadErrorMessage'] ?? '').toString(),
            hasWindowKakao: true,
            hasWindowKakaoMaps: true,
            containerReady: _isContainerReady,
            containerConnected: _isContainerConnected,
            containerWidth: _container.clientWidth,
            containerHeight: _container.clientHeight,
            mapCreateAttempted: false,
            mapCreated: false,
          ),
          retryReason: 'load_callback_wait',
        );
      });
    } else {
      js.context['__kakaoSdkLoaded'] = true;
      _createMapWhenContainerReady(maps as js.JsObject, scriptTag.src);
    }
  }

  void _createMapWhenContainerReady(js.JsObject maps, String scriptSrc) {
    final connected = _isContainerConnected;
    final width = _container.clientWidth;
    final height = _container.clientHeight;
    final isReady = connected && width > 0 && height > 0;

    if (!isReady) {
      _failOrRetry(
        stage: 'waiting_container_layout',
        code: 'MAP-006',
        message: '지도 컨테이너가 DOM에 연결되었는지와 크기를 기다리는 중입니다.',
        userMessage: '지도 영역 준비가 지연되고 있어 다시 시도 중입니다.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptSrc,
          sdkLoaded: js.context['__kakaoSdkLoaded'] == true,
          sdkLoadError: js.context['__kakaoSdkLoadError'] == true,
          sdkLoadErrorMessage:
              (js.context['__kakaoSdkLoadErrorMessage'] ?? '').toString(),
          hasWindowKakao: true,
          hasWindowKakaoMaps: true,
          containerReady: false,
          containerConnected: connected,
          containerWidth: width,
          containerHeight: height,
          mapCreateAttempted: false,
          mapCreated: false,
        ),
        retryReason: 'container_layout',
      );
      return;
    }

    _createMap(
      maps: maps,
      scriptSrc: scriptSrc,
      containerWidth: width,
      containerHeight: height,
    );
  }

  void _createMap({
    required js.JsObject maps,
    required String scriptSrc,
    required int containerWidth,
    required int containerHeight,
  }) {
    try {
      final center = js.JsObject(
        maps['LatLng'] as js.JsFunction,
        [
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
        ],
      );

      final options = js.JsObject.jsify({
        'center': center,
        'level': 4,
      });

      _map = js.JsObject(
        maps['Map'] as js.JsFunction,
        [_container, options],
      );

      _clearMarkers();
      _createCurrentLocationMarker(maps);
      for (final place in widget.places) {
        _createLaundryMarker(maps, place);
      }
      _map!.callMethod('relayout');

      _reportDiagnostic(
        WebMapDiagnostic(
          stage: 'map_ready',
          code: 'MAP-000',
          message: '카카오 지도가 정상적으로 생성되었습니다.',
          isReady: true,
          details: _diagnosticDetails(
            scriptTagFound: true,
            scriptSrc: scriptSrc,
            sdkLoaded: true,
            sdkLoadError: false,
            sdkLoadErrorMessage: '',
            hasWindowKakao: true,
            hasWindowKakaoMaps: true,
            containerReady: true,
            containerConnected: _isContainerConnected,
            containerWidth: containerWidth,
            containerHeight: containerHeight,
            mapCreateAttempted: true,
            mapCreated: true,
            markerCount: _markers.length,
            centerLat: widget.currentPosition.latitude,
            centerLon: widget.currentPosition.longitude,
          ),
        ),
      );

      if (mounted) {
        _retryCount = 0;
        setState(() {
          _userMessage = null;
          _isMapReady = true;
        });
      }
    } catch (error) {
      _finalizeFailure(
        stage: 'map_create_failed',
        code: 'MAP-007',
        message: '지도 생성 중 예외가 발생했습니다.',
        userMessage: '지도 생성 중 오류가 발생했습니다.',
        details: _diagnosticDetails(
          scriptTagFound: true,
          scriptSrc: scriptSrc,
          sdkLoaded: true,
          sdkLoadError: false,
          sdkLoadErrorMessage: '',
          hasWindowKakao: true,
          hasWindowKakaoMaps: true,
          containerReady: true,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: true,
          mapCreated: false,
          errorDetail: '$error',
        ),
      );
    } finally {
      _isInitializing = false;
    }
  }

  void _updateExistingMap() {
    try {
      final kakao = js.context['kakao'];
      final maps = kakao?['maps'];
      if (_map == null || maps == null) {
        return;
      }

      final center = js.JsObject(
        maps['LatLng'] as js.JsFunction,
        [
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
        ],
      );
      _map!.callMethod('setCenter', [center]);
      _clearMarkers();
      _createCurrentLocationMarker(maps as js.JsObject);
      for (final place in widget.places) {
        _createLaundryMarker(maps, place);
      }
      _map!.callMethod('relayout');

      if (mounted) {
        setState(() {
          _userMessage = null;
          _isMapReady = true;
        });
      }
    } catch (error) {
      _finalizeFailure(
        stage: 'map_update_failed',
        code: 'MAP-008',
        message: '기존 지도를 갱신하지 못했습니다.',
        userMessage: '지도 갱신 중 오류가 발생했습니다.',
        details: _diagnosticDetails(
          scriptTagFound: _findSdkScriptTag() != null,
          scriptSrc: _findSdkScriptTag()?.src ?? '',
          sdkLoaded: js.context['__kakaoSdkLoaded'] == true,
          sdkLoadError: js.context['__kakaoSdkLoadError'] == true,
          sdkLoadErrorMessage:
              (js.context['__kakaoSdkLoadErrorMessage'] ?? '').toString(),
          hasWindowKakao: js.context['kakao'] != null,
          hasWindowKakaoMaps: js.context['kakao'] != null &&
              js.context['kakao']['maps'] != null,
          containerReady: _isContainerReady,
          containerConnected: _isContainerConnected,
          containerWidth: _container.clientWidth,
          containerHeight: _container.clientHeight,
          mapCreateAttempted: true,
          mapCreated: _map != null,
          errorDetail: '$error',
        ),
      );
    }
  }

  void _createCurrentLocationMarker(js.JsObject maps) {
    final position = js.JsObject(
      maps['LatLng'] as js.JsFunction,
      [
        widget.currentPosition.latitude,
        widget.currentPosition.longitude,
      ],
    );

    final marker = js.JsObject(maps['Marker'] as js.JsFunction, [
      js.JsObject.jsify({
        'position': position,
        'title': '현재 위치',
        'image': _markerImageFromSvg(
          maps,
          svg: _currentLocationMarkerSvg,
          width: 34,
          height: 34,
          offsetX: 17,
          offsetY: 17,
        ),
      }),
    ]);
    marker.callMethod('setMap', [_map]);
    _markers.add(marker);
  }

  void _createLaundryMarker(js.JsObject maps, SelectedLaundromat place) {
    final position = js.JsObject(
      maps['LatLng'] as js.JsFunction,
      [
        place.laundromat.latitude,
        place.laundromat.longitude,
      ],
    );

    final marker = js.JsObject(maps['Marker'] as js.JsFunction, [
      js.JsObject.jsify({
        'position': position,
        'title': place.laundromat.name,
        'image': _markerImageFromSvg(
          maps,
          svg: _laundromatMarkerSvg,
          width: 34,
          height: 40,
          offsetX: 17,
          offsetY: 40,
        ),
      }),
    ]);
    marker.callMethod('setMap', [_map]);

    final event = maps['event'] as js.JsObject;
    event.callMethod(
      'addListener',
      [
        marker,
        'click',
        js.JsFunction.withThis((_) {
          widget.onPlaceSelected(place);
        }),
      ],
    );
    _markers.add(marker);
  }

  void _clearMarkers() {
    for (final marker in _markers) {
      marker.callMethod('setMap', [null]);
    }
    _markers.clear();
  }

  js.JsObject _markerImageFromSvg(
    js.JsObject maps, {
    required String svg,
    required int width,
    required int height,
    required int offsetX,
    required int offsetY,
  }) {
    final size = js.JsObject(
      maps['Size'] as js.JsFunction,
      [width, height],
    );
    final offset = js.JsObject(
      maps['Point'] as js.JsFunction,
      [offsetX, offsetY],
    );
    return js.JsObject(
      maps['MarkerImage'] as js.JsFunction,
      [
        'data:image/svg+xml;charset=UTF-8,${Uri.encodeComponent(svg)}',
        size,
        js.JsObject.jsify({'offset': offset}),
      ],
    );
  }

  void _failOrRetry({
    required String stage,
    required String code,
    required String message,
    required String userMessage,
    required Map<String, String> details,
    required String retryReason,
  }) {
    _reportDiagnostic(
      WebMapDiagnostic(
        stage: stage,
        code: _retryCount >= _maxRetryCount ? code : null,
        message: message,
        details: details,
      ),
    );

    if (_retryCount >= _maxRetryCount) {
      _finalizeFailure(
        stage: stage,
        code: code,
        message: message,
        userMessage: userMessage,
        details: details,
      );
      return;
    }

    _retryCount += 1;
    if (mounted) {
      setState(() {
        _userMessage = userMessage;
        _isMapReady = false;
      });
    }
    _isInitializing = false;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 180), () {
      _initializeMap(reason: retryReason);
    });
  }

  void _finalizeFailure({
    required String stage,
    required String code,
    required String message,
    required String userMessage,
    required Map<String, String> details,
  }) {
    _reportDiagnostic(
      WebMapDiagnostic(
        stage: stage,
        code: code,
        message: message,
        details: details,
      ),
    );
    if (mounted) {
      setState(() {
        _userMessage = userMessage;
        _isMapReady = false;
      });
    }
    _isInitializing = false;
  }

  void _setUserMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _userMessage = message;
    });
  }

  void _reportDiagnostic(WebMapDiagnostic diagnostic) {
    widget.onDiagnosticChanged(diagnostic);
  }

  html.ScriptElement? _findSdkScriptTag() {
    final scripts =
        html.document.querySelectorAll('script[data-kakao-map-sdk="true"]');
    if (scripts.isNotEmpty && scripts.first is html.ScriptElement) {
      return scripts.first as html.ScriptElement;
    }

    final scriptById = html.document.getElementById('kakao-map-sdk');
    if (scriptById is html.ScriptElement) {
      return scriptById;
    }

    return null;
  }

  Map<String, String> _diagnosticDetails({
    required bool scriptTagFound,
    required String scriptSrc,
    required bool sdkLoaded,
    required bool sdkLoadError,
    required String sdkLoadErrorMessage,
    required bool hasWindowKakao,
    required bool hasWindowKakaoMaps,
    required bool containerReady,
    required bool containerConnected,
    required int containerWidth,
    required int containerHeight,
    required bool mapCreateAttempted,
    required bool mapCreated,
    int? markerCount,
    double? centerLat,
    double? centerLon,
    String? errorDetail,
  }) {
    return {
      'scriptTagFound': '$scriptTagFound',
      'scriptSrc': scriptSrc,
      'sdkLoaded': '$sdkLoaded',
      'sdkLoadError': '$sdkLoadError',
      'sdkLoadErrorMessage': sdkLoadErrorMessage,
      'hasWindowKakao': '$hasWindowKakao',
      'hasWindowKakaoMaps': '$hasWindowKakaoMaps',
      'autoloadMode': _autoloadMode,
      'containerReady': '$containerReady',
      'containerConnected': '$containerConnected',
      'containerWidth': '$containerWidth',
      'containerHeight': '$containerHeight',
      'mapCreateAttempted': '$mapCreateAttempted',
      'retryCount': '$_retryCount',
      'mapCreated': '$mapCreated',
      if (markerCount != null) 'markerCount': '$markerCount',
      if (centerLat != null) 'centerLat': centerLat.toStringAsFixed(5),
      if (centerLon != null) 'centerLon': centerLon.toStringAsFixed(5),
      if ((errorDetail ?? '').isNotEmpty) 'errorDetail': errorDetail!,
    };
  }

  String get _autoloadMode =>
      (js.context['__kakaoSdkAutoloadMode'] ?? 'unknown').toString();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_isMapReady)
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    const SizedBox(height: 12),
                    Text(_userMessage ?? '지도를 불러오는 중입니다'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
