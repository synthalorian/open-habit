package com.synthwave.open_habit.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity

class XpSummaryWidgetProvider : HomeWidgetProvider() {

  companion object {
    private const val TAG = "OHXpSummary"
  }

  private fun safeLaunchIntent(context: Context, uri: String, cls: Class<*>): PendingIntent {
    val intent = Intent(context, cls)
    intent.data = Uri.parse(uri)
    intent.action = "es.antonborri.home_widget.action.LAUNCH"
    return PendingIntent.getActivity(
      context,
      0,
      intent,
      PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    try {
      val xpJson = widgetData.getString("oh_widget_xp", "{}") ?: "{}"
      val data = JSONObject(xpJson)
      val themeName = widgetData.getString("oh_widget_theme", "light") ?: "light"
      val colors = WidgetThemeUtils.getColors(themeName)

      val level = data.optInt("level", 1)
      val totalXp = data.optInt("totalXp", 0)
      val xpToNext = data.optInt("xpToNext", 100)
      val bestStreak = data.optInt("bestStreak", 0)

      appWidgetIds.forEach { widgetId ->
        val views = RemoteViews(context.packageName, R.layout.widget_xp_summary).apply {
          // ── Themed background ─────────────────────────────────────────
          WidgetThemeUtils.applyCardBackground(this, R.id.widget_xp_container, themeName)

          setOnClickPendingIntent(R.id.widget_xp_container,
              safeLaunchIntent(context, "openhabit://stats", MainActivity::class.java))

          // ── Themed text ───────────────────────────────────────────────
          setTextViewText(R.id.xp_level, "Lv.$level")
          setTextColor(R.id.xp_level, colors.titleAccent)

          setTextViewText(R.id.xp_progress, "$totalXp / $xpToNext XP")
          setTextColor(R.id.xp_progress, colors.textPrimary)

          setTextViewText(R.id.xp_streak, "🔥 Best: $bestStreak")
          setTextColor(R.id.xp_streak, colors.textSecondary)

          // ── Themed XP bar ─────────────────────────────────────────────
          val pct = if (xpToNext > 0) (totalXp.toFloat() / xpToNext.toFloat()).coerceIn(0f, 1f) else 0f
          val fillWeight = (pct * 100).toInt()
          setInt(R.id.xp_bar_background, "setBackgroundColor", colors.xpBarBg)
          setInt(R.id.xp_bar_fill, "setBackgroundColor", colors.xpBarFill)
          setViewVisibility(R.id.xp_bar_fill, if (fillWeight > 0) View.VISIBLE else View.GONE)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
      }
    } catch (e: Exception) {
      Log.e(TAG, "Widget update failed", e)
    }
  }
}
