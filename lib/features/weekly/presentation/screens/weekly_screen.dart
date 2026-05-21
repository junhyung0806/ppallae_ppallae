import 'package:flutter/material.dart';

import '../../../../core/models/laundry_status.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../recommendation/models/laundry_difficulty.dart';
import '../../../recommendation/state/laundry_dashboard_controller.dart';
import '../../data/weekly_dummy_data.dart';
import '../widgets/weekly_forecast_tile.dart';

class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({
    super.key,
    required this.controller,
  });

  final LaundryDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedDifficulty = controller.state.selectedDifficulty;
        final forecasts = weeklyDummyData
            .map((forecast) => _applyDifficultyAdjustment(forecast, selectedDifficulty))
            .toList();
        final bestDay = forecasts.reduce(
          (best, next) => next.score > best.score ? next : best,
        );

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                '이번 주 빨래 캘린더',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '7일 예보를 기준으로 가장 적합한 날짜를 골라봤어요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '빨래 두께',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${selectedDifficulty.label} 기준으로 주간 추천을 보고 있어요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    _DifficultySelector(
                      selected: selectedDifficulty,
                      onSelected: (difficulty) {
                        controller.changeDifficulty(difficulty);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                backgroundColor: bestDay.status.backgroundColor,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이번 주 베스트 날짜',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${bestDay.dayLabel}요일 ${bestDay.dateLabel}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          StatusChip(status: bestDay.status),
                          const SizedBox(height: 12),
                          Text(
                            bestDay.reason,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                title: '날짜별 지수',
                subtitle: '점수와 함께 왜 추천되는지도 한눈에 확인할 수 있어요.',
              ),
              const SizedBox(height: 16),
              ...forecasts.map(
                (forecast) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WeeklyForecastTile(forecast: forecast),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  WeeklyLaundryForecast _applyDifficultyAdjustment(
    WeeklyLaundryForecast forecast,
    LaundryDifficulty difficulty,
  ) {
    final penalty = switch (difficulty) {
      LaundryDifficulty.light => 0,
      LaundryDifficulty.normal => 4,
      LaundryDifficulty.heavy => 11,
      LaundryDifficulty.extraHeavy => 19,
    };
    final adjustedScore = (forecast.score - penalty).clamp(0, 100);
    final adjustedStatus = _statusForScore(adjustedScore);
    final adjustedReason = _reasonForDifficulty(
      forecast: forecast,
      difficulty: difficulty,
      adjustedStatus: adjustedStatus,
    );

    return WeeklyLaundryForecast(
      dayLabel: forecast.dayLabel,
      dateLabel: forecast.dateLabel,
      score: adjustedScore,
      status: adjustedStatus,
      reason: adjustedReason,
      isBest: false,
    );
  }

  LaundryStatus _statusForScore(int score) {
    if (score >= 75) {
      return LaundryStatus.good;
    }
    if (score >= 45) {
      return LaundryStatus.normal;
    }
    return LaundryStatus.bad;
  }

  String _reasonForDifficulty({
    required WeeklyLaundryForecast forecast,
    required LaundryDifficulty difficulty,
    required LaundryStatus adjustedStatus,
  }) {
    if (difficulty == LaundryDifficulty.light) {
      return '${forecast.reason} 가벼운 빨래는 비교적 수월해요.';
    }
    if (difficulty == LaundryDifficulty.normal) {
      return '${forecast.reason} 일반 빨래 기준으로는 무난한 편이에요.';
    }
    if (difficulty == LaundryDifficulty.heavy) {
      return adjustedStatus == LaundryStatus.bad
          ? '${forecast.reason} 두꺼운 빨래는 건조가 늦어져 미루는 편이 좋아요.'
          : '${forecast.reason} 두꺼운 빨래는 건조 시간을 넉넉히 잡아주세요.';
    }
    return adjustedStatus == LaundryStatus.good
        ? '${forecast.reason} 초두꺼움 빨래는 가능하지만 아주 여유 있게 말려야 해요.'
        : '${forecast.reason} 초두꺼움 빨래는 이번 주엔 더 좋은 날을 고르는 편이 안전해요.';
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
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LaundryDifficulty.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final difficulty = LaundryDifficulty.values[index];
          return _LaundryDifficultyChip(
            difficulty: difficulty,
            selected: difficulty == selected,
            onTap: () => onSelected(difficulty),
          );
        },
      ),
    );
  }
}

class _LaundryDifficultyChip extends StatelessWidget {
  const _LaundryDifficultyChip({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final LaundryDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = selected
        ? (
            background: Theme.of(context).colorScheme.primary,
            foreground: Colors.white,
          )
        : (
            background: const Color(0xFFF3F5F9),
            foreground: Theme.of(context).colorScheme.onSurface,
          );

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                difficulty.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                difficulty.chipExamples.join(', '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.82),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
