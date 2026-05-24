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

class ChallengesWidgetProvider : HomeWidgetProvider() {

  companion object {
    private const val TAG = "OHChallenges"
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
      val challengesJson = widgetData.getString("oh_widget_challenges", "[]") ?: "[]"
      val challenges = JSONArray(challengesJson)
      val themeName = widgetData.getString("oh_widget_theme", "light") ?: "light"
      val colors = WidgetThemeUtils.getColors(themeName)

      appWidgetIds.forEach { widgetId ->
        val views = RemoteViews(context.packageName, R.layout.widget_challenges).apply {
          // ── Themed background ─────────────────────────────────────────
          WidgetThemeUtils.applyCardBackground(this, R.id.widget_challenges_container, themeName)

          setOnClickPendingIntent(R.id.widget_challenges_container,
              safeLaunchIntent(context, "openhabit://challenges", MainActivity::class.java))

          // ── Themed header and divider ─────────────────────────────────
          setTextColor(R.id.challenges_header, colors.titleAccent)
          setInt(R.id.challenges_divider, "setBackgroundColor", colors.dividerLine)

          if (challenges.length() == 0) {
            setTextViewText(R.id.challenge_1, "🏆 No active challenges")
            setTextColor(R.id.challenge_1, colors.textMuted)
            setViewVisibility(R.id.challenge_1, View.VISIBLE)
            for (i in 2..3) {
              val resId = context.resources.getIdentifier("challenge_$i", "id", context.packageName)
              setViewVisibility(resId, View.GONE)
            }
            return@apply
          }

          // ── Themed challenge rows ─────────────────────────────────────
          for (i in 0 until minOf(challenges.length(), 3)) {
            val c = challenges.getJSONObject(i)
            val title = c.optString("title", "Challenge")
            val progress = c.optInt("progress", 0)
            val target = c.optInt("target", 1)
            val xpReward = c.optInt("xpReward", 25)

            val resId = context.resources.getIdentifier("challenge_${i + 1}", "id", context.packageName)
            setTextViewText(resId, "$title  $progress/$target (+${xpReward}XP)")
            setTextColor(resId, colors.textPrimary)
            setViewVisibility(resId, View.VISIBLE)
          }

          for (i in challenges.length() until 3) {
            val resId = context.resources.getIdentifier("challenge_${i + 1}", "id", context.packageName)
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
