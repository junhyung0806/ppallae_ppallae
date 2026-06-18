/// 빨래 등급 코드/라벨/임계값/색 공통 정의.
///
/// 정상 동작 시 백엔드 `score.grade` 를 그대로 사용한다.
/// 점수→등급 fallback 은 백엔드 응답에 grade 필드가 비어있을 때만 호출되며,
/// 임계값이 백엔드와 어긋나면 debug에서 mismatch 경고가 뜬다.
///
/// Kotlin 위젯 측(`PpallaeWidgetCommon.gradeLabel`) 도 같은 매핑이지만,
/// 위젯은 native 격리라 별도 유지.
library;

import 'package:flutter/material.dart';

/// 점수 아직 모를 때 / 응답 없을 때 쓰는 기본 액센트 색 (브랜드 블루).
/// 메모: 등급이 결정되면 [gradeColor] 의 등급 색이 우선.
const Color kFallbackAccent = Color(0xFF3A7BD5);

/// [_PpallaePill] 등 선택 강조 그라데이션의 밝은 페어 색.
/// 등급별로는 자동 lighten 하기 어렵기에, 폴백 시에만 페어 사용.
const Color kFallbackAccentLight = Color(0xFF4A8DE0);

/// 100~85: EXCELLENT, 84~70: GOOD, 69~50: NORMAL, 49~30: BAD, 29~0: VERY_BAD.
String gradeFromScore(int score) {
  if (score >= 85) return 'EXCELLENT';
  if (score >= 70) return 'GOOD';
  if (score >= 50) return 'NORMAL';
  if (score >= 30) return 'BAD';
  return 'VERY_BAD';
}

String gradeLabel(String grade) {
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
      return '최악';
    default:
      return grade;
  }
}

/// 등급 → 표시 색. 신호등 스케일의 파스텔 톤.
/// 알 수 없는 등급은 [kFallbackAccent] 폴백.
Color gradeColor(String grade) {
  switch (grade) {
    case 'EXCELLENT':
      return const Color(0xFF5BA3D3); // 파스텔 스카이블루
    case 'GOOD':
      return const Color(0xFF5DAB6C); // 세이지 그린
    case 'NORMAL':
      return const Color(0xFFE5B946); // 머스타드 옐로우
    case 'BAD':
      return const Color(0xFFE89464); // 소프트 오렌지
    case 'VERY_BAD':
      return const Color(0xFFD17878); // 로지 레드
    default:
      return kFallbackAccent;
  }
}

/// 등급 그라데이션 페어 (선택 pill 의 LinearGradient 의 밝은 쪽).
/// 각 등급 색을 살짝 밝게 한 값. 디자인 일관성 유지용.
Color gradeColorLight(String grade) {
  switch (grade) {
    case 'EXCELLENT':
      return const Color(0xFF7BB8DE);
    case 'GOOD':
      return const Color(0xFF7DBF8C);
    case 'NORMAL':
      return const Color(0xFFEFC868);
    case 'BAD':
      return const Color(0xFFEFA985);
    case 'VERY_BAD':
      return const Color(0xFFDD9494);
    default:
      return kFallbackAccentLight;
  }
}
