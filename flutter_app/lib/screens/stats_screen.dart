import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import '../services/local_database_service.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_bar.dart';
import '../widgets/stat_dialogs.dart';

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

              // XP Timeline Chart
              SectionHeader(title: 'XP Timeline'),
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: _XpTimelineChart(currentXP: data.currentXP, level: data.level),
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
              _AchievementPreview(data: data),
              const SizedBox(height: 24),

              // Active Streaks
              SectionHeader(title: 'Active Streaks'),
              if (data.habits.where((h) => h.streakCount > 0).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Create habits and complete them daily to build streaks!',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                ...data.habits
                    .where((h) => h.streakCount > 0)
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

class _XpTimelineChart extends StatelessWidget {
  final int currentXP;
  final int level;

  const _XpTimelineChart({required this.currentXP, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show a simple bar chart: level milestones with current XP highlighted
    final levels = [1, 2, 3, 4, 5, level].toSet().toList()..sort();
    final maxXp = levels.last * 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxXp.toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Lv. ${levels[group.x.toInt()]}',
                TextStyle(color: theme.colorScheme.onSurface),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < levels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${levels[idx]}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: levels.asMap().entries.map((entry) {
          final lvl = entry.value;
          final xpForLevel = lvl * 100;
          final isCurrent = lvl == level;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: isCurrent ? currentXP.toDouble() : xpForLevel.toDouble(),
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5500).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${habit.streakCount} day${habit.streakCount == 1 ? '' : 's'}',
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF5500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementPreview extends ConsumerWidget {
  final dynamic data;

  const _AchievementPreview({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = LocalDatabaseService();

    return FutureBuilder<List<AchievementData>>(
      future: db.init().then((_) => db.achievements),
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

        final achievements = snap.data ?? <AchievementData>[];
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
            final unlocked = a.unlocked;
            final progress = _achievementProgress(a, data);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          a.icon,
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
                                a.title,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: unlocked
                                      ? const Color(0xFFFFD700)
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                              Text(
                                a.description,
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
                            unlocked ? '+${a.xpReward} XP' : '🔒',
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
                    // Progress bar for locked achievements
                    if (!unlocked && progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    theme.colorScheme.secondary.withValues(alpha: 0.7),
                                    theme.colorScheme.secondary,
                                  ]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  double? _achievementProgress(AchievementData ach, dynamic data) {
    final currentXp = data.currentXP as int? ?? 0;
    final habits = data.habits as List? ?? [];
    final maxStreak = habits
        .map((h) => (h.streakCount as int?) ?? 0)
        .fold<int>(0, (max, s) => s > max ? s : max);

    return switch (ach.id) {
      'ach_first_xp' => currentXp >= 10 ? 1.0 : (currentXp / 10),
      'ach_100_xp' => (currentXp / 100).clamp(0.0, 1.0),
      'ach_500_xp' => (currentXp / 500).clamp(0.0, 1.0),
      'ach_1000_xp' => (currentXp / 1000).clamp(0.0, 1.0),
      'ach_5000_xp' => (currentXp / 5000).clamp(0.0, 1.0),
      'ach_streak_3' => (maxStreak / 3).clamp(0.0, 1.0),
      'ach_streak_7' => (maxStreak / 7).clamp(0.0, 1.0),
      'ach_streak_14' => (maxStreak / 14).clamp(0.0, 1.0),
      'ach_streak_30' => (maxStreak / 30).clamp(0.0, 1.0),
      _ => null,
    };
  }
}
