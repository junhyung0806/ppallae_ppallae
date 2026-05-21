import '../models/laundry_difficulty.dart';
import '../models/recommendation_result.dart';
import '../models/weather_snapshot.dart';

class RecommendationReasonContext {
  const RecommendationReasonContext({
    required this.startTime,
    required this.difficulty,
    required this.weather,
    required this.breakdown,
    required this.estimatedMinutes,
    required this.dryingDisplayText,
  });

  final DateTime startTime;
  final LaundryDifficulty difficulty;
  final WeatherSnapshot weather;
  final RecommendationScoreBreakdown breakdown;
  final int estimatedMinutes;
  final String dryingDisplayText;
}

class RecommendationReasonBuilder {
  const RecommendationReasonBuilder();

  String buildHeadline(RecommendationReasonContext context) {
    final finishAt = context.startTime.add(
      Duration(minutes: context.estimatedMinutes),
    );
    final finishHour = finishAt.hour.toString().padLeft(2, '0');
    final finishMinute = finishAt.minute.toString().padLeft(2, '0');
    return '지금 빨래하면 ${finishHour}:${finishMinute} 전에 마를 가능성이 높아요';
  }

  String buildDescription(RecommendationReasonContext context) {
    final sortedComponents = [...context.breakdown.components]
      ..sort((a, b) => b.rawScore.compareTo(a.rawScore));

    final strongReasons = sortedComponents.take(2).map((component) => component.label).join(', ');
    final weakReason = sortedComponents.last.label;

    final difficultyHint = context.difficulty == LaundryDifficulty.extraHeavy
        ? '초두꺼움 빨래는 건조 시간이 길어 오늘은 더 보수적으로 판단했어요.'
        : context.difficulty == LaundryDifficulty.heavy
            ? '두꺼운 빨래라 일반 옷보다 점수를 낮게 잡았어요.'
            : '${context.difficulty.label} 빨래 기준으로 판단했어요.';

    return '$strongReasons 조건이 좋아 추천 점수가 높게 나왔어요. '
        '$weakReason 영향은 상대적으로 불리했습니다. '
        '$difficultyHint';
  }
}
