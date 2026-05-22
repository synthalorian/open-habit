package com.synthwave.open_habit.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity

class XpSummaryWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val xpJson = widgetData.getString("oh_widget_xp", "{}") ?: "{}"
    val data = JSONObject(xpJson)

    val level = data.optInt("level", 1)
    val totalXp = data.optInt("totalXp", 0)
    val xpToNext = data.optInt("xpToNext", 100)
    val bestStreak = data.optInt("bestStreak", 0)

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_xp_summary).apply {
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java,
            Uri.parse("openhabit://stats")
        )
        setOnClickPendingIntent(R.id.widget_xp_container, launchIntent)

        setTextViewText(R.id.xp_level, "Lv.$level")
        setTextViewText(R.id.xp_progress, "$totalXp / $xpToNext XP")
        setTextViewText(R.id.xp_streak, "🔥 Best: $bestStreak")

        // Draw a simple XP bar using nested layouts
        val pct = if (xpToNext > 0) (totalXp.toFloat() / xpToNext.toFloat()).coerceIn(0f, 1f) else 0f
        val fillWeight = (pct * 100).toInt()
        setViewVisibility(R.id.xp_bar_fill, if (fillWeight > 0) View.VISIBLE else View.GONE)
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
