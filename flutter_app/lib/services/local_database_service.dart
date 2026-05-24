import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'widget_data_service.dart';

// ─── Data Models (self-contained, no HTTP deps) ──────────────────────────

class HabitData {
  final String id;
  final String name;
  final String category;
  final String difficulty; // easy, medium, hard, extreme
  final int xpReward;
  int streakCount;
  String? lastCompleted; // YYYY-MM-DD
  final String createdAt;
  final bool isBad;

  HabitData({
    required this.id,
    required this.name,
    required this.category,
    this.difficulty = 'easy',
    this.xpReward = 10,
    this.streakCount = 0,
    this.lastCompleted,
    String? createdAt,
    this.isBad = false,
  }) : createdAt = createdAt ?? _today();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': isBad ? '🚫 $name' : name,
        'category': category,
        'difficulty': difficulty,
        'xp_reward': xpReward,
        'streak_count': streakCount,
        'last_completed': lastCompleted,
        'created_at': createdAt,
      };

  factory HabitData.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? '';
    final isBad = rawName.startsWith('🚫 ');
    return HabitData(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: isBad ? rawName.substring(2) : rawName,
      category: json['category'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'easy',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 10,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      lastCompleted: json['last_completed'] as String?,
      createdAt: json['created_at'] as String?,
      isBad: isBad,
    );
  }

  bool get isCompletedToday => lastCompleted == _today();

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

class ProgressionData {
  int totalXp;
  int level;
  int xpToNext;

  ProgressionData({this.totalXp = 0, this.level = 1, this.xpToNext = 100});

  Map<String, dynamic> toJson() => {
        'total_xp': totalXp,
        'level': level,
        'xp_to_next': xpToNext,
      };

  factory ProgressionData.fromJson(Map<String, dynamic> json) => ProgressionData(
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        xpToNext: (json['xp_to_next'] as num?)?.toInt() ?? 100,
      );
}

class CompletionResultData {
  final int xpAwarded;
  final int bonusXp;
  final int totalXp;
  final int streak;
  final bool levelledUp;
  final List<AchievementData> newAchievements;

  CompletionResultData({
    required this.xpAwarded,
    required this.bonusXp,
    required this.totalXp,
    required this.streak,
    required this.levelledUp,
    this.newAchievements = const [],
  });
}

class AchievementData {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final bool unlocked;

  AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.xpReward = 0,
    this.unlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'xp_reward': xpReward,
        'unlocked': unlocked,
      };

  factory AchievementData.fromJson(Map<String, dynamic> json) => AchievementData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '⭐',
        xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class StreakData {
  final String habitId;
  final int count;
  final bool isActive;

  StreakData({required this.habitId, required this.count, this.isActive = true});

  Map<String, dynamic> toJson() => {
        'habit_id': habitId,
        'count': count,
        'is_active': isActive,
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        habitId: json['habit_id'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class ChallengeData {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  int progress;
  final int target;
  String status; // active, completed, failed
  final bool oneClick; // true = progressChallenge calls complete it in one tap

  ChallengeData({
    required this.id,
    required this.title,
    this.description = '',
    this.xpReward = 50,
    this.progress = 0,
    this.target = 5,
    this.status = 'active',
    this.oneClick = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'progress': progress,
        'target': target,
        'status': status,
        'one_click': oneClick,
      };

  factory ChallengeData.fromJson(Map<String, dynamic> json) => ChallengeData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 5,
        status: json['status'] as String? ?? 'active',
        oneClick: json['one_click'] as bool? ?? false,
      );

  bool get isCompleted => status == 'completed';
  bool get shouldAutoComplete => oneClick;
}

class StatData {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String categoryMappings;
  int xpInStat;
  int level;
  int xpToNext;

  StatData({
    String? id,
    required this.name,
    this.icon = '💪',
    this.color = '#FF5500',
    this.categoryMappings = '[]',
    this.xpInStat = 0,
    this.level = 1,
    this.xpToNext = 100,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'category_mappings': categoryMappings,
        'xp_in_stat': xpInStat,
        'level': level,
        'xp_to_next': xpToNext,
      };

  factory StatData.fromJson(Map<String, dynamic> json) => StatData(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '💪',
        color: json['color'] as String? ?? '#FF5500',
        categoryMappings: json['category_mappings'] as String? ?? '[]',
        xpInStat: (json['xp_in_stat'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        xpToNext: (json['xp_to_next'] as num?)?.toInt() ?? 100,
      );

  double get progress => xpToNext > 0 ? (xpInStat / xpToNext).clamp(0.0, 1.0) : 0.0;
  Color get displayColor {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF9B71);
    }
  }
}

// ─── Local Database Service ──────────────────────────────────────────────

class LocalDatabaseService extends ChangeNotifier {
  static final LocalDatabaseService _instance = LocalDatabaseService._();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._();

  bool _initialized = false;

  // In-memory caches (persisted to SharedPreferences)
  List<HabitData> _habits = [];
  List<AchievementData> _achievements = [];
  List<ChallengeData> _challenges = [];
  List<StatData> _stats = [];
  ProgressionData _progression = ProgressionData();

  // Getters
  List<HabitData> get habits => List.unmodifiable(_habits);
  List<AchievementData> get achievements => List.unmodifiable(_achievements);
  List<ChallengeData> get challenges => List.unmodifiable(_challenges);
  List<StatData> get stats => List.unmodifiable(_stats);
  ProgressionData get progression => _progression;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Load habits
    final habitsJson = prefs.getString('oh_habits');
    if (habitsJson != null) {
      _habits = (json.decode(habitsJson) as List)
          .map((e) => HabitData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Load progression
    final progJson = prefs.getString('oh_progression');
    if (progJson != null) {
      _progression = ProgressionData.fromJson(json.decode(progJson));
    } else {
      _progression = ProgressionData();
    }

    // Load achievements
    final achJson = prefs.getString('oh_achievements');
    if (achJson != null) {
      _achievements = (json.decode(achJson) as List)
          .map((e) => AchievementData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _achievements = _defaultAchievements();
    }

    // Load challenges
    final chJson = prefs.getString('oh_challenges');
    if (chJson != null) {
      _challenges = (json.decode(chJson) as List)
          .map((e) => ChallengeData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _challenges = _generateDailyChallenges();
    }

    // Load stats
    final stJson = prefs.getString('oh_stats');
    if (stJson != null) {
      _stats = (json.decode(stJson) as List)
          .map((e) => StatData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _stats = _defaultStats();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  // ─── Habit Operations ─────────────────────────────────────────────────

  Future<void> addHabit(HabitData habit) async {
    _habits.add(habit);
    await _persist('oh_habits', _habits.map((h) => h.toJson()).toList());
    notifyListeners();
    WidgetDataService.pushAll(this);
  }

  Future<bool> deleteHabit(String id) async {
    final before = _habits.length;
    _habits.removeWhere((h) => h.id == id);
    if (_habits.length < before) {
      await _persist('oh_habits', _habits.map((h) => h.toJson()).toList());
      notifyListeners();
      WidgetDataService.pushAll(this);
      return true;
    }
    return false;
  }

  Future<CompletionResultData> completeHabit(String id) async {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx < 0) throw Exception('Habit not found');

    final habit = _habits[idx];
    final today = _today();

    // Calculate streak
    final yesterday = _yesterday();
    int newStreak;
    if (habit.lastCompleted == yesterday) {
      newStreak = habit.streakCount + 1;
    } else if (habit.lastCompleted == today) {
      throw Exception('Already completed today');
    } else {
      newStreak = 1;
    }

    // Update habit
    _habits[idx] = HabitData(
      id: habit.id,
      name: habit.name,
      category: habit.category,
      difficulty: habit.difficulty,
      xpReward: habit.xpReward,
      streakCount: newStreak,
      lastCompleted: today,
      isBad: habit.isBad,
    );

    // ── Bad habit relapse penalty ─────────────────────────────────────────────
    // completed after a gap (newStreak==1 but old streak>0) = relapse detected.
    // Drains 30% of in-stat XP + flat penalty proportional to gap days.
    if (habit.isBad && newStreak == 1 && habit.streakCount > 0) {
      final prevStr = habit.lastCompleted ?? today;
      final gapDays = DateTime.now()
              .difference(DateTime.parse('${prevStr}T00:00:00'))
              .inDays
              .clamp(1, 365);
      final penalty = gapDays * 10; // 10 XP per gap day, flat
      for (var i = 0; i < _stats.length; i++) {
        final stat = _stats[i];
        final mappings = _parseCategoryMappings(stat.categoryMappings);
        if (mappings.contains(habit.category)) {
          // Drain 30% of accumulated XP to show the relapse visually
          stat.xpInStat = (stat.xpInStat * 0.7).floor();
          // Flat penalty from total
          stat.xpInStat = (stat.xpInStat - penalty).clamp(0, stat.xpInStat);
        }
      }
    }

    // Calculate XP
    final base = _baseXp(habit.difficulty);
    final bonus = newStreak > 1 ? (newStreak - 1) * 5 : 0;
    final totalAwarded = base + bonus;

    // Award stat XP based on category matching (balanced, per-completion formula)
    final habitCategory = habit.category;
    for (var i = 0; i < _stats.length; i++) {
      final stat = _stats[i];
      final mappings = _parseCategoryMappings(stat.categoryMappings);
      if (mappings.contains(habitCategory)) {
        _awardStatXp(i, _statXp(totalAwarded));
      }
    }

    // Check achievements
    final newAchievements = <AchievementData>[];
    _progression.totalXp += totalAwarded;

    // Level up check
    bool levelledUp = false;
    while (_progression.totalXp >= _progression.xpToNext) {
      _progression.totalXp -= _progression.xpToNext;
      _progression.level += 1;
      _progression.xpToNext = _progression.level * 100;
      levelledUp = true;
    }

    // Check XP milestone achievements
    final totalAfter = _progression.totalXp;
    for (final ach in _achievements.where((a) => !a.unlocked)) {
      // Streak milestones
      if (ach.id.startsWith('ach_streak_')) {
        final threshold = int.tryParse(ach.id.split('_').last) ?? 0;
        if (newStreak >= threshold) {
          final updatedAch = AchievementData(
            id: ach.id, title: ach.title, description: ach.description,
            icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
          );
          _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
          _progression.totalXp += ach.xpReward;
          newAchievements.add(updatedAch);
        }
      }
      // XP milestones — check against totalXp BEFORE level-up subtraction
      if (ach.id == 'ach_first_xp' && totalAfter > 0 && !ach.unlocked) {
        final updatedAch = AchievementData(
          id: ach.id, title: ach.title, description: ach.description,
          icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
        );
        _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
        _progression.totalXp += ach.xpReward;
        newAchievements.add(updatedAch);
      }
      if (ach.id == 'ach_100_xp' && totalAfter >= 100 && !ach.unlocked) {
        final updatedAch = AchievementData(
          id: ach.id, title: ach.title, description: ach.description,
          icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
        );
        _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
        _progression.totalXp += ach.xpReward;
        newAchievements.add(updatedAch);
      }
      if (ach.id == 'ach_500_xp' && totalAfter >= 500 && !ach.unlocked) {
        final updatedAch = AchievementData(
          id: ach.id, title: ach.title, description: ach.description,
          icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
        );
        _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
        _progression.totalXp += ach.xpReward;
        newAchievements.add(updatedAch);
      }
      if (ach.id == 'ach_1000_xp' && totalAfter >= 1000 && !ach.unlocked) {
        final updatedAch = AchievementData(
          id: ach.id, title: ach.title, description: ach.description,
          icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
        );
        _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
        _progression.totalXp += ach.xpReward;
        newAchievements.add(updatedAch);
      }
      if (ach.id == 'ach_5000_xp' && totalAfter >= 5000 && !ach.unlocked) {
        final updatedAch = AchievementData(
          id: ach.id, title: ach.title, description: ach.description,
          icon: ach.icon, xpReward: ach.xpReward, unlocked: true,
        );
        _achievements[_achievements.indexWhere((a) => a.id == ach.id)] = updatedAch;
        _progression.totalXp += ach.xpReward;
        newAchievements.add(updatedAch);
      }
    }

    // Persist everything — stats included so RB/RP listeners always see canonical state
    await _persist('oh_habits', _habits.map((h) => h.toJson()).toList());
    await _persist('oh_progression', _progression.toJson());
    await _persist('oh_achievements', _achievements.map((a) => a.toJson()).toList());
    await _persist('oh_stats', _stats.map((s) => s.toJson()).toList());

    notifyListeners();

    WidgetDataService.pushAll(this);

    return CompletionResultData(
      xpAwarded: totalAwarded,
      bonusXp: bonus,
      totalXp: _progression.totalXp,
      streak: newStreak,
      levelledUp: levelledUp,
      newAchievements: newAchievements,
    );
  }

  // ─── Challenge Operations ─────────────────────────────────────────────

  Future<ChallengeData> progressChallenge(String id, {int amount = 1}) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx < 0) throw Exception('Challenge not found');

    final c = _challenges[idx];
    // One-click challenges jump straight to completion when touched
    final effectiveAmount = c.shouldAutoComplete
        ? (c.target - c.progress).clamp(1, c.target)
        : amount;
    final newProgress = (c.progress + effectiveAmount).clamp(0, c.target);
    final completed = newProgress >= c.target;

    _challenges[idx] = ChallengeData(
      id: c.id,
      title: c.title,
      description: c.description,
      xpReward: c.xpReward,
      progress: newProgress,
      target: c.target,
      status: completed ? 'completed' : 'active',
      oneClick: c.shouldAutoComplete,
    );

    if (completed) {
      _progression.totalXp += c.xpReward;
      await _persist('oh_progression', _progression.toJson());
    }

    await _persist('oh_challenges', _challenges.map((c) => c.toJson()).toList());
    notifyListeners();
    WidgetDataService.pushAll(this);
    return _challenges[idx];
  }

  // ── Quick XP (dev/test helper) ────────────────────────────────────────────

  Future<void> addQuickXP(int amount) async {
    _progression.totalXp += amount;
    // Run level-up check
    while (_progression.totalXp >= _progression.xpToNext) {
      _progression.totalXp -= _progression.xpToNext;
      _progression.level += 1;
      _progression.xpToNext = _progression.level * 100;
    }
    await _persist('oh_progression', _progression.toJson());
    notifyListeners();
    WidgetDataService.pushAll(this);
  }

  // ─── Stat Operations ──────────────────────────────────────────────────

  Future<void> addStat(StatData stat) async {
    _stats.add(stat);
    await _persist('oh_stats', _stats.map((s) => s.toJson()).toList());
    notifyListeners();
    WidgetDataService.pushAll(this);
  }

  Future<void> updateStat(StatData stat) async {
    final idx = _stats.indexWhere((s) => s.id == stat.id);
    if (idx >= 0) {
      _stats[idx] = stat;
      await _persist('oh_stats', _stats.map((s) => s.toJson()).toList());
      notifyListeners();
      WidgetDataService.pushAll(this);
    }
  }

  Future<bool> deleteStat(String id) async {
    final before = _stats.length;
    _stats.removeWhere((s) => s.id == id);
    if (_stats.length < before) {
      await _persist('oh_stats', _stats.map((s) => s.toJson()).toList());
      notifyListeners();
      WidgetDataService.pushAll(this);
      return true;
    }
    return false;
  }

  List<StatData> get defaultStats => _defaultStats();

  // ─── Reset ────────────────────────────────────────────────────────────

  Future<void> resetAllData() async {
    _habits.clear();
    _achievements = _defaultAchievements();
    _challenges = _generateDailyChallenges();
    _stats = _defaultStats();
    _progression = ProgressionData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('oh_habits');
    await prefs.remove('oh_progression');
    await prefs.remove('oh_achievements');
    await prefs.remove('oh_challenges');
    await prefs.remove('oh_stats');

    _persist('oh_achievements', _achievements.map((a) => a.toJson()).toList());
    _persist('oh_challenges', _challenges.map((c) => c.toJson()).toList());
    _persist('oh_stats', _stats.map((s) => s.toJson()).toList());

    notifyListeners();
    WidgetDataService.pushAll(this);
  }

  // ─── Internal Helpers ────────────────────────────────────────────────

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _yesterday() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int _baseXp(String difficulty) {
    switch (difficulty) {
      case 'easy': return 10;
      case 'medium': return 25;
      case 'hard': return 50;
      case 'extreme': return 100;
      default: return 10;
    }
  }

  List<String> _parseCategoryMappings(String mappings) {
    try {
      final list = json.decode(mappings) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  // Per-completion stat XP: 75% phrase scaled by difficulty, no streak bonus
  // easy=8, medium=20, hard=40, extreme=80
  // Balanced so 2–3 daily habits visibly grow stats without breaking total XP economy
  int _statXp(int totalAwarded) {
    final base = _baseXpForStat(totalAwarded);
    // No streak bonus on stat XP — stat XP comes from consistency of completions
    return base;
  }

  int _baseXpForStat(int total) {
    if (total >= 100) return 80;  // extreme
    if (total >= 50) return 40;   // hard
    if (total >= 25) return 20;   // medium
    return 8;                     // easy
  }

  void _awardStatXp(int statIdx, int amount) {
    final stat = _stats[statIdx];
    stat.xpInStat += amount;

    // Check for stat level up
    while (stat.xpInStat >= stat.xpToNext) {
      stat.xpInStat -= stat.xpToNext;
      stat.level += 1;
      stat.xpToNext = stat.level * 100;
    }

    // Stat data will be persisted by the caller after all mutations are done
  }

  List<AchievementData> _defaultAchievements() => [
        AchievementData(id: 'ach_first_xp', title: 'First Steps', description: 'Earn your first XP', icon: '⭐', xpReward: 10),
        AchievementData(id: 'ach_100_xp', title: 'Century', description: 'Earn 100 total XP', icon: '🏅', xpReward: 25),
        AchievementData(id: 'ach_500_xp', title: 'Iron Will', description: 'Earn 500 total XP', icon: '🥈', xpReward: 50),
        AchievementData(id: 'ach_1000_xp', title: 'Unstoppable', description: 'Earn 1,000 total XP', icon: '🥇', xpReward: 100),
        AchievementData(id: 'ach_5000_xp', title: 'Legendary', description: 'Earn 5,000 total XP', icon: '🏆', xpReward: 250),
        AchievementData(id: 'ach_streak_3', title: 'Threepeat', description: '3-day streak', icon: '🔥', xpReward: 15),
        AchievementData(id: 'ach_streak_7', title: 'Week Warrior', description: '7-day streak', icon: '📅', xpReward: 30),
        AchievementData(id: 'ach_streak_14', title: 'Fortnight Force', description: '14-day streak', icon: '💪', xpReward: 50),
        AchievementData(id: 'ach_streak_30', title: 'Monthly Master', description: '30-day streak', icon: '🌙', xpReward: 100),
      ];

  List<ChallengeData> _generateDailyChallenges() => [
        // ── Fitness ──────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_1', title: 'Hydration Hero', description: 'Drink 8 glasses of water today', xpReward: 30, target: 8),
        ChallengeData(id: 'ch_daily_2', title: 'Step Up', description: 'Walk 5,000 steps', xpReward: 25, target: 5000, oneClick: true),
        ChallengeData(id: 'ch_daily_3', title: 'Mindful Minute', description: 'Meditate for 5 minutes', xpReward: 20, target: 5),
        ChallengeData(id: 'ch_daily_4', title: 'Morning Push-ups', description: 'Do 25 push-ups', xpReward: 35, target: 25),
        ChallengeData(id: 'ch_daily_5', title: '10K Steps', description: 'Crush 10,000 steps today', xpReward: 50, target: 10000, oneClick: true),
        ChallengeData(id: 'ch_daily_6', title: 'Stretch It Out', description: '10-minute full body stretch', xpReward: 20, target: 10),
        ChallengeData(id: 'ch_daily_7', title: 'Plank Master', description: 'Hold plank for 2 minutes total', xpReward: 30, target: 120),
        ChallengeData(id: 'ch_daily_8', title: 'Bike or Run', description: '30 minutes of cycling or running', xpReward: 40, target: 30),
        ChallengeData(id: 'ch_daily_9', title: 'Jump Rope', description: '500 jump rope skips', xpReward: 35, target: 500),
        ChallengeData(id: 'ch_daily_10', title: 'Yoga Flow', description: 'Complete a 20-minute yoga session', xpReward: 30, target: 20),
        // ── Learning ─────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_11', title: 'Deep Dive', description: 'Read 30 pages of a book', xpReward: 30, target: 30),
        ChallengeData(id: 'ch_daily_12', title: 'Language Practice', description: '15 minutes studying a new language', xpReward: 25, target: 15),
        ChallengeData(id: 'ch_daily_13', title: 'Podcast Hour', description: 'Listen to a full educational podcast episode', xpReward: 25, target: 60),
        ChallengeData(id: 'ch_daily_14', title: 'Coding Session', description: 'Write code for 45 minutes', xpReward: 40, target: 45),
        ChallengeData(id: 'ch_daily_15', title: 'Skill Builder', description: '30 minutes of deliberate practice', xpReward: 30, target: 30),
        ChallengeData(id: 'ch_daily_16', title: 'Article Deep-Read', description: 'Read and take notes on 3 medium articles', xpReward: 25, target: 3),
        // ── Social ───────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_17', title: 'Outreach', description: 'Reach out to 2 friends or family', xpReward: 30, target: 2),
        ChallengeData(id: 'ch_daily_18', title: 'Compliment Spree', description: 'Give 3 genuine compliments', xpReward: 20, target: 3),
        ChallengeData(id: 'ch_daily_19', title: 'Community Builder', description: 'Attend or organize a community event', xpReward: 40, target: 1),
        ChallengeData(id: 'ch_daily_20', title: 'Handwritten Letter', description: 'Write and send a handwritten note', xpReward: 25, target: 1),
        // ── Finance ──────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_21', title: 'Expense Logger', description: 'Log every expense for the day', xpReward: 25, target: 5),
        ChallengeData(id: 'ch_daily_22', title: 'No Impulse', description: 'Go 24 hours without an unplanned purchase', xpReward: 35, target: 24),
        ChallengeData(id: 'ch_daily_23', title: 'Investor Hour', description: 'Read investing material for 20 minutes', xpReward: 30, target: 20),
        // ── Creative ─────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_24', title: 'Creator Hour', description: 'Work on a creative project for 60 minutes', xpReward: 40, target: 60),
        ChallengeData(id: 'ch_daily_25', title: 'Photo Walk', description: 'Take 10 creative photographs', xpReward: 30, target: 10),
        ChallengeData(id: 'ch_daily_26', title: 'Jam Session', description: 'Play or compose music for 30 minutes', xpReward: 35, target: 30),
        // ── Mindfulness / General ────────────────────────────────
        ChallengeData(id: 'ch_daily_27', title: 'Sunrise Greeter', description: 'Watch the sun come up (or check in with the sky)', xpReward: 25, target: 1),
        ChallengeData(id: 'ch_daily_28', title: 'Digital Sunset', description: 'No screens 1 hour before bed', xpReward: 30, target: 60),
        // ── Nutrition ────────────────────────────────────────────
        ChallengeData(id: 'ch_daily_29', title: 'Veggie Smash', description: 'Eat 5 servings of vegetables today', xpReward: 30, target: 5),
        ChallengeData(id: 'ch_daily_30', title: 'No Added Sugar', description: 'Zero added sugar for the full day', xpReward: 40, target: 1),
        ChallengeData(id: 'ch_daily_31', title: 'Home Cooked', description: 'Cook and eat a totally from-scratch meal', xpReward: 30, target: 1),
      ];

  List<StatData> _defaultStats() => [
        StatData(id: 'stat_spi', name: 'Spirit', icon: '🙏', color: '#BB88FF', categoryMappings: '["Mindfulness","General"]'),
        StatData(id: 'stat_str', name: 'Strength', icon: '💪', color: '#FF5500', categoryMappings: '["Fitness"]'),
        StatData(id: 'stat_int', name: 'Intelligence', icon: '🧠', color: '#00AAFF', categoryMappings: '["Learning","Creative"]'),
        StatData(id: 'stat_vit', name: 'Vitality', icon: '❤️', color: '#FF3333', categoryMappings: '["Mindfulness","Nutrition"]'),
        StatData(id: 'stat_agi', name: 'Agility', icon: '⚡', color: '#FFDD00', categoryMappings: '["Fitness","Productivity"]'),
        StatData(id: 'stat_wis', name: 'Wisdom', icon: '🔮', color: '#AA66FF', categoryMappings: '["Mindfulness","Learning"]'),
        StatData(id: 'stat_cha', name: 'Charisma', icon: '🎭', color: '#FF66AA', categoryMappings: '["Social","Creative"]'),
        StatData(id: 'stat_luc', name: 'Luck', icon: '🍀', color: '#00CC66', categoryMappings: '["Finance","General"]'),
      ];
}
