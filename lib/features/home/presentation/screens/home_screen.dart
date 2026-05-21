import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/laundry_status.dart';
import '../../../../core/models/laundry_status_mapper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hover_overflow_text.dart';
import '../../../../core/widgets/info_metric_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/location_search_service.dart';
import '../../models/recent_location_search.dart';
import '../../../map/presentation/widgets/location_map_section.dart';
import '../../../recommendation/models/laundry_difficulty.dart';
import '../../../recommendation/models/recommendation_result.dart';
import '../../../recommendation/models/recommendation_status.dart';
import '../../../recommendation/models/saved_location.dart';
import '../../../recommendation/services/recommendation_engine.dart';
import '../../../recommendation/services/repositories.dart';
import '../../../recommendation/state/laundry_dashboard_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final LaundryDashboardController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationSearchService _locationSearchService = LocationSearchService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final recommendation = state.recommendation;
        final weather = state.currentWeather;
        final activeLocation = widget.controller.resolveSelectedLocation();

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '빨래하기 좋은 타이밍',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      _LocationSummaryCard(
                        location: activeLocation,
                        currentTimeText: _formattedTime(DateTime.now()),
                        recommendation: recommendation,
                      ),
                      const SizedBox(height: 12),
                      _LocationSelectionRow(
                        selections: widget.controller.buildLocationSelections(),
                        selectedLocationId: state.selectedLocationId,
                        onSelected: _selectLocation,
                      ),
                      const SizedBox(height: 20),
                      _DifficultySelector(
                        selected: state.selectedDifficulty,
                        onSelected: (difficulty) {
                          widget.controller.changeDifficulty(difficulty);
                        },
                      ),
                      const SizedBox(height: 20),
                      LocationMapSection(
                        controller: widget.controller,
                        title: '선택 위치 주변 빨래방',
                        subtitle: '위치를 확인하고 주변 빨래방을 먼저 고른 뒤 추천을 이어서 보세요.',
                        onRefreshCurrent: widget.controller.refreshCurrentLocation,
                        onSearch: () => _openLocationSearch(context),
                        onSaveCurrentSelection: () =>
                            _saveActiveLocation(context, activeLocation),
                      ),
                      const SizedBox(height: 20),
                      if (recommendation == null || weather == null)
                        const AppCard(
                          child: Text('추천 결과를 불러오는 중입니다.'),
                        )
                      else
                        AppCard(
                          backgroundColor:
                              recommendation.status.asLaundryStatus.backgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusChip(
                                status: recommendation.status.asLaundryStatus,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '오늘의 빨래 점수 ${recommendation.score}점',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recommendation.headline,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recommendation.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                recommendation.dryingEstimate.explanation,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 14),
                        _WeatherSyncDebugCard(meta: state.weatherMeta),
                      ],
                      const SizedBox(height: 24),
                      const SectionTitle(
                        title: '지금 체크할 포인트',
                        subtitle: '추천 결과가 어떤 근거로 나왔는지 빠르게 볼 수 있어요.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InfoMetricCard(
                              title: '습도',
                              value: weather == null ? '-' : '${weather.humidity}%',
                              status: _metricStatusForHumidity(weather?.humidity),
                              icon: Icons.water_drop_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InfoMetricCard(
                              title: '강수확률',
                              value: weather == null ? '-' : '${weather.rainProbability}%',
                              status: _metricStatusForRain(weather?.rainProbability),
                              icon: Icons.grain_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InfoMetricCard(
                              title: '예상 건조시간',
                              value: recommendation?.dryingEstimate.displayText ?? '-',
                              status: recommendation?.status.asLaundryStatus ??
                                  RecommendationStatus.normal.asLaundryStatus,
                              icon: Icons.wb_twilight_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(
                        title: '시간대별 추천',
                        subtitle: '같은 위치에서도 시간대에 따라 추천 점수가 달라집니다.',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 214,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final forecast = state.hourlyForecasts[index];
                      final result = widget.controller.recommendationEngine.evaluate(
                        RecommendationEngineInput(
                          weather: forecast.weather,
                          preferences: state.preferences,
                          patternSummary: state.patternSummary,
                          difficulty: state.selectedDifficulty,
                          startTime: forecast.at,
                        ),
                      );
                      return _HourlyRecommendationCard(
                        timeLabel: _timeLabel(forecast.at),
                        status: result.status,
                        score: result.score,
                        message:
                            '예상 건조시간 ${result.dryingEstimate.displayText} · ${result.headline}',
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemCount: state.hourlyForecasts.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLocationSearch(BuildContext context) async {
    final selection = await showModalBottomSheet<_SearchSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LocationSearchSheet(
        searchService: _locationSearchService,
        recentSearches: widget.controller.state.recentSearches,
        onDeleteRecent: widget.controller.deleteRecentSearch,
        onClearRecent: widget.controller.clearRecentSearches,
      ),
    );

    if (selection != null) {
      await widget.controller.applySearchSelection(
        selection.selection,
        query: selection.query,
      );
    }
  }

  Future<void> _saveActiveLocation(
    BuildContext context,
    LocationSelection? activeLocation,
  ) async {
    if (activeLocation == null || !activeLocation.hasCoordinates) {
      return;
    }

    final saved = await showModalBottomSheet<SavedLocation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SaveLocationSheet(activeLocation: activeLocation),
    );

    if (saved != null) {
      await widget.controller.saveLocation(saved);
    }
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

  String _formattedTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _timeLabel(DateTime at) {
    final hour = at.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }

  LaundryStatus _metricStatusForHumidity(int? humidity) {
    if (humidity == null) {
      return RecommendationStatus.normal.asLaundryStatus;
    }
    if (humidity <= 50) {
      return RecommendationStatus.good.asLaundryStatus;
    }
    if (humidity <= 65) {
      return RecommendationStatus.normal.asLaundryStatus;
    }
    return RecommendationStatus.bad.asLaundryStatus;
  }

  LaundryStatus _metricStatusForRain(int? rainProbability) {
    if (rainProbability == null) {
      return RecommendationStatus.normal.asLaundryStatus;
    }
    if (rainProbability <= 20) {
      return RecommendationStatus.good.asLaundryStatus;
    }
    if (rainProbability <= 45) {
      return RecommendationStatus.normal.asLaundryStatus;
    }
    return RecommendationStatus.bad.asLaundryStatus;
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({
    required this.location,
    required this.currentTimeText,
    required this.recommendation,
  });

  final LocationSelection? location;
  final String currentTimeText;
  final RecommendationResult? recommendation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoPill(
            icon: Icons.schedule_rounded,
            label: '현재 기준 $currentTimeText',
          ),
          const SizedBox(height: 12),
          Text(
            location?.summaryLabel ?? '위치를 확인하는 중입니다.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            recommendation == null
                ? '위치를 정하면 바로 추천 점수가 갱신됩니다.'
                : '현재 선택 위치 기준 추천 점수 ${recommendation!.score}점',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5B6B),
                ),
          ),
        ],
      ),
    );
  }
}

class _LocationSelectionRow extends StatelessWidget {
  const _LocationSelectionRow({
    required this.selections,
    required this.selectedLocationId,
    required this.onSelected,
  });

  final List<LocationSelection> selections;
  final String selectedLocationId;
  final ValueChanged<LocationSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: selections.map((selection) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                _iconFor(selection.sourceType),
                size: 18,
                color: selectedLocationId == selection.id
                    ? const Color(0xFF2D8CFF)
                    : const Color(0xFF587085),
              ),
              label: Text(selection.chipLabel),
              selected: selectedLocationId == selection.id,
              onSelected: (_) => onSelected(selection),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(LocationSourceType type) {
    switch (type) {
      case LocationSourceType.current:
        return Icons.my_location_rounded;
      case LocationSourceType.search:
        return Icons.search_rounded;
      case LocationSourceType.saved:
        return Icons.bookmark_rounded;
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2D6DA3)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2D6DA3),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheetResult {
  const _SearchSheetResult({
    required this.selection,
    required this.query,
  });

  final LocationSelection selection;
  final String query;
}

class _SaveLocationSheet extends StatefulWidget {
  const _SaveLocationSheet({
    required this.activeLocation,
  });

  final LocationSelection activeLocation;

  @override
  State<_SaveLocationSheet> createState() => _SaveLocationSheetState();
}

class _SaveLocationSheetState extends State<_SaveLocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.activeLocation.sourceType == LocationSourceType.saved
          ? widget.activeLocation.label
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      widget.activeLocation.toSavedLocation(savedLabel: trimmed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewInsets),
        child: SizedBox(
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '선택 위치 저장',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '검색처럼 가볍게 이름만 정하면 바로 저장됩니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activeLocation.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.activeLocation.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '저장할 이름',
                  hintText: '예: 헬스장, 학교, 본가',
                  prefixIcon: Icon(Icons.bookmark_add_outlined),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({
    required this.searchService,
    required this.recentSearches,
    required this.onDeleteRecent,
    required this.onClearRecent,
  });

  final LocationSearchService searchService;
  final List<RecentLocationSearch> recentSearches;
  final Future<void> Function(String id) onDeleteRecent;
  final Future<void> Function() onClearRecent;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  late final TextEditingController _controller;
  Timer? _debounce;
  late List<RecentLocationSearch> _recentSearches;
  List<LocationSelection> _results = const [];
  String _query = '';
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _recentSearches = [...widget.recentSearches];
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final nextQuery = _controller.text.trim();
    setState(() {
      _query = nextQuery;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(nextQuery);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) {
      return;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _errorText = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final fetched = await widget.searchService.search(trimmed);
      if (!mounted || trimmed != _controller.text.trim()) {
        return;
      }
      setState(() {
        _results = fetched;
        _errorText = fetched.isEmpty ? '검색 결과가 없습니다.' : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _errorText = '위치 검색에 실패했어요: $error';
        _isLoading = false;
      });
    }
  }

  void _submitFirstResult() {
    if (_results.isEmpty) {
      return;
    }
    _selectResult(_results.first);
  }

  void _selectResult(LocationSelection selection, {String? query}) {
    Navigator.of(context).pop(
      _SearchSheetResult(
        selection: selection,
        query: (query ?? _query).isEmpty ? selection.label : (query ?? _query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewInsets),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '다른 위치 검색',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '빠르게 위치를 찾고 바로 주변 빨래방과 추천을 확인할 수 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '동, 장소명, 주소를 입력하세요',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _controller.clear();
                          },
                        ),
                ),
                onSubmitted: (_) => _submitFirstResult(),
              ),
              const SizedBox(height: 16),
              if (_recentSearches.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      '최근 검색',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await widget.onClearRecent();
                        if (mounted) {
                          setState(() {
                            _recentSearches = const [];
                          });
                        }
                      },
                      child: const Text('전체 삭제'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentSearches.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _recentSearches[index];
                      return _RecentSearchCard(
                        item: item,
                        onTap: () => _selectResult(
                          item.toLocationSelection(),
                          query: item.query,
                        ),
                        onDelete: () async {
                          await widget.onDeleteRecent(item.id);
                          if (mounted) {
                            setState(() {
                              _recentSearches.removeWhere((element) => element.id == item.id);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text(
                    '검색 결과',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8A4B00),
                        ),
                  ),
                ),
              Expanded(
                child: _results.isEmpty
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _query.isEmpty
                                  ? '검색어를 입력하면 결과가 바로 표시됩니다.'
                                  : '입력한 위치와 일치하는 결과를 찾는 중입니다.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return _SearchResultTile(
                            selection: result,
                            onTap: () => _selectResult(result),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchCard extends StatelessWidget {
  const _RecentSearchCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final RecentLocationSearch item;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E4EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 18, color: Color(0xFF4B5B6B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.query,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.selection,
    required this.onTap,
  });

  final LocationSelection selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = _shortDescription(selection.address);
    return Material(
      color: const Color(0xFFF8FBFE),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F0FF),
          child: Icon(Icons.place_rounded, color: Color(0xFF2D8CFF)),
        ),
        title: Text(
          selection.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _shortDescription(String address) {
    final parts = address.split(',');
    if (parts.length <= 1) {
      return address;
    }
    return parts.take(3).map((part) => part.trim()).join(' · ');
  }
}

class _WeatherSyncDebugCard extends StatelessWidget {
  const _WeatherSyncDebugCard({
    required this.meta,
  });

  final WeatherFetchMeta meta;

  @override
  Widget build(BuildContext context) {
    final hasError = meta.usedFallback || (meta.errorCode ?? '').isNotEmpty;
    final upstreamCode = meta.details['upstreamErrorCode'];
    final upstreamStage = meta.details['upstreamStage'];
    final requestSummary = meta.details['forecastRequestSummary'];
    final fallbackReason = meta.details['fallbackReason'];
    final requestRuntime = meta.details['requestRuntime'];
    final requestName = meta.details['requestName'];
    final requestTarget = meta.details['requestTarget'];
    final badgeText = hasError ? 'FALLBACK' : 'SUCCESS';
    final statusMessage = _statusMessage(
      hasError: hasError,
      upstreamCode: upstreamCode,
      upstreamStage: upstreamStage,
      requestRuntime: requestRuntime,
      requestTarget: requestTarget,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '날씨 연동 진단',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 10),
              _DebugBadge(
                label: badgeText,
                background: hasError
                    ? const Color(0xFFFFF0D9)
                    : const Color(0xFFE5F7EE),
                foreground: hasError
                    ? const Color(0xFF8A4B00)
                    : const Color(0xFF16643A),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if ((requestSummary ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('요청 요약: $requestSummary'),
          ],
          if ((requestName ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('실패 endpoint: $requestName'),
          ],
          if ((requestRuntime ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('호출 방식: $requestRuntime'),
          ],
          if ((upstreamCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('원인코드: $upstreamCode'),
          ],
          if ((upstreamStage ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('실패단계: $upstreamStage'),
          ],
          if ((fallbackReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('fallback 이유: $fallbackReason'),
          ],
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('개발용 상세 로그'),
            children: [
              _DebugLine(label: 'source', value: meta.source),
              _DebugLine(label: 'stage', value: meta.stage),
              _DebugLine(label: 'fallback', value: '${meta.usedFallback}'),
              _DebugLine(label: 'debug', value: meta.debugMessage ?? '-'),
              ...meta.details.entries.map(
                (entry) => _DebugLine(
                  label: entry.key,
                  value: entry.value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusMessage({
    required bool hasError,
    required String? upstreamCode,
    required String? upstreamStage,
    required String? requestRuntime,
    required String? requestTarget,
  }) {
    if (!hasError) {
      return meta.userMessage;
    }

    if (upstreamCode == 'BACKEND-001') {
      return '외부 날씨 백엔드 설정이 없어 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'BACKEND-004') {
      return '외부 날씨 백엔드 인증 또는 접근 권한 문제로 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'BACKEND-003' &&
        (upstreamStage ?? '').contains('timeout')) {
      return '외부 날씨 백엔드 응답 지연으로 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'BACKEND-005') {
      return '외부 날씨 백엔드 서버 응답 오류로 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'BACKEND-006' || upstreamCode == 'BACKEND-007') {
      return '외부 날씨 백엔드 응답 형식 문제로 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'KMA-010') {
      return '기상청 API 키 또는 접근 권한이 유효하지 않아 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'KMA-009' ||
        (upstreamStage ?? '').contains('browser_fetch_blocked') ||
        requestRuntime == 'browser_fetch') {
      return '웹 브라우저에서 기상청 API 직접 호출이 차단되어 fallback 데이터를 사용 중입니다.';
    }

    if (upstreamCode == 'KMA-003' &&
        (upstreamStage ?? '').contains('http_timeout')) {
      return '기상청 API 응답 지연으로 fallback 데이터를 사용 중입니다. API 키 또는 엔드포인트 상태를 확인해 주세요.';
    }

    if (upstreamCode == 'KMA-001') {
      return '기상청 API 키가 설정되지 않아 fallback 데이터를 사용 중입니다.';
    }

    if (requestTarget == 'backend' || requestRuntime == 'browser_to_backend') {
      return '외부 날씨 백엔드 연결 실패로 fallback 데이터를 사용 중입니다.';
    }

    return meta.userMessage;
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.selected,
    required this.onSelected,
  });

  final LaundryDifficulty selected;
  final ValueChanged<LaundryDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final difficulty = LaundryDifficulty.values[index];
          return LaundryDifficultyChip(
            difficulty: difficulty,
            selected: difficulty == selected,
            onTap: () => onSelected(difficulty),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: LaundryDifficulty.values.length,
      ),
    );
  }
}

class LaundryDifficultyChip extends StatelessWidget {
  const LaundryDifficultyChip({
    super.key,
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final LaundryDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF102033);
    final background = selected ? const Color(0xFF2D8CFF) : Colors.white;
    final border = selected ? const Color(0xFF2D8CFF) : const Color(0xFFD9E5F0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.local_laundry_service_outlined,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
                child: HoverOverflowText(
                  text: difficulty.chipLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourlyRecommendationCard extends StatelessWidget {
  const _HourlyRecommendationCard({
    required this.timeLabel,
    required this.status,
    required this.score,
    required this.message,
  });

  final String timeLabel;
  final RecommendationStatus status;
  final int score;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StatusChip(status: status.asLaundryStatus),
            const SizedBox(height: 12),
            Text('$score점', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 20,
              child: HoverOverflowText(
                text: message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF102033),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF314154),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugBadge extends StatelessWidget {
  const _DebugBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
