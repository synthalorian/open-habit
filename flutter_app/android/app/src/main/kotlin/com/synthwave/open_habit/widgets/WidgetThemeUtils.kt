package com.synthwave.open_habit.widgets

import android.graphics.Color
import android.widget.RemoteViews
import com.synthwave.open_habit.R

/**
 * Theme-aware colors for all 4 home screen widgets.
 *
 * Called from each widget provider's onUpdate() to set colors
 * programmatically based on the saved theme name in SharedPreferences.
 */
object WidgetThemeUtils {

  // ── Theme name constants (mirrors AppThemeMode in Dart) ────────────

  const val THEME_SYNTHWAVE = "synthwave"
  const val THEME_DARK = "dark"
  const val THEME_LIGHT = "light"

  // ── Per-theme color bundles ────────────────────────────────────────

  data class WidgetColors(
    val cardBg: Int,
    val border: Int,
    val titleAccent: Int,
    val textPrimary: Int,
    val textSecondary: Int,
    val textMuted: Int,
    val dividerLine: Int,
    val xpBarFill: Int,
    val xpBarBg: Int,
    val dateText: Int,
    val completedText: Int,
  )

  fun getColors(themeName: String): WidgetColors {
    return when (themeName) {
      THEME_SYNTHWAVE -> WidgetColors(
        cardBg = Color.parseColor("#240037"),
        border = Color.parseColor("#8F00FF"),
        titleAccent = Color.parseColor("#FFFF66"),
        textPrimary = Color.parseColor("#FFFF66"),
        textSecondary = Color.parseColor("#CCAA44"),
        textMuted = Color.parseColor("#663388"),
        dividerLine = Color.parseColor("#33FF00FF"),
        xpBarFill = Color.parseColor("#FFFF66"),
        xpBarBg = Color.parseColor("#33FFFFFF"),
        dateText = Color.parseColor("#FFFF66"),
        completedText = Color.parseColor("#66FFFF66"),
      )
      THEME_DARK -> WidgetColors(
        cardBg = Color.parseColor("#1C1C2E"),
        border = Color.parseColor("#2A2A44"),
        titleAccent = Color.parseColor("#8F00FF"),
        textPrimary = Color.parseColor("#E0E0F0"),
        textSecondary = Color.parseColor("#A0A0C0"),
        textMuted = Color.parseColor("#666680"),
        dividerLine = Color.parseColor("#332A2A44"),
        xpBarFill = Color.parseColor("#8F00FF"),
        xpBarBg = Color.parseColor("#33FFFFFF"),
        dateText = Color.parseColor("#A0A0C0"),
        completedText = Color.parseColor("#668F00FF"),
      )
      else -> WidgetColors(
        cardBg = Color.parseColor("#FFFFFF"),
        border = Color.parseColor("#8F00FF"),
        titleAccent = Color.parseColor("#8F00FF"),
        textPrimary = Color.parseColor("#1A1A2E"),
        textSecondary = Color.parseColor("#666680"),
        textMuted = Color.parseColor("#9999AA"),
        dividerLine = Color.parseColor("#331A1A2E"),
        xpBarFill = Color.parseColor("#8F00FF"),
        xpBarBg = Color.parseColor("#331A1A2E"),
        dateText = Color.parseColor("#666680"),
        completedText = Color.parseColor("#668F00FF"),
      )
    }
  }

  fun getBackgroundResource(themeName: String): Int {
    return when (themeName) {
      THEME_SYNTHWAVE -> R.drawable.widget_bg_synthwave
      THEME_DARK -> R.drawable.widget_bg_dark
      else -> R.drawable.widget_bg_light
    }
  }

  /** Apply the themed card background to the root container of a widget. */
  fun applyCardBackground(views: RemoteViews, containerId: Int, themeName: String) {
    views.setInt(containerId, "setBackgroundResource", getBackgroundResource(themeName))
  }
}
