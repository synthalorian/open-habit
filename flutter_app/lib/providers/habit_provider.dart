import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_state.dart';
import '../services/local_database_service.dart';

// ─── Provider ─────────────────────────────────────────────────────────────

final habitProvider =
    NotifierProvider<HabitNotifier, AppData>(() => HabitNotifier());

// ─── Notifier ─────────────────────────────────────────────────────────────

class HabitNotifier extends Notifier<AppData> {
  final LocalDatabaseService _db = LocalDatabaseService();

  @override
  AppData build() {
    state = AppData.empty();
    _initDb();
    return state;
  }

  Future<void> _initDb() async {
    await _db.init();
    _db.addListener(_onDbChanged);
    _refreshFromDb();
  }

  void _onDbChanged() => _refreshFromDb();

  void _refreshFromDb() {
    final db = _db;
    state = AppData(
      habits: db.habits.map(_toUiHabit).toList(),
      challenges: db.challenges.map(_toUiChallenge).toList(),
      level: db.progression.level,
      currentXP: db.progression.totalXp,
      neededXP: db.progression.xpToNext,
      stats: db.stats.map((s) => PlayerStat(
            id: s.id,
            name: s.name,
            value: s.xpInStat.toDouble(),
            level: s.level,
            xpInStat: s.xpInStat,
            xpToNext: s.xpToNext,
            icon: s.icon,
            color: s.color,
            categoryMappings: s.categoryMappings,
          )).toList(),
      recommendations: const [],
      isLoading: false,
    );
  }

  Future<void> refresh() async => _refreshFromDb();

  // ─── Conversion helpers ──────────────────────────────────────────────────

  Habit _toUiHabit(HabitData h) => Habit(
        id: h.id,
        name: h.name,
        category: h.category,
        xp: h.xpReward,
        completed: h.isCompletedToday,
        isBad: h.isBad,
        streakCount: h.streakCount,
      );

  AppChallenge _toUiChallenge(ChallengeData c) => AppChallenge(
        id: c.id,
        title: c.title,
        description: c.description,
        xp: c.xpReward,
        progress: c.progress,
        target: c.target,
        completed: c.isCompleted,
        oneClick: c.oneClick,
      );

  // ─── Mutations ───────────────────────────────────────────────────────────

  Future<CompletionResultData?> toggleHabit(String id) async {
    try {
      final result = await _db.completeHabit(id);
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> addHabit(String name, String category, int xp) async {
    final difficulty = switch (xp) {
      10 => 'easy',
      25 => 'medium',
      50 => 'hard',
      100 => 'extreme',
      _ => 'easy',
    };
    await _db.addHabit(HabitData(
      id: const Uuid().v4(),
      name: name,
      category: category,
      difficulty: difficulty,
      xpReward: xp,
    ));
  }

  Future<void> addBadHabit(String name, String category, int xp) async {
    await _db.addHabit(HabitData(
      id: const Uuid().v4(),
      name: name,
      category: category,
      difficulty: 'easy',
      xpReward: 10,
      isBad: true,
    ));
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
  }

  Future<void> progressChallenge(String challengeId, {int amount = 1}) async {
    try {
      await _db.progressChallenge(challengeId, amount: amount);
    } catch (_) {}
  }

  Future<void> addRecommendationAsHabit(String recId) async {
    final data = state;
    final rec = data.recommendations.firstWhere((r) => r.id == recId);
    final difficulty = switch (rec.difficulty) {
      'Easy' => 'easy',
      'Medium' => 'medium',
      'Hard' => 'hard',
      'Extreme' => 'extreme',
      _ => 'easy',
    };
    await _db.addHabit(HabitData(
      id: const Uuid().v4(),
      name: rec.name,
      category: rec.category,
      difficulty: difficulty,
      xpReward: AppData.xpForDifficulty(rec.difficulty),
    ));
    state = data.copyWith(
      recommendations:
          List.from(data.recommendations)..removeWhere((r) => r.id == recId),
    );
  }

  void dismissRecommendation(String recId) {
    final data = state;
    state = data.copyWith(
      recommendations:
          List.from(data.recommendations)..removeWhere((r) => r.id == recId),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Future<void> addStat(String name, String icon, String color,
      {String categoryMappings = '[]'}) async {
    await _db.addStat(StatData(
      name: name,
      icon: icon,
      color: color,
      categoryMappings: categoryMappings,
    ));
  }

  Future<void> updateStat(StatData stat) async {
    await _db.updateStat(stat);
  }

  Future<bool> deleteStat(String id) async {
    return await _db.deleteStat(id);
  }

  Future<void> addQuickXP(int amount) async {
    await _db.addQuickXP(amount);
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  Future<void> resetAllData() async {
    await _db.resetAllData();
  }
}
