package com.example.ppallae_ppallae

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PpallaeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.ppallae_widget).apply {
                val region = widgetData.getString("region", "지역 미설정")
                val score = widgetData.getString("score", "-")
                val grade = widgetData.getString("grade", "")
                val reco = widgetData.getString(
                    "recommendation",
                    "앱을 열어 빨래지수를 확인하세요",
                )

                setTextViewText(R.id.widget_region, region)
                setTextViewText(R.id.widget_score, score)
                setTextViewText(R.id.widget_grade, grade)
                setTextViewText(R.id.widget_reco, reco)

                // 위젯 탭 → 앱 열기
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
