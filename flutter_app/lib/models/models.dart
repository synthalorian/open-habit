import 'package:uuid/uuid.dart';

// ─── Enums ────────────────────────────────────────────────────────────────

enum Difficulty { easy, medium, hard, extreme }

enum Frequency { daily, weekly, custom, once }

enum HabitStatus { active, archived, completed }

enum ChallengeType { streak, total, categoryBurst, longStreak }

enum ChallengeStatus { active, completed, failed }


// Helper functions for date formatting and enum capitalization
String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';

String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

// ─── Habit ────────────────────────────────────────────────────────────────

/// Core habit entity — mirrors `open_habit_shared::Habit`.
class Habit {
  final String id;
  final String name;
  final String? description;
  final String category;
  final Difficulty difficulty;
  final Frequency frequency;
  final HabitStatus status;
  final DateTime created_at;
  final DateTime? last_completed;
  final int current_streak;
  final int best_streak;
  final int total_completions;
  final int xp_reward;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.difficulty,
    required this.frequency,
    required this.status,
    required this.created_at,
    this.last_completed,
    required this.current_streak,
    required this.best_streak,
    required this.total_completions,
    required this.xp_reward,
  });

  /// Create a new Habit with defaults (matches Rust `Habit::new`)
  factory Habit.create({
    required String name,
    required String category,
    required Difficulty difficulty,
    required Frequency frequency,
  }) {
    return Habit(
      id: const Uuid().v4(),
      name: name,
      category: category,
      difficulty: difficulty,
      frequency: frequency,
      status: HabitStatus.active,
      created_at: DateTime.now(),
      current_streak: 0,
      best_streak: 0,
      total_completions: 0,
      xp_reward: DifficultyX.DifficultyXP[difficulty.index],
    );
  }

  /// JSON serialization — matches Rust serialized field names (snake_case)
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      difficulty: DifficultyX.fromString(json['difficulty'] as String),
      frequency: FrequencyX.fromString(json['frequency'] as String),
      status: HabitStatusX.fromString(json['status'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
      last_completed: json['last_completed'] == null
          ? null
          : DateTime.parse(json['last_completed'] as String),
      current_streak: json['current_streak'] as int,
      best_streak: json['best_streak'] as int,
      total_completions: json['total_completions'] as int,
      xp_reward: json['xp_reward'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': _capitalize(difficulty.name),
      'frequency': _capitalize(frequency.name),
      'status': _capitalize(status.name),
      'created_at': _formatDate(created_at),
      'last_completed': last_completed != null ? _formatDate(last_completed!) : null,
      'current_streak': current_streak,
      'best_streak': best_streak,
      'total_completions': total_completions,
      'xp_reward': xp_reward,
    };
  }


  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    Difficulty? difficulty,
    Frequency? frequency,
    HabitStatus? status,
    DateTime? created_at,
    DateTime? last_completed,
    int? current_streak,
    int? best_streak,
    int? total_completions,
    int? xp_reward,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      created_at: created_at ?? this.created_at,
      last_completed: last_completed ?? this.last_completed,
      current_streak: current_streak ?? this.current_streak,
      best_streak: best_streak ?? this.best_streak,
      total_completions: total_completions ?? this.total_completions,
      xp_reward: xp_reward ?? this.xp_reward,
    );
  }
}

// ─── Streak ────────────────────────────────────────────────────────────────

class Streak {
  final String habit_id;
  final int count;
  final DateTime started_at;
  final DateTime last_date;
  final bool is_active;

  Streak({
    required this.habit_id,
    required this.count,
    required this.started_at,
    required this.last_date,
    required this.is_active,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      habit_id: json['habit_id'] as String,
      count: json['count'] as int,
      started_at: DateTime.parse(json['started_at'] as String),
      last_date: DateTime.parse(json['last_date'] as String),
      is_active: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'habit_id': habit_id,
        'count': count,
        'started_at': started_at.toIso8601String(),
        'last_date': last_date.toIso8601String(),
        'is_active': is_active,
      };
}

// ─── Achievement ──────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xp_reward;
  final String? condition_type;
  final int? condition_value;
  final bool unlocked;
  final DateTime? unlocked_at;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xp_reward,
    this.condition_type,
    this.condition_value,
    this.unlocked = false,
    this.unlocked_at,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      xp_reward: json['xp_reward'] as int,
      condition_type: json['condition_type'] as String?,
      condition_value: json['condition_value'] as int?,
      unlocked: json['unlocked'] as bool? ?? false,
      unlocked_at: json['unlocked_at'] == null
          ? null
          : DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'xp_reward': xp_reward,
        'condition_type': condition_type,
        'condition_value': condition_value,
        'unlocked': unlocked,
        'unlocked_at': unlocked_at?.toIso8601String(),
      };
}

// ─── Challenge ────────────────────────────────────────────────────────────

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int target;
  final int xp_reward;
  final ChallengeStatus status;
  final int progress;
  final DateTime started_at;
  final DateTime? deadline;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.xp_reward,
    required this.status,
    required this.progress,
    required this.started_at,
    this.deadline,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeTypeX.fromString(json['type'] as String),
      target: json['target'] as int,
      xp_reward: json['xp_reward'] as int,
      status: ChallengeStatusX.fromString(json['status'] as String),
      progress: json['progress'] as int,
      started_at: DateTime.parse(json['started_at'] as String),
      deadline:
          json['deadline'] == null ? null : DateTime.parse(json['deadline'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'target': target,
        'xp_reward': xp_reward,
        'status': status.toString().split('.').last,
        'progress': progress,
        'started_at': started_at.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
      };
}

// ─── Completion Response ──────────────────────────────────────────────────

class CompletionResponse {
  final int xpAwarded;
  final int bonusXp;
  final int achievementXp;
  final int totalXp;
  final int streak;
  final bool levelledUp;
  final List<Map<String, dynamic>> newAchievements;

  CompletionResponse({
    required this.xpAwarded,
    required this.bonusXp,
    required this.achievementXp,
    required this.totalXp,
    required this.streak,
    required this.levelledUp,
    required this.newAchievements,
  });

  factory CompletionResponse.fromJson(Map<String, dynamic> json) {
    return CompletionResponse(
      xpAwarded: json['xp_awarded'] as int,
      bonusXp: json['bonus_xp'] as int,
      achievementXp: json['achievement_xp'] as int,
      totalXp: json['total_xp'] as int,
      streak: json['streak'] as int,
      levelledUp: json['levelled_up'] as bool,
      newAchievements:
          (json['new_achievements'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }
}

// ─── Progression Response ─────────────────────────────────────────────────

class ProgressionResponse {
  final int totalXp;
  final int level;
  final int xpToNext;
  final int progress;

  ProgressionResponse({
    required this.totalXp,
    required this.level,
    required this.xpToNext,
    required this.progress,
  });

  factory ProgressionResponse.fromJson(Map<String, dynamic> json) {
    return ProgressionResponse(
      totalXp: json['total_xp'] as int,
      level: json['level'] as int,
      xpToNext: json['xp_to_next'] as int,
      progress: json['progress'] as int,
    );
  }
}

// ─── XP Record Response ───────────────────────────────────────────────────

class XpRecordResponse {
  final String status;
  final int amount;

  XpRecordResponse({required this.status, required this.amount});

  factory XpRecordResponse.fromJson(Map<String, dynamic> json) {
    return XpRecordResponse(
      status: json['status'] as String,
      amount: json['amount'] as int,
    );
  }
}

// ─── Enum Helpers ─────────────────────────────────────────────────────────

extension DifficultyX on Difficulty {
  static Difficulty fromString(String s) {
    switch (s.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'extreme':
        return Difficulty.extreme;
      default:
        return Difficulty.easy;
    }
  }

  static const List<int> DifficultyXP = [10, 25, 50, 100];
}

extension FrequencyX on Frequency {
  static Frequency fromString(String s) {
    switch (s.toLowerCase()) {
      case 'daily':
        return Frequency.daily;
      case 'weekly':
        return Frequency.weekly;
      case 'custom':
        return Frequency.custom;
      case 'once':
        return Frequency.once;
      default:
        return Frequency.daily;
    }
  }
}

extension HabitStatusX on HabitStatus {
  static HabitStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return HabitStatus.active;
      case 'archived':
        return HabitStatus.archived;
      case 'completed':
        return HabitStatus.completed;
      default:
        return HabitStatus.active;
    }
  }
}

extension ChallengeTypeX on ChallengeType {
  static ChallengeType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'streak':
        return ChallengeType.streak;
      case 'total':
        return ChallengeType.total;
      case 'categoryburst':
        return ChallengeType.categoryBurst;
      case 'longstreak':
        return ChallengeType.longStreak;
      default:
        return ChallengeType.streak;
    }
  }
}

extension ChallengeStatusX on ChallengeStatus {
  static ChallengeStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return ChallengeStatus.active;
      case 'completed':
        return ChallengeStatus.completed;
      case 'failed':
        return ChallengeStatus.failed;
      default:
        return ChallengeStatus.active;
    }
  }
}
