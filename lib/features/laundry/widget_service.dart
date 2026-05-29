import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../api/models/api_models.dart';

/// 홈 위젯(Android)에 빨래지수 요약을 전달한다. 웹/미지원 플랫폼에서는 무시.
class WidgetService {
  static const _androidProvider = 'PpallaeWidgetProvider';

  static Future<void> update({
    required ScoreEnvelopeModel envelope,
    String? bestStartTimeRange,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'region',
        envelope.regionDisplayName,
      );
      await HomeWidget.saveWidgetData<String>(
        'score',
        '${envelope.score.overallScore}',
      );
      await HomeWidget.saveWidgetData<String>(
        'grade',
        _gradeLabel(envelope.score.grade),
      );
      await HomeWidget.saveWidgetData<String>(
        'recommendation',
        bestStartTimeRange != null
            ? '추천 $bestStartTimeRange'
            : envelope.score.recommendationText,
      );
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // 위젯 미설정/미지원이면 조용히 무시
    }
  }
}

String _gradeLabel(String grade) {
  switch (grade) {
    case 'EXCELLENT':
      return '최고';
    case 'GOOD':
      return '좋음';
    case 'NORMAL':
      return '보통';
    case 'BAD':
      return '나쁨';
    case 'VERY_BAD':
      return '매우 나쁨';
    default:
      return grade;
  }
}
