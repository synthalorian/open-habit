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
import org.json.JSONArray
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity

class StatSnapshotWidgetProvider : HomeWidgetProvider() {

  companion object {
    private const val TAG = "OHStatsSnap"
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
      val statsJson = widgetData.getString("oh_widget_stats", "[]") ?: "[]"
      val stats = JSONArray(statsJson)
      val themeName = widgetData.getString("oh_widget_theme", "light") ?: "light"
      val colors = WidgetThemeUtils.getColors(themeName)

      appWidgetIds.forEach { widgetId ->
        val views = RemoteViews(context.packageName, R.layout.widget_stat_snapshot).apply {
          // ── Themed background ─────────────────────────────────────────
          WidgetThemeUtils.applyCardBackground(this, R.id.widget_stats_container, themeName)

          setOnClickPendingIntent(R.id.widget_stats_container,
              safeLaunchIntent(context, "openhabit://stats", MainActivity::class.java))

          // ── Themed header and divider ─────────────────────────────────
          setTextColor(R.id.stats_header, colors.titleAccent)
          setInt(R.id.stats_divider, "setBackgroundColor", colors.dividerLine)

          if (stats.length() == 0) {
            setTextViewText(R.id.stat_1, "✨ Create stats in app")
            setTextColor(R.id.stat_1, colors.textMuted)
            setViewVisibility(R.id.stat_1, View.VISIBLE)
            for (i in 2..6) {
              val resId = context.resources.getIdentifier("stat_$i", "id", context.packageName)
              setViewVisibility(resId, View.GONE)
            }
            return@apply
          }

          // ── Themed stat rows ──────────────────────────────────────────
          for (i in 0 until minOf(stats.length(), 6)) {
            val s = stats.getJSONObject(i)
            val name = s.optString("name", "Stat")
            val icon = s.optString("icon", "⭐")
            val level = s.optInt("level", 1)

            val resId = context.resources.getIdentifier("stat_${i + 1}", "id", context.packageName)
            setTextViewText(resId, "$icon $name Lv.$level")
            setTextColor(resId, colors.textPrimary)
            setViewVisibility(resId, View.VISIBLE)
          }

          for (i in stats.length() until 6) {
            val resId = context.resources.getIdentifier("stat_${i + 1}", "id", context.packageName)
            setViewVisibility(resId, View.GONE)
          }
        }

        appWidgetManager.updateAppWidget(widgetId, views)
      }
    } catch (e: Exception) {
      Log.e(TAG, "Widget update failed", e)
    }
  }
}
