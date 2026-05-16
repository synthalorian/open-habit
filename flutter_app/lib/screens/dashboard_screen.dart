import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/habit_provider.dart';
import '../services/local_database_service.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/habit_card.dart';
import '../widgets/challenge_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_bar.dart';
import '../screens/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(habitProvider);
    final notifier = ref.read(habitProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Open Habit',
          style: GoogleFonts.rajdhani(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isLoading) _LoadingShimmer(theme: theme),

                // XP Progress
                NeonCard(
                  padding: const EdgeInsets.all(20),
                  child: XPProgressBar(
                    progress: data.neededXP > 0
                        ? data.currentXP / data.neededXP
                        : 0,
                    currentXP: data.currentXP,
                    neededXP: data.neededXP,
                    level: data.level,
                  ),
                ),
                const SizedBox(height: 24),

                // Today's Habits
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionHeader(title: "Today's Habits"),
                    Text(
                      '${data.completedToday} / ${data.habits.length} done',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                if (data.habits.isEmpty)
                  DashboardEmptyState(
                    icon: Icons.checklist,
                    message: 'No habits yet. Tap + on the Habits tab to start!',
                    theme: theme,
                  )
                else
                  ...data.habits.map((habit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HabitCardWidget(
                        habit: habit,
                        onToggle: () async {
                          final response =
                              await notifier.toggleHabit(habit.id);
                          if (response != null && context.mounted) {
                            _showCompletionDialog(context, response);
                          }
                        },
                        onDelete: () => notifier.deleteHabit(habit.id),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // RPG Stats (compact grid)
                if (data.stats.isNotEmpty) ...[
                  SectionHeader(title: 'RPG Stats'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: data.stats.length,
                    itemBuilder: (ctx, i) => StatBarWidget(
                      stat: data.stats[i],
                      compact: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text(
                              '${data.stats[i].icon} ${data.stats[i].name} — Lv. ${data.stats[i].level}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Active Challenges
                SectionHeader(title: 'Active Challenges'),
                if (data.challenges.isEmpty)
                  DashboardEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'No active challenges. Complete habits to unlock them!',
                    theme: theme,
                  )
                else
                  ...data.challenges.where((c) => !c.completed).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChallengeCardWidget(
                        challenge: c,
                        onProgress: () async {
                          await notifier.progressChallenge(c.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Progressed "${c.title}"!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Active Streaks
                SectionHeader(title: 'Active Streaks'),
                if (data.habits.where((h) => h.streakCount > 0).isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No streaks yet. Keep completing habits daily!',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...data.habits
                      .where((h) => h.streakCount > 0)
                      .take(5)
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
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
                                    h.name,
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
                                      '${h.streakCount} day${h.streakCount == 1 ? '' : 's'}',
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFF5500),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(
      BuildContext context, CompletionResultData response) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              response.levelledUp ? 'LEVEL UP! 🎉' : 'Nice work!',
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: response.levelledUp
                    ? const Color(0xFFFFD700)
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _completionRow(
                'Base XP', '+${response.xpAwarded}', theme, Icons.star),
            if (response.bonusXp > 0)
              _completionRow('Streak Bonus', '+${response.bonusXp}',
                  theme, Icons.local_fire_department),
            if (response.newAchievements.isNotEmpty)
              _completionRow('Achievement',
                  '+${response.newAchievements.fold<int>(0, (sum, a) => sum + a.xpReward)}',
                  theme, Icons.emoji_events),
            if (response.newAchievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Achievements Unlocked:',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              ...response.newAchievements.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events,
                            size: 18, color: const Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${a.title} (+${a.xpReward} XP)',
                            style: GoogleFonts.rajdhani(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const Divider(),
            _completionRow(
                'Streak', '${response.streak} day${response.streak == 1 ? '' : 's'}', theme, Icons.local_fire_department),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going!'),
          ),
        ],
      ),
    );
  }

  Widget _completionRow(
      String label, String value, ThemeData theme, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final ThemeData theme;

  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  final ThemeData theme;

  const _LoadingShimmer({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        )),
      ],
    );
  }
}
