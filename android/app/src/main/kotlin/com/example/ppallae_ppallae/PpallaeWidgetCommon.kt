package com.example.ppallae_ppallae

/**
 * 위젯 공통 헬퍼. 등급 → 아이콘 drawable, 3x1 layout 매핑.
 * Flutter 측 색상/그레이드 임계값과 동기화 유지.
 */
internal object PpallaeWidgetCommon {
    const val TAG = "PpallaeWidget"

    /** 등급 → 등급별 PNG drawable 리소스 ID */
    fun gradeIcon(gradeCode: String): Int = when (gradeCode) {
        "EXCELLENT" -> R.drawable.widget_grade_excellent
        "GOOD" -> R.drawable.widget_grade_good
        "NORMAL" -> R.drawable.widget_grade_normal
        "BAD" -> R.drawable.widget_grade_bad
        "VERY_BAD" -> R.drawable.widget_grade_very_bad
        else -> R.drawable.widget_grade_normal
    }

    /** 3x1: 등급별 layout 리소스 (배경색이 박혀있는 각각의 XML) */
    fun grade3x1Layout(gradeCode: String): Int = when (gradeCode) {
        "EXCELLENT" -> R.layout.ppallae_widget_3x1_excellent
        "GOOD" -> R.layout.ppallae_widget_3x1_good
        "NORMAL" -> R.layout.ppallae_widget_3x1_normal
        "BAD" -> R.layout.ppallae_widget_3x1_bad
        "VERY_BAD" -> R.layout.ppallae_widget_3x1_very_bad
        else -> R.layout.ppallae_widget_3x1_normal
    }

    /** 1x1: 등급별 layout 리소스 */
    fun grade1x1Layout(gradeCode: String): Int = when (gradeCode) {
        "EXCELLENT" -> R.layout.ppallae_widget_1x1_excellent
        "GOOD" -> R.layout.ppallae_widget_1x1_good
        "NORMAL" -> R.layout.ppallae_widget_1x1_normal
        "BAD" -> R.layout.ppallae_widget_1x1_bad
        "VERY_BAD" -> R.layout.ppallae_widget_1x1_very_bad
        else -> R.layout.ppallae_widget_1x1_normal
    }

    /** 등급 코드 → 한글 라벨 */
    fun gradeLabel(gradeCode: String): String = when (gradeCode) {
        "EXCELLENT" -> "최고"
        "GOOD" -> "좋음"
        "NORMAL" -> "보통"
        "BAD" -> "나쁨"
        "VERY_BAD" -> "최악"
        else -> "-"
    }
}
