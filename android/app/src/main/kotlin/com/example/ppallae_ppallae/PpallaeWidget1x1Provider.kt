package com.example.ppallae_ppallae

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
        val gradeLabel = PpallaeWidgetCommon.gradeLabel(gradeCode)

        Log.i(
            PpallaeWidgetCommon.TAG,
            "1x1 onUpdate ids=${appWidgetIds.toList()} grade=$gradeCode score=$score"
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
