import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../models/app_state.dart' hide Habit;

// Re-export response DTOs so consumers only need one import
export '../models/models.dart' show CompletionResponse, ProgressionResponse;
export '../models/app_state.dart' show PlayerStat;

/// Base configuration for API calls
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration timeout = Duration(seconds: 10);
}

/// REST client for communicating with the open_habit Rust backend.
/// All calls use JSON and the shared type schema from `open_habit_shared`.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// GET /habits — returns all active habits
  Future<List<Habit>> fetchHabits() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/habits'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((h) => Habit.fromJson(h)).toList();
    } else {
      throw _httpError('fetchHabits', resp);
    }
  }

  /// GET /habits/{id}
  Future<Habit> fetchHabit(String id) async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/habits/$id'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      return Habit.fromJson(jsonDecode(resp.body));
    } else if (resp.statusCode == 404) {
      throw Exception('Habit not found');
    } else {
      throw _httpError('fetchHabit', resp);
    }
  }

  /// POST /habits — creates a new habit
  Future<Habit> createHabit(Habit habit) async {
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/habits'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(habit.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 201) {
      return Habit.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('createHabit', resp);
    }
  }

  /// PUT /habits/{id} — partial update (pass only changed fields)
  Future<Habit> updateHabit(String id, Map<String, dynamic> updates) async {
    final resp = await _client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/habits/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updates),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      return Habit.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('updateHabit', resp);
    }
  }

  /// DELETE /habits/{id}
  Future<void> deleteHabit(String id) async {
    final resp = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/habits/$id'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode != 204) {
      throw _httpError('deleteHabit', resp);
    }
  }

  /// POST /habits/{id}/complete — marks habit done today
  /// Returns completion payload with XP, streak, achievements
  Future<CompletionResponse> completeHabit(String id) async {
    final resp = await _client
        .post(Uri.parse('${ApiConfig.baseUrl}/habits/$id/complete'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return CompletionResponse.fromJson(data);
    } else {
      throw _httpError('completeHabit', resp);
    }
  }

  /// GET /progression — player level & XP snapshot
  Future<ProgressionResponse> fetchProgression() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/progression'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      return ProgressionResponse.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('fetchProgression', resp);
    }
  }

  /// POST /xp/record — manual XP award
  Future<XpRecordResponse> recordXp(int amount, {String? source}) async {
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/xp/record'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount,
            if (source != null) 'source': source,
          }),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      return XpRecordResponse.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('recordXp', resp);
    }
  }

  /// GET /achievements — all achievements (locked + unlocked)
  Future<List<Achievement>> fetchAchievements() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/achievements'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((a) => Achievement.fromJson(a)).toList();
    } else {
      throw _httpError('fetchAchievements', resp);
    }
  }

  /// GET /streaks — active streak info
  Future<List<Streak>> fetchStreaks() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/streaks'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((s) => Streak.fromJson(s)).toList();
    } else {
      throw _httpError('fetchStreaks', resp);
    }
  }

  /// POST /challenges/{id}/progress — increment challenge progress
  Future<void> progressChallenge(String challengeId, {int amount = 1}) async {
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/challenges/$challengeId/progress'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'amount': amount}),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode != 200 && resp.statusCode != 202) {
      throw _httpError('progressChallenge', resp);
    }
  }

  /// GET /challenges — current challenges (Phase 2)
  Future<List<Challenge>> fetchChallenges() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/challenges'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((c) => Challenge.fromJson(c)).toList();
    } else {
      throw _httpError('fetchChallenges', resp);
    }
  }

  /// GET /stats — fetch player RPG stats
  Future<List<PlayerStat>> fetchStats() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/stats'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((s) => PlayerStat.fromJson(s)).toList();
    } else {
      throw _httpError('fetchStats', resp);
    }
  }

  /// POST /stats/create — create a new custom stat
  Future<PlayerStat> createStat(PlayerStat stat) async {
    final resp = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/stats/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(stat.toJson()),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 201) {
      return PlayerStat.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('createStat', resp);
    }
  }

  /// PUT /stats/{id} — update a stat (name, icon, color, category_mappings)
  Future<PlayerStat> updateStat(String id, Map<String, dynamic> updates) async {
    final resp = await _client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/stats/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updates),
        )
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      return PlayerStat.fromJson(jsonDecode(resp.body));
    } else {
      throw _httpError('updateStat', resp);
    }
  }

  /// DELETE /stats/{id}
  Future<void> deleteStat(String id) async {
    final resp = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/stats/$id'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode != 204) {
      throw _httpError('deleteStat', resp);
    }
  }

  /// GET /stats/defaults — fetch default stat definitions
  Future<List<PlayerStat>> fetchDefaultStats() async {
    final resp = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/stats/defaults'))
        .timeout(ApiConfig.timeout);

    if (resp.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(resp.body);
      return decoded.map((s) => PlayerStat.fromJson(s)).toList();
    } else {
      throw _httpError('fetchDefaultStats', resp);
    }
  }

  /// Helper for consistent error formatting
  Exception _httpError(String op, http.Response resp) {
    return Exception('$op failed: ${resp.statusCode} ${resp.reasonPhrase}\n${resp.body}');
  }
}

// ─── Response DTO ─────────────────────────────────────────────────────────

/// Response from POST /xp/record
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
