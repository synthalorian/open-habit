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

class ChallengesWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val challengesJson = widgetData.getString("oh_widget_challenges", "[]") ?: "[]"
    val challenges = JSONArray(challengesJson)

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_challenges).apply {
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java,
            Uri.parse("openhabit://challenges")
        )
        setOnClickPendingIntent(R.id.widget_challenges_container, launchIntent)

        if (challenges.length() == 0) {
          setTextViewText(R.id.challenge_1, "🏆 No active challenges")
          setViewVisibility(R.id.challenge_1, View.VISIBLE)
          for (i in 2..3) {
            val resId = context.resources.getIdentifier("challenge_$i", "id", context.packageName)
            setViewVisibility(resId, View.GONE)
          }
          return@apply
        }

        for (i in 0 until minOf(challenges.length(), 3)) {
          val c = challenges.getJSONObject(i)
          val title = c.optString("title", "Challenge")
          val progress = c.optInt("progress", 0)
          val target = c.optInt("target", 1)
          val xpReward = c.optInt("xpReward", 25)

          val resId = context.resources.getIdentifier("challenge_${i + 1}", "id", context.packageName)
          setTextViewText(resId, "$title  $progress/$target (+${xpReward}XP)")
          setViewVisibility(resId, View.VISIBLE)
        }

        // Hide unused slots
        for (i in challenges.length() until 3) {
          val resId = context.resources.getIdentifier("challenge_${i + 1}", "id", context.packageName)
          setViewVisibility(resId, View.GONE)
        }
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
