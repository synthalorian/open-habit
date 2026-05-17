import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../models/habit_categories.dart';
import '../providers/habit_provider.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/habit_card.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(habitProvider);
    final notifier = ref.read(habitProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Habits (${data.habits.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitDialog(context, notifier),
            tooltip: 'Add Habit',
          ),
        ],
      ),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          child: data.habits.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checklist,
                                size: 80,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No habits yet',
                              style: GoogleFonts.rajdhani(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first habit',
                              style: GoogleFonts.rajdhani(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () => _showAddHabitDialog(context, notifier),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Habit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.habits.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HabitCardWidget(
                      habit: data.habits[i],
                      onToggle: () async {
                        final response =
                            await notifier.toggleHabit(data.habits[i].id);
                        if (response != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '+${response.xpAwarded} XP!'
                                '${response.levelledUp ? ' LEVEL UP!' : ''}'
                                '${response.newAchievements.isNotEmpty ? ' 🏆' : ''}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onDelete: () =>
                          notifier.deleteHabit(data.habits[i].id),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, HabitNotifier notifier) {
    final nameController = TextEditingController();
    String category = 'General';
    String difficulty = 'Easy';
    bool isBad = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Text(isBad ? '🚫' : '✨', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                isBad ? 'Quit Bad Habit' : 'New Habit',
                style: GoogleFonts.rajdhani(fontSize: 22),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bad habit toggle
                Row(
                  children: [
                    const Text('Build Habit'),
                    Switch(
                      value: isBad,
                      activeThumbColor: const Color(0xFFFF007F),
                      onChanged: (v) =>
                          setDialogState(() => isBad = v),
                    ),
                    Text('Quit Habit',
                        style: TextStyle(
                            color: isBad
                                ? const Color(0xFFFF007F)
                                : null)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isBad ? 'Bad Habit Name' : 'Habit Name',
                    hintText: isBad
                        ? 'e.g., Smoking, Social Media, Junk Food'
                        : 'e.g., Meditate, Read, Run',
                    prefixIcon: Icon(
                      isBad ? Icons.block_rounded : Icons.check_circle_outline,
                      color: isBad ? const Color(0xFFFF007F) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: HabitCategories.names
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Text(HabitCategories.emojiFor(c)),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          )))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? 'General'),
                ),
                if (!isBad) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Easy', 'Medium', 'Hard', 'Extreme']
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                                '$d (${AppData.xpForDifficulty(d)} XP)')))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => difficulty = v ?? 'Easy'),
                  ),
                ],
                if (isBad) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF007F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF007F).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: const Color(0xFFFF007F)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You earn XP for each day you avoid this habit. Stay strong!',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: const Color(0xFFFF007F).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                if (isBad) {
                  notifier.addBadHabit(
                    nameController.text.trim(),
                    category,
                    10,
                  );
                } else {
                  final xp = AppData.xpForDifficulty(difficulty);
                  notifier.addHabit(
                    nameController.text.trim(),
                    category,
                    xp,
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBad
                          ? 'Bad habit added! Stay strong! 🛡️'
                          : 'Habit added! +${AppData.xpForDifficulty(difficulty)} XP',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBad
                    ? const Color(0xFFFF007F)
                    : null,
              ),
              child: Text(isBad ? 'Start Quitting' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
