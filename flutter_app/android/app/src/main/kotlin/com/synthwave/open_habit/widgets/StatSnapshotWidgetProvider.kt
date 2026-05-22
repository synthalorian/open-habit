package com.synthwave.open_habit.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity

class StatSnapshotWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val statsJson = widgetData.getString("oh_widget_stats", "[]") ?: "[]"
    val stats = JSONArray(statsJson)

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_stat_snapshot).apply {
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java,
            Uri.parse("openhabit://stats")
        )
        setOnClickPendingIntent(R.id.widget_stats_container, launchIntent)

        if (stats.length() == 0) {
          setTextViewText(R.id.stat_1, "✨ Create stats in app")
          setViewVisibility(R.id.stat_1, View.VISIBLE)
          for (i in 2..6) {
            val resId = context.resources.getIdentifier("stat_$i", "id", context.packageName)
            setViewVisibility(resId, View.GONE)
          }
          return@apply
        }

        for (i in 0 until minOf(stats.length(), 6)) {
          val s = stats.getJSONObject(i)
          val name = s.optString("name", "Stat")
          val icon = s.optString("icon", "⭐")
          val level = s.optInt("level", 1)

          val resId = context.resources.getIdentifier("stat_${i + 1}", "id", context.packageName)
          setTextViewText(resId, "$icon $name Lv.$level")
          setViewVisibility(resId, View.VISIBLE)
        }

        // Hide unused slots
        for (i in stats.length() until 6) {
          val resId = context.resources.getIdentifier("stat_${i + 1}", "id", context.packageName)
          setViewVisibility(resId, View.GONE)
        }
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
