package com.ppallae.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 1x1 위젯: 등급색 카드 + 등급 아이콘 + 점수 + 등급 라벨.
 * 5개 등급별 layout 중 하나를 선택 (배경색이 layout에 박힘).
 */
class PpallaeWidget1x1Provider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val gradeCode = widgetData.getString("gradeCode", "") ?: ""
        val score = widgetData.getString("score", "-") ?: "-"
        // 오늘 안에 추천 시간이 없으면("tomorrow"='1') 등급 라벨 대신 "내일추천"
        // (색/레이아웃은 등급 그대로 — 제품 결정 2026-07-10).
        val tomorrow = widgetData.getString("tomorrow", "") == "1"
        val gradeLabel =
            if (tomorrow) "내일추천" else PpallaeWidgetCommon.gradeLabel(gradeCode)
        // 신선도: 데이터가 오래됐으면(3h+) 점수/등급을 흐리게 → stale 을 눈치채게.
        // 1x1 은 공간이 없어 "n분 전" 텍스트 대신 흐림 처리만 한다.
        val updatedAtMs = PpallaeWidgetCommon.parseUpdatedAtMs(widgetData)
        val stale = PpallaeWidgetCommon.isStale(updatedAtMs)

        Log.i(
            PpallaeWidgetCommon.TAG,
            "1x1 onUpdate ids=${appWidgetIds.toList()} grade=$gradeCode score=$score stale=$stale"
        )

        appWidgetIds.forEach { widgetId ->
            try {
                val layoutRes = PpallaeWidgetCommon.grade1x1Layout(gradeCode)
                val views = RemoteViews(context.packageName, layoutRes).apply {
                    setImageViewResource(
                        R.id.widget_icon,
                        PpallaeWidgetCommon.gradeIcon(gradeCode)
                    )
                    setTextViewText(R.id.widget_score, score)
                    setTextViewText(R.id.widget_grade, gradeLabel)
                    if (stale) {
                        setTextColor(R.id.widget_score, PpallaeWidgetCommon.STALE_TEXT_COLOR)
                        setTextColor(R.id.widget_grade, PpallaeWidgetCommon.STALE_TEXT_COLOR)
                    }
                    setOnClickPendingIntent(
                        R.id.widget_root,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    )
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Throwable) {
                Log.e(PpallaeWidgetCommon.TAG, "[WGT-A1x1] failed id=$widgetId", e)
            }
        }
    }
}
