package com.example.ppallae_ppallae

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 2x1 위젯 (구버전 클래스명 '3x1' 유지 — Manifest/Flutter 호환).
 * 등급색 카드 + 추천 시간 + 점수 + 등급 + 아이콘 + 진행바 + 슬라이더 dot (4슬롯).
 * dot은 4개 슬롯 중 등급에 맞는 하나만 VISIBLE.
 */
class PpallaeWidget3x1Provider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val gradeCode = widgetData.getString("gradeCode", "") ?: ""
        val scoreStr = widgetData.getString("score", "-") ?: "-"
        val recoStart = widgetData.getString("recoStart", "--:--") ?: "--:--"
        val recoEnd = widgetData.getString("recoEnd", "--:--") ?: "--:--"
        val recoText = if (recoEnd.isNotEmpty()) "추천 시간 : $recoStart ~ $recoEnd"
        else "추천 시간 : $recoStart"
        val gradeLabel = PpallaeWidgetCommon.gradeLabel(gradeCode)
        val scoreInt = scoreStr.toIntOrNull() ?: 0
        val dotIndex = gradeToDotIndex(gradeCode)

        Log.i(
            PpallaeWidgetCommon.TAG,
            "2x1 onUpdate ids=${appWidgetIds.toList()} grade=$gradeCode " +
                "score=$scoreStr dotIdx=$dotIndex"
        )

        appWidgetIds.forEach { widgetId ->
            try {
                val layoutRes = PpallaeWidgetCommon.grade3x1Layout(gradeCode)
                val views = RemoteViews(context.packageName, layoutRes).apply {
                    setTextViewText(R.id.widget_reco, recoText)
                    setTextViewText(R.id.widget_score, scoreStr)
                    setTextViewText(R.id.widget_grade, gradeLabel)
                    setImageViewResource(
                        R.id.widget_icon,
                        PpallaeWidgetCommon.gradeIcon(gradeCode)
                    )
                    setProgressBar(R.id.widget_score_bar, 100, scoreInt, false)

                    // 4 dot 슬롯 중 등급에 맞는 하나만 보이기
                    val dotIds = intArrayOf(
                        R.id.widget_dot_0,
                        R.id.widget_dot_1,
                        R.id.widget_dot_2,
                        R.id.widget_dot_3,
                    )
                    for (i in dotIds.indices) {
                        setViewVisibility(
                            dotIds[i],
                            if (i == dotIndex) View.VISIBLE else View.GONE
                        )
                    }

                    setOnClickPendingIntent(
                        R.id.widget_root,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    )
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Throwable) {
                Log.e(PpallaeWidgetCommon.TAG, "[WGT-A2x1] failed id=$widgetId", e)
            }
        }
    }

    /** 등급 → dot 슬롯 index (4개 라벨 나쁨/보통/좋음/최고에 매핑). */
    private fun gradeToDotIndex(gradeCode: String): Int = when (gradeCode) {
        "EXCELLENT" -> 3
        "GOOD" -> 2
        "NORMAL" -> 1
        "BAD", "VERY_BAD" -> 0
        else -> 0
    }
}
