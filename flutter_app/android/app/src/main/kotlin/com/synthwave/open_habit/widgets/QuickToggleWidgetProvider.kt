package com.synthwave.open_habit.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import com.synthwave.open_habit.R
import com.synthwave.open_habit.MainActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class QuickToggleWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val habitsJson = widgetData.getString("oh_widget_habits", "[]") ?: "[]"
    val habits = JSONArray(habitsJson)

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_quick_toggle).apply {
        // Open app on widget background tap
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java,
            Uri.parse("openhabit://dashboard")
        )
        setOnClickPendingIntent(R.id.widget_container, launchIntent)

        // Show today's date
        val fmt = SimpleDateFormat("EEE, MMM d", Locale.getDefault())
        setTextViewText(R.id.widget_date, fmt.format(Date()))

        if (habits.length() == 0) {
          setTextViewText(R.id.habit_1, "✨ Add a habit to start")
          setViewVisibility(R.id.habit_1, View.VISIBLE)
          for (i in 2..6) {
            val resId = context.resources.getIdentifier("habit_$i", "id", context.packageName)
            setViewVisibility(resId, View.GONE)
          }
          return@apply
        }

        // Populate up to 6 habits
        for (i in 0 until minOf(habits.length(), 6)) {
          val h = habits.getJSONObject(i)
          val name = h.getString("name")
          val isBad = h.optBoolean("isBad", false)
          val completed = h.optBoolean("completed", false)
          val category = h.optString("category", "General")
          val habitId = h.optString("id", "")

          val display = if (isBad) "🚫 $name" else name
          val prefix = if (completed) "✅ " else if (isBad) "⛔ " else "○ "
          val text = "$prefix$display"

          val resId = context.resources.getIdentifier("habit_${i + 1}", "id", context.packageName)
          setTextViewText(resId, text)
          setTextColor(resId, if (completed) Color.parseColor("#4DFF9B71") else Color.parseColor("#FFFFFFFF"))
          setViewVisibility(resId, View.VISIBLE)

          // Background intent to complete habit via Dart callback
          if (!completed && habitId.isNotEmpty()) {
            val bgIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("quickToggle://complete?id=$habitId")
            )
            setOnClickPendingIntent(resId, bgIntent)
          }
        }

        // Hide unused slots
        for (i in habits.length() until 6) {
          val resId = context.resources.getIdentifier("habit_${i + 1}", "id", context.packageName)
          setViewVisibility(resId, View.GONE)
        }
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
