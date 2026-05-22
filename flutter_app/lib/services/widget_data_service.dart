import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'local_database_service.dart';

/// Pushes LocalDatabaseService state to Android home screen widgets.
///
/// Each widget type reads from its own SharedPreferences keys written here.
/// Called by LocalDatabaseService after every mutation so widgets stay in sync.
class WidgetDataService {
  static const String _keyHabits = 'oh_widget_habits';
  static const String _keyXp = 'oh_widget_xp';
  static const String _keyStats = 'oh_widget_stats';
  static const String _keyChallenges = 'oh_widget_challenges';

  // ── Provider class names (must match Kotlin classes in AndroidManifest) ──

  static const String _quickToggleProvider =
      'com.synthwave.open_habit.widgets.QuickToggleWidgetProvider';
  static const String _xpSummaryProvider =
      'com.synthwave.open_habit.widgets.XpSummaryWidgetProvider';
  static const String _statSnapshotProvider =
      'com.synthwave.open_habit.widgets.StatSnapshotWidgetProvider';
  static const String _challengesProvider =
      'com.synthwave.open_habit.widgets.ChallengesWidgetProvider';

  /// Push data for ALL 4 widgets and trigger their updates.
  static Future<void> pushAll(LocalDatabaseService db) async {
    await Future.wait([
      _pushHabits(db),
      _pushXp(db),
      _pushStats(db),
      _pushChallenges(db),
    ]);
  }

  // ── Quick Toggle: today's habits ────────────────────────────────────────

  static Future<void> _pushHabits(LocalDatabaseService db) async {
    final today = _today();
    final habits = db.habits.where((h) {
      // Show habits that are either not completed today or are bad habits (reverse)
      return h.lastCompleted != today || h.isBad;
    }).take(6).toList();

    final json = jsonEncode(habits.map((h) => {
      'id': h.id,
      'name': h.name,
      'category': h.category,
      'difficulty': h.difficulty,
      'xp': h.xpReward,
      'isBad': h.isBad,
      'completed': h.lastCompleted == today,
    }).toList());

    await HomeWidget.saveWidgetData<String>(_keyHabits, json);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _quickToggleProvider,
    );
  }

  // ── XP Summary: level, XP, streaks ──────────────────────────────────────

  static Future<void> _pushXp(LocalDatabaseService db) async {
    final prog = db.progression;
    // Find best streak across habits
    int bestStreak = 0;
    for (final h in db.habits) {
      if (h.streakCount > bestStreak) bestStreak = h.streakCount;
    }

    final json = jsonEncode({
      'level': prog.level,
      'totalXp': prog.totalXp,
      'xpToNext': prog.xpToNext,
      'bestStreak': bestStreak,
    });

    await HomeWidget.saveWidgetData<String>(_keyXp, json);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _xpSummaryProvider,
    );
  }

  // ── Stat Snapshot: RPG stats with levels ────────────────────────────────

  static Future<void> _pushStats(LocalDatabaseService db) async {
    final stats = db.stats.map((s) => {
      'id': s.id,
      'name': s.name,
      'icon': s.icon,
      'level': s.level,
      'color': s.color,
    }).toList();

    await HomeWidget.saveWidgetData<String>(
      _keyStats,
      jsonEncode(stats),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _statSnapshotProvider,
    );
  }

  // ── Challenges: active daily challenges ─────────────────────────────────

  static Future<void> _pushChallenges(LocalDatabaseService db) async {
    final challenges = db.challenges
        .where((c) => c.status == 'Active')
        .map((c) => {
      'title': c.title,
      'description': c.description,
      'progress': c.progress,
      'target': c.target,
      'xpReward': c.xpReward,
    }).toList();

    await HomeWidget.saveWidgetData<String>(
      _keyChallenges,
      jsonEncode(challenges),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: _challengesProvider,
    );
  }

  /// Background callback – called when a widget click triggers Dart code.
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? data) async {
    if (data == null) return;

    // Parse: quickToggle://complete?id=abc-123
    if (data.host == 'quickToggle' && data.path == '/complete') {
      final habitId = data.queryParameters['id'];
      if (habitId == null || habitId.isEmpty) return;

      final db = LocalDatabaseService();
      await db.init();
      await db.completeHabit(habitId);
      await pushAll(db);
    }
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
