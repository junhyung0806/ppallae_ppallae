package com.example.ppallae_ppallae

import android.content.SharedPreferences

/**
 * 위젯 공통 헬퍼. 등급 → 아이콘 drawable, 3x1 layout 매핑, 신선도(갱신시각) 계산.
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

    /** 이 값(ms)보다 오래되면 stale 로 간주 — 위젯 텍스트를 흐리게 처리. */
    const val STALE_THRESHOLD_MS = 3 * 60 * 60 * 1000L // 3시간

    /** stale 상태 텍스트 색 (반투명 흰색 — 등급색 배경 위에서 "흐림"으로 보임). */
    const val STALE_TEXT_COLOR = 0x66FFFFFF.toInt()

    /**
     * SharedPreferences 의 updatedAtMs(epoch millis, UTC) 파싱.
     * 없거나 파싱 실패 시 null → 신선도 미표시 + stale 취급 안 함(첫 로드 전 등).
     */
    fun parseUpdatedAtMs(widgetData: SharedPreferences): Long? {
        val raw = widgetData.getString("updatedAtMs", "") ?: ""
        if (raw.isBlank()) return null
        return raw.toLongOrNull()
    }

    /** updatedAtMs 가 STALE_THRESHOLD_MS 보다 오래됐는지. null 이면 false(모름). */
    fun isStale(updatedAtMs: Long?): Boolean {
        if (updatedAtMs == null) return false
        return System.currentTimeMillis() - updatedAtMs > STALE_THRESHOLD_MS
    }

    /** "방금 · 3분 전 · 2시간 전" 등 경과시간 라벨. null 이면 빈 문자열. */
    fun freshnessLabel(updatedAtMs: Long?): String {
        if (updatedAtMs == null) return ""
        val diffMin = (System.currentTimeMillis() - updatedAtMs) / 60000L
        return when {
            diffMin < 1 -> "방금"
            diffMin < 60 -> "${diffMin}분 전"
            diffMin < 24 * 60 -> "${diffMin / 60}시간 전"
            else -> "${diffMin / (24 * 60)}일 전"
        }
    }
}
