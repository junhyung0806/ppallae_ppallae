import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../recommendation/models/recommendation_result.dart';
import '../../../recommendation/models/recommendation_status.dart';
import '../../../recommendation/models/saved_location.dart';
import '../../../recommendation/state/laundry_dashboard_controller.dart';
import '../../data/web_map_diagnostic.dart';
import '../../models/laundromat.dart';
import '../../utilities/distance_calculator.dart';
import 'web_kakao_map_widget.dart';
import 'web_map_diagnostic_card.dart';

class LocationMapSection extends StatefulWidget {
  const LocationMapSection({
    super.key,
    required this.controller,
    this.title = '주변 빨래방',
    this.subtitle = '선택한 위치를 기준으로 주변 빨래방을 함께 볼 수 있어요.',
    this.showLocationSelector = false,
    required this.onRefreshCurrent,
    required this.onSearch,
    required this.onSaveCurrentSelection,
  });

  final LaundryDashboardController controller;
  final String title;
  final String subtitle;
  final bool showLocationSelector;
  final Future<void> Function() onRefreshCurrent;
  final Future<void> Function() onSearch;
  final Future<void> Function() onSaveCurrentSelection;

  @override
  State<LocationMapSection> createState() => _LocationMapSectionState();
}

class _LocationMapSectionState extends State<LocationMapSection> {
  final DistanceCalculator _distanceCalculator = const DistanceCalculator();
  final PageController _cardController = PageController(viewportFraction: 0.9);
  WebMapDiagnostic _webMapDiagnostic = WebMapDiagnostic.initial();

  int _visibleLaundromatCount = 0;
  String? _lastAnchorKey;

  bool get _isWeb => kIsWeb;

  bool get _supportsNativeMap {
    return !_isWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final activeLocation = widget.controller.resolveSelectedLocation();
        final recommendation = state.recommendation;
        final anchor = _MapAnchor(
          latitude: activeLocation?.latitude ?? 37.3417,
          longitude: activeLocation?.longitude ?? 127.1112,
          label: activeLocation?.label ?? '현재 위치',
        );

        final allLaundromats = _buildNearbyLaundromats(anchor);
        final anchorKey =
            '${anchor.latitude.toStringAsFixed(4)}:${anchor.longitude.toStringAsFixed(4)}';
        final initialVisibleCount = _initialVisibleCount(allLaundromats);
        final visibleCount = _lastAnchorKey == anchorKey && _visibleLaundromatCount > 0
            ? _visibleLaundromatCount.clamp(1, allLaundromats.length)
            : initialVisibleCount;
        final laundromats = allLaundromats.take(visibleCount).toList(growable: false);
        final hasMoreLaundromats = visibleCount < allLaundromats.length;
        final selected = _selectedFromList(laundromats, state.selectedLaundromat);

        if (_lastAnchorKey != anchorKey || _visibleLaundromatCount != visibleCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _lastAnchorKey = anchorKey;
              _visibleLaundromatCount = visibleCount;
            });
          });
        }

        if ((state.selectedLaundromat == null ||
                !laundromats.any(
                  (item) => item.laundromat.id == state.selectedLaundromat?.laundromat.id,
                )) &&
            laundromats.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.selectLaundromat(laundromats.first);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            if (widget.showLocationSelector) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.controller.buildLocationSelections().map((selection) {
                    final selectedLocation =
                        widget.controller.state.selectedLocationId == selection.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(selection.chipLabel),
                        selected: selectedLocation,
                        onSelected: (_) {
                          _selectLocation(selection);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox.expand(
                      child: _isWeb
                          ? WebKakaoMapWidget(
                              currentPosition: LatLng(anchor.latitude, anchor.longitude),
                              places: laundromats,
                              onPlaceSelected: widget.controller.selectLaundromat,
                              onDiagnosticChanged: (diagnostic) {
                                if (mounted) {
                                  setState(() => _webMapDiagnostic = diagnostic);
                                }
                              },
                            )
                          : _supportsNativeMap
                              ? GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(anchor.latitude, anchor.longitude),
                                    zoom: 15,
                                  ),
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  markers: _buildMarkers(anchor, laundromats),
                                )
                              : _MapPlaceholder(
                                  laundromats: laundromats,
                                  selected: selected,
                                  onSelect: widget.controller.selectLaundromat,
                                ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              widget.onRefreshCurrent();
                            },
                            icon: const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text('현재 위치'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF102033),
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              widget.onSearch();
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('다른 위치 검색'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF102033),
                              side: const BorderSide(color: Color(0xFFD6E1EB)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              widget.onSaveCurrentSelection();
                            },
                            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            label: const Text('선택 위치 저장'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF102033),
                              side: const BorderSide(color: Color(0xFFD6E1EB)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isWeb && !_webMapDiagnostic.isReady) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  _userFacingMapMessage(_webMapDiagnostic),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (_isWeb && kDebugMode) ...[
              const SizedBox(height: 12),
              WebMapDiagnosticCard(diagnostic: _webMapDiagnostic),
            ],
            const SizedBox(height: 14),
            AppCard(
              child: ScrollConfiguration(
                behavior: const _MouseDraggableScrollBehavior(),
                child: SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _cardController,
                    padEnds: false,
                    itemCount: laundromats.length + (hasMoreLaundromats ? 1 : 0),
                    onPageChanged: (index) {
                      if (index < laundromats.length) {
                        widget.controller.selectLaundromat(laundromats[index]);
                      }
                    },
                    itemBuilder: (context, index) {
                      if (index >= laundromats.length) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _MoreLaundromatsCard(
                            remainingCount: allLaundromats.length - laundromats.length,
                            onTap: () {
                              setState(() {
                                _visibleLaundromatCount = (_visibleLaundromatCount + 1)
                                    .clamp(1, allLaundromats.length);
                              });
                            },
                          ),
                        );
                      }

                      final laundromat = laundromats[index];
                      final isSelected = selected?.laundromat.id == laundromat.laundromat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _LaundromatCard(
                          laundromat: laundromat,
                          isSelected: isSelected,
                          recommendation: recommendation,
                          onTap: () => widget.controller.selectLaundromat(laundromat),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLocation(LocationSelection selection) async {
    switch (selection.sourceType) {
      case LocationSourceType.current:
        await widget.controller.selectCurrentLocation();
        break;
      case LocationSourceType.saved:
        await widget.controller.selectSavedLocation(selection.id);
        break;
      case LocationSourceType.search:
        await widget.controller.selectSearchLocation(selection);
        break;
    }
  }

  String _userFacingMapMessage(WebMapDiagnostic diagnostic) {
    switch (diagnostic.code) {
      case 'MAP-001':
      case 'MAP-002':
      case 'MAP-003':
      case 'MAP-004':
      case 'MAP-005':
        return '카카오 지도 SDK를 준비하는 중 문제가 생겼습니다.';
      case 'MAP-006':
        return '지도 영역 준비가 지연되고 있어 다시 시도 중입니다.';
      case 'MAP-007':
      case 'MAP-008':
        return '지도를 생성하지 못했습니다. Kakao JavaScript 키와 Web 플랫폼 허용 도메인을 확인해주세요.';
      default:
        return diagnostic.isReady
            ? '지도가 정상적으로 준비되었습니다.'
            : '지도를 초기화하는 중입니다. 잠시만 기다려주세요.';
    }
  }

  List<SelectedLaundromat> _buildNearbyLaundromats(_MapAnchor anchor) {
    final laundromats = [
      Laundromat(
        id: 'laundromat_1',
        name: '${anchor.label} 스마트 빨래방',
        latitude: anchor.latitude + 0.0011,
        longitude: anchor.longitude + 0.0022,
        address: '도보 접근이 편한 코인 세탁점',
      ),
      Laundromat(
        id: 'laundromat_2',
        name: '${anchor.label} 코인워시',
        latitude: anchor.latitude - 0.0013,
        longitude: anchor.longitude - 0.0018,
        address: '건조기 수가 많은 매장',
      ),
      Laundromat(
        id: 'laundromat_3',
        name: '${anchor.label} 드라이 라운지',
        latitude: anchor.latitude + 0.0018,
        longitude: anchor.longitude - 0.0024,
        address: '대형 빨래 위주로 쓰기 좋은 매장',
      ),
      Laundromat(
        id: 'laundromat_4',
        name: '${anchor.label} 버블코인',
        latitude: anchor.latitude + 0.0039,
        longitude: anchor.longitude + 0.0028,
        address: '24시간 운영되는 동네 코인 빨래방',
      ),
      Laundromat(
        id: 'laundromat_5',
        name: '${anchor.label} 런드리 스테이션',
        latitude: anchor.latitude - 0.0042,
        longitude: anchor.longitude + 0.0033,
        address: '주차가 편한 외곽형 빨래방',
      ),
      Laundromat(
        id: 'laundromat_6',
        name: '${anchor.label} 워시허브',
        latitude: anchor.latitude + 0.0061,
        longitude: anchor.longitude - 0.0014,
        address: '운동화 세탁 코스가 있는 매장',
      ),
      Laundromat(
        id: 'laundromat_7',
        name: '${anchor.label} 나이트 런드리',
        latitude: anchor.latitude - 0.0068,
        longitude: anchor.longitude - 0.0041,
        address: '야간 이용이 편한 소형 빨래방',
      ),
      Laundromat(
        id: 'laundromat_8',
        name: '${anchor.label} 클린업24',
        latitude: anchor.latitude + 0.0086,
        longitude: anchor.longitude + 0.0048,
        address: '대형 이불 세탁이 가능한 매장',
      ),
    ];

    final selected = laundromats.map((laundromat) {
      final meters = _distanceCalculator.metersBetween(
        startLatitude: anchor.latitude,
        startLongitude: anchor.longitude,
        endLatitude: laundromat.latitude,
        endLongitude: laundromat.longitude,
      );
      return SelectedLaundromat(
        laundromat: laundromat,
        distanceMeters: meters,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return selected;
  }

  int _initialVisibleCount(List<SelectedLaundromat> laundromats) {
    if (laundromats.isEmpty) {
      return 0;
    }

    final withinOneKilometer = laundromats.where((item) => item.distanceMeters <= 1000).length;
    if (withinOneKilometer == 0) {
      return 1;
    }
    return withinOneKilometer.clamp(1, 5);
  }

  SelectedLaundromat? _selectedFromList(
    List<SelectedLaundromat> laundromats,
    SelectedLaundromat? selected,
  ) {
    if (selected == null) {
      return laundromats.isEmpty ? null : laundromats.first;
    }

    for (final laundromat in laundromats) {
      if (laundromat.laundromat.id == selected.laundromat.id) {
        return laundromat;
      }
    }

    return laundromats.isEmpty ? null : laundromats.first;
  }

  Set<Marker> _buildMarkers(
    _MapAnchor anchor,
    List<SelectedLaundromat> laundromats,
  ) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(anchor.latitude, anchor.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '내 위치'),
      ),
    };

    for (final selected in laundromats) {
      final laundromat = selected.laundromat;
      markers.add(
        Marker(
          markerId: MarkerId(laundromat.id),
          position: LatLng(laundromat.latitude, laundromat.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: laundromat.name,
            snippet: selected.distanceLabel,
          ),
          onTap: () => widget.controller.selectLaundromat(selected),
        ),
      );
    }

    return markers;
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.laundromats,
    required this.selected,
    required this.onSelect,
  });

  final List<SelectedLaundromat> laundromats;
  final SelectedLaundromat? selected;
  final ValueChanged<SelectedLaundromat> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE2F1FF), Color(0xFFF7FBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.separated(
          itemCount: laundromats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final laundromat = laundromats[index];
            final isSelected = selected?.laundromat.id == laundromat.laundromat.id;
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelect(laundromat),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D8CFF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_laundry_service_rounded,
                        color: isSelected ? Colors.white : const Color(0xFFFF7A59),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              laundromat.laundromat.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF102033),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              laundromat.distanceLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFEAF3FF)
                                        : const Color(0xFF4B5B6B),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LaundromatCard extends StatelessWidget {
  const _LaundromatCard({
    required this.laundromat,
    required this.isSelected,
    required this.recommendation,
    required this.onTap,
  });

  final SelectedLaundromat laundromat;
  final bool isSelected;
  final RecommendationResult? recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D8CFF) : const Color(0xFFD6E1EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MapMetaPill(
                    icon: Icons.directions_walk_rounded,
                    label: laundromat.walkingTimeLabel,
                  ),
                  _MapMetaPill(
                    icon: Icons.straighten_rounded,
                    label: laundromat.distanceLabel,
                  ),
                  if (recommendation != null)
                    _MapMetaPill(
                      icon: recommendation!.status == RecommendationStatus.bad
                          ? Icons.warning_amber_rounded
                          : Icons.thumb_up_alt_rounded,
                      label: recommendation!.status == RecommendationStatus.bad
                          ? '지금은 비추천'
                          : '지금 빨래 추천',
                      foreground: recommendation!.status == RecommendationStatus.bad
                          ? const Color(0xFF8A4B00)
                          : const Color(0xFF16643A),
                      background: recommendation!.status == RecommendationStatus.bad
                          ? const Color(0xFFFFF2D9)
                          : const Color(0xFFE8F6EC),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_laundry_service_rounded,
                      color: Color(0xFFFF7A59),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      laundromat.laundromat.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF102033),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                laundromat.laundromat.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                recommendation == null
                    ? '지도에서 좌우로 넘겨 다른 빨래방을 확인해보세요.'
                    : '선택 위치 기준 추천 점수 ${recommendation!.score}점과 연결되어 있어요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2D6DA3),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreLaundromatsCard extends StatelessWidget {
  const _MoreLaundromatsCard({
    required this.remainingCount,
    required this.onTap,
  });

  final int remainingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD6E1EB)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F1FB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 30, color: Color(0xFF2D6DA3)),
                ),
                const SizedBox(height: 12),
                Text(
                  '가까운 빨래방 더 보기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '남은 $remainingCount곳 중 가장 가까운 빨래방 1곳을 추가합니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapMetaPill extends StatelessWidget {
  const _MapMetaPill({
    required this.icon,
    required this.label,
    this.foreground = const Color(0xFF2D6DA3),
    this.background = const Color(0xFFF1F7FD),
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapAnchor {
  const _MapAnchor({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class _MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  const _MouseDraggableScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
