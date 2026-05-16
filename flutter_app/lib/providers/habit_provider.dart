import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
import '../models/models.dart' as api;
import '../services/api_client.dart';

// ─── Provider ─────────────────────────────────────────────────────────────

final habitProvider =
    NotifierProvider<HabitNotifier, AppData>(() => HabitNotifier());

// ─── Notifier ─────────────────────────────────────────────────────────────

class HabitNotifier extends Notifier<AppData> {
  final ApiClient _api = ApiClient();
  bool _initialized = false;

  @override
  AppData build() {
    if (!_initialized) {
      _initialized = true;
      state = AppData.empty();
      _loadFromBackend();
    }
    return state;
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> _loadFromBackend() async {
    try {
      final results = await Future.wait([
        _api.fetchHabits(),
        _api.fetchProgression(),
        _api.fetchChallenges(),
        _api.fetchStreaks(),
        _api.fetchStats(),
      ]);

      final habitsApi = results[0] as List<api.Habit>;
      final prog = results[1] as ProgressionResponse;
      final challengesApi = results[2] as List<api.Challenge>;
      final _ = results[3] as List<api.Streak>;
      final statsApi = results[4] as List<PlayerStat>;

      state = AppData(
        habits: habitsApi.map(_toUiHabit).toList(),
        challenges: challengesApi.isNotEmpty
            ? challengesApi.map(_toUiChallenge).toList()
            : state.challenges.isNotEmpty
                ? state.challenges
                : AppData.initial().challenges,
        level: prog.level,
        currentXP: prog.totalXp,
        neededXP: prog.xpToNext > 0 ? prog.xpToNext : 100,
        stats: statsApi,
        recommendations: state.recommendations.isNotEmpty
            ? state.recommendations
            : AppData.initial().recommendations,
        isLoading: false,
      );
    } catch (e) {
      if (state.habits.isEmpty) {
        state = AppData.initial().copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> refresh() async {
    await _loadFromBackend();
  }

  // ─── Conversion helpers ──────────────────────────────────────────────────

  Habit _toUiHabit(api.Habit h) {
    final now = DateTime.now();
    final last = h.last_completed;
    final completed = last != null && _isSameDay(last, now);
    final name = h.name;
    return Habit(
      id: h.id,
      name: name.startsWith('🚫 ') ? name.substring(2) : name,
      category: h.category,
      xp: h.xp_reward,
      completed: completed,
      isBad: name.startsWith('🚫 '),
    );
  }

  AppChallenge _toUiChallenge(api.Challenge c) {
    return AppChallenge(
      id: c.id,
      title: c.title,
      description: c.description,
      xp: c.xp_reward,
      progress: c.progress,
      target: c.target,
      completed: c.status == api.ChallengeStatus.completed,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Mutations ───────────────────────────────────────────────────────────

  /// Toggle a habit complete. Returns the [CompletionResponse] for UI feedback,
  /// or null if the habit was already completed or the call failed.
  Future<CompletionResponse?> toggleHabit(String id) async {
    final habit = state.habits.firstWhere((h) => h.id == id);
    if (habit.completed) return null;

    try {
      final response = await _api.completeHabit(id);
      await refresh();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> addHabit(String name, String category, int xp) async {
    final difficulty = switch (xp) {
      10 => api.Difficulty.easy,
      25 => api.Difficulty.medium,
      50 => api.Difficulty.hard,
      100 => api.Difficulty.extreme,
      _ => api.Difficulty.easy,
    };
    final newHabit = api.Habit.create(
      name: name,
      category: category,
      difficulty: difficulty,
      frequency: api.Frequency.daily,
    );
    try {
      await _api.createHabit(newHabit);
      await refresh();
    } catch (e) {
      // silent fail; user can retry
    }
  }

  Future<void> addBadHabit(String name, String category, int xp) async {
    final difficulty = api.Difficulty.easy;
    final newHabit = api.Habit.create(
      name: "🚫 $name",
      category: category,
      difficulty: difficulty,
      frequency: api.Frequency.daily,
    );
    try {
      await _api.createHabit(newHabit);
      await refresh();
    } catch (e) {
      // silent
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _api.deleteHabit(id);
      await refresh();
    } catch (e) {
      // silent fail
    }
  }

  /// Progress a challenge by [amount] (default 1).
  Future<void> progressChallenge(String challengeId, {int amount = 1}) async {
    try {
      await _api.progressChallenge(challengeId, amount: amount);
      await refresh();
    } catch (e) {
      // silent fail
    }
  }

  void addRecommendationAsHabit(String recId) async {
    final data = state;
    final rec = data.recommendations.firstWhere((r) => r.id == recId);
    final placeholder = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: rec.name,
      category: rec.category,
      xp: AppData.xpForDifficulty(rec.difficulty),
      completed: false,
    );
    state = data.copyWith(
      habits: List.from(data.habits)..add(placeholder),
      recommendations:
          List.from(data.recommendations)..removeWhere((r) => r.id == recId),
    );

    try {
      final difficulty = switch (rec.difficulty) {
        'Easy' => api.Difficulty.easy,
        'Medium' => api.Difficulty.medium,
        'Hard' => api.Difficulty.hard,
        'Extreme' => api.Difficulty.extreme,
        _ => api.Difficulty.easy,
      };
      final newHabitApi = api.Habit.create(
        name: rec.name,
        category: rec.category,
        difficulty: difficulty,
        frequency: api.Frequency.daily,
      );
      await _api.createHabit(newHabitApi);
      await refresh();
    } catch (e) {
      await refresh();
    }
  }

  void dismissRecommendation(String recId) {
    final data = state;
    state = data.copyWith(
      recommendations:
          List.from(data.recommendations)..removeWhere((r) => r.id == recId),
    );
  }
}
