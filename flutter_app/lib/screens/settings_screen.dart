import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../models/habit_categories.dart';
import '../models/app_state.dart';
import '../providers/habit_provider.dart';

const _buyMeACoffeeUrl = 'https://www.buymeacoffee.com/synthalorian';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GradientSettingsBackground(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Theme'),
              subtitle: Text('Choose your vibe'),
              leading: Icon(Icons.palette_outlined),
            ),
            ...AppThemeMode.all.map((mode) {
              final selected = mode.name == currentTheme.name;
              return RadioListTile<String>(
                value: mode.name,
                groupValue: selected ? mode.name : null,
                title: Text(mode.displayName),
                subtitle: Text(mode.description),
                onChanged: (v) {
                  if (v == null) return;
                  ref.read(themeProvider.notifier).setTheme(mode);
                },
                secondary: Icon(
                  mode.name == 'synthwave' ? Icons.music_note : null,
                  color: theme.colorScheme.secondary,
                ),
              );
            }),
            const Divider(),

            // Habit Library
            ListTile(
              leading: Icon(Icons.library_books_rounded,
                  color: theme.colorScheme.secondary),
              title: const Text('Habit Library'),
              subtitle: const Text('Browse pre-made healthy habits to add'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _HabitLibraryScreen(),
                  ),
                );
              },
            ),

            // Bad Habits
            ListTile(
              leading: Icon(Icons.block_rounded,
                  color: const Color(0xFFFF007F)),
              title: const Text('Quit Bad Habits'),
              subtitle: const Text('Track habits you want to break'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _BadHabitsGuideScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Buy Me A Coffee
            ListTile(
              leading: const Icon(Icons.coffee_rounded,
                  color: Color(0xFFFFDD00)),
              title: const Text('Support Development'),
              subtitle: const Text('Buy me a coffee on BuyMeACoffee'),
              onTap: () => _openUrl(_buyMeACoffeeUrl),
              trailing: const Icon(Icons.open_in_new),
            ),

            const Divider(),

            // XP Test (dev)
            Consumer(
              builder: (context, ref, _) {
                final data = ref.watch(habitProvider);
                final lvl = data.level;
                final xp = data.currentXP;
                final bodyChild = Row(
                  children: [
                    Icon(Icons.science_rounded,
                        color: const Color(0xFFAA66FF)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('XP Test',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('+50 XP (dev helper)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Lvl $lvl · $xp XP',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: const Color(0xFFAA66FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () => ref.read(habitProvider.notifier).addQuickXP(50),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: bodyChild,
                    ),
                  ),
                );
              },
            ),

            // Reset All Data
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded,
                  color: Colors.red.shade400),
              title: Text('Reset All Data',
                  style: TextStyle(color: Colors.red.shade400)),
              subtitle: const Text('Clear all habits, XP, and progress'),
              onTap: () => _showResetDialog(context, ref),
              trailing: Icon(Icons.chevron_right,
                  color: Colors.red.shade400),
            ),

            // Open Source
            ListTile(
              leading: Icon(Icons.code_rounded,
                  color: theme.colorScheme.secondary),
              title: const Text('Open Source'),
              subtitle: const Text(
                  'This app is open source under Apache 2.0'),
              onTap: () => _openUrl(
                  'https://github.com/synthalorian/open-habit'),
              trailing: const Icon(Icons.open_in_new),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Open Habit v0.6.0',
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Built with Rust + Flutter',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your habits shape your world.\nMake them legendary.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your habits, '
          'XP, achievements, and stats. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(habitProvider.notifier).resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared. Start fresh!')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

/// Gradient background for settings
class GradientSettingsBackground extends StatelessWidget {
  final Widget child;
  const GradientSettingsBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0a0a1a),
            Color(0xFF111133),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Habit Library Screen — browse pre-made healthy habits
class _HabitLibraryScreen extends ConsumerWidget {
  const _HabitLibraryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(habitProvider.notifier);
    String selectedCategory = 'All';

    return StatefulBuilder(
      builder: (ctx, setState) => Scaffold(
        appBar: AppBar(title: const Text('Habit Library')),
        body: GradientSettingsBackground(
          child: Column(
            children: [
              // Category filter
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    'All', ...HabitCategories.names,
                  ].map((cat) {
                    final selected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat == 'All' ? '🌟 All' : '${HabitCategories.emojiFor(cat)} $cat',
                          style: GoogleFonts.rajdhani(fontSize: 13),
                        ),
                        selected: selected,
                        onSelected: (v) => setState(() => selectedCategory = cat),
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: HabitLibrary.habits
                      .where((h) => selectedCategory == 'All' || h.category == selectedCategory)
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: ListTile(
                                leading: Text(h.emoji, style: const TextStyle(fontSize: 28)),
                                title: Text(h.name,
                                    style: GoogleFonts.rajdhani(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(h.description,
                                    style: GoogleFonts.rajdhani(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                trailing: IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      color: theme.colorScheme.primary),
                                  onPressed: () {
                                    final xp = AppData.xpForDifficulty(h.difficulty);
                                    notifier.addHabit(h.name, h.category, xp);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added "${h.name}"!'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guide screen for bad habits
class _BadHabitsGuideScreen extends StatelessWidget {
  const _BadHabitsGuideScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quit Bad Habits')),
      body: GradientSettingsBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF007F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text('🚫', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'How It Works',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF007F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bad habits work in reverse. Instead of earning XP for doing something, you earn XP for NOT doing it. Each day you resist, your streak grows and you level up your self-control.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Suggested Bad Habits to Quit',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              '🚬 Smoking / Vaping',
              '📱 Social Media Scrolling',
              '🍔 Junk Food / Sugar Cravings',
              '⏰ Hitting Snooze',
              '🍺 Alcohol',
              '🎮 Video Game Addiction',
              '💬 Negative Self-Talk',
              '💸 Impulse Spending',
              '🛌 Late Night Phone Use',
              '☕ Excessive Caffeine',
            ].map((bad) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      bad,
                      style: GoogleFonts.rajdhani(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Go to the Habits tab and toggle the "Quit Habit" switch to add yours! 🛡️',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
