import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/habit_provider.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_bar.dart';
import '../widgets/stat_dialogs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_client.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Custom Stat',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => const StatCreateDialog(),
              );
              if (result == true) {
                ref.read(habitProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              SectionHeader(title: 'Overview'),
              Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      icon: Icons.star_rounded,
                      label: 'Total XP',
                      value: '${data.currentXP}',
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCardWidget(
                      icon: Icons.trending_up_rounded,
                      label: 'Level',
                      value: '${data.level}',
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Done Today',
                      value: '${data.completedToday} / ${data.habits.length}',
                      color: const Color(0xFFFF5500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCardWidget(
                      icon: Icons.emoji_events_rounded,
                      label: 'Challenges',
                      value: '${data.challenges.where((c) => c.completed).length} / ${data.challenges.length}',
                      color: const Color(0xFFB026FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // RPG Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionHeader(title: 'RPG Stats'),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => const StatCreateDialog(),
                      );
                      if (result == true) {
                        ref.read(habitProvider.notifier).refresh();
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('New Stat',
                        style: GoogleFonts.rajdhani(fontSize: 12)),
                  ),
                ],
              ),
              if (data.stats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('🔮', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        'No stats yet. Complete habits to level up!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...data.stats.map((stat) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StatBarWidget(
                        stat: stat,
                        onTap: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (_) => StatCustomizeDialog(stat: stat),
                          );
                          if (result == true) {
                            ref.read(habitProvider.notifier).refresh();
                          }
                        },
                      ),
                    )),
              const SizedBox(height: 24),

              // Achievements
              SectionHeader(title: 'Achievements'),
              _AchievementPreview(),
              const SizedBox(height: 24),

              // Active Streaks
              SectionHeader(title: 'Active Streaks'),
              if (data.habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Create habits to start building streaks!',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                ...data.habits
                    .where((h) => !h.isBad)
                    .take(5)
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _StreakRow(habit: h),
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final dynamic habit;
  const _StreakRow({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              size: 16, color: const Color(0xFFFF5500)),
          const SizedBox(width: 8),
          Text(
            habit.name,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            'Click to complete →',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<List<dynamic>>(
      future: _fetchAchievements(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading achievements...',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final achievements = snap.data ?? [];
        if (achievements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Start completing habits to earn achievements!',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        return Column(
          children: achievements.map((a) {
            final unlocked = a['unlocked'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: unlocked
                      ? theme.colorScheme.surface.withValues(alpha: 0.3)
                      : theme.colorScheme.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: unlocked
                      ? Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      a['icon'] as String? ?? '🏆',
                      style: TextStyle(
                        fontSize: 24,
                        color: unlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] as String? ?? '',
                            style: GoogleFonts.rajdhani(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: unlocked
                                  ? const Color(0xFFFFD700)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          Text(
                            a['description'] as String? ?? '',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: unlocked ? 0.6 : 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                            : theme.colorScheme.surface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        unlocked ? '+${a['xp_reward']} XP' : '🔒',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? const Color(0xFFFFD700)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchAchievements() async {
    try {
      final client = http.Client();
      final resp = await client
          .get(Uri.parse('http://localhost:3000/achievements'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }
}
