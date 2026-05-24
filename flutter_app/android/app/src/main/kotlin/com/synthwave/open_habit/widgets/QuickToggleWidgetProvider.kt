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
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class QuickToggleWidgetProvider : HomeWidgetProvider() {

  companion object {
    private const val TAG = "OHQuickToggle"
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
      val habitsJson = widgetData.getString("oh_widget_habits", "[]") ?: "[]"
      val habits = JSONArray(habitsJson)
      val themeName = widgetData.getString("oh_widget_theme", "light") ?: "light"
      val colors = WidgetThemeUtils.getColors(themeName)

      appWidgetIds.forEach { widgetId ->
        val views = RemoteViews(context.packageName, R.layout.widget_quick_toggle).apply {
          // ── Themed background ─────────────────────────────────────────
          WidgetThemeUtils.applyCardBackground(this, R.id.widget_container, themeName)

          setOnClickPendingIntent(R.id.widget_container,
              safeLaunchIntent(context, "openhabit://dashboard", MainActivity::class.java))

          // ── Themed date and divider ───────────────────────────────────
          val fmt = SimpleDateFormat("EEE, MMM d", Locale.getDefault())
          setTextViewText(R.id.widget_date, fmt.format(Date()))
          setTextColor(R.id.widget_date, colors.dateText)
          setInt(R.id.quick_toggle_divider, "setBackgroundColor", colors.dividerLine)

          if (habits.length() == 0) {
            setTextViewText(R.id.habit_1, "✨ Add a habit to start")
            setTextColor(R.id.habit_1, colors.textMuted)
            setViewVisibility(R.id.habit_1, View.VISIBLE)
            for (i in 2..6) {
              val resId = context.resources.getIdentifier("habit_$i", "id", context.packageName)
              setViewVisibility(resId, View.GONE)
            }
            return@apply
          }

          // ── Themed habit rows ─────────────────────────────────────────
          for (i in 0 until minOf(habits.length(), 6)) {
            val h = habits.getJSONObject(i)
            val name = h.getString("name")
            val isBad = h.optBoolean("isBad", false)
            val completed = h.optBoolean("completed", false)
            val habitId = h.optString("id", "")

            val display = if (isBad) "🚫 $name" else name
            val prefix = if (completed) "✅ " else if (isBad) "⛔ " else "○ "
            val text = "$prefix$display"

            val resId = context.resources.getIdentifier("habit_${i + 1}", "id", context.packageName)
            setTextViewText(resId, text)
            setTextColor(resId, if (completed) colors.completedText else colors.textPrimary)
            setViewVisibility(resId, View.VISIBLE)

            if (!completed && habitId.isNotEmpty()) {
              val bgIntent = HomeWidgetBackgroundIntent.getBroadcast(
                  context,
                  Uri.parse("quickToggle://complete?id=$habitId")
              )
              setOnClickPendingIntent(resId, bgIntent)
            }
          }

          for (i in habits.length() until 6) {
            val resId = context.resources.getIdentifier("habit_${i + 1}", "id", context.packageName)
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
