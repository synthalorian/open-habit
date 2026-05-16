import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../models/habit_categories.dart';
import 'neon_widgets.dart';

class HabitCardWidget extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final bool showDelete;
  final VoidCallback? onDelete;

  const HabitCardWidget({
    super.key,
    required this.habit,
    required this.onToggle,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catInfo = HabitCategories.find(habit.category);
    final catIcon = catInfo?.icon ?? Icons.check_circle_outline;
    final catEmoji = catInfo?.emoji ?? '📋';
    final catColor = catInfo?.color ?? theme.colorScheme.primary;
    final isBad = habit.isBad;
    final accentColor = isBad ? const Color(0xFFFF007F) : catColor;

    return NeonCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          // Category emoji/icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(catEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),

          // Check circle
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: habit.completed
                  ? (isBad ? const Color(0xFFFF007F) : theme.colorScheme.primary)
                  : theme.colorScheme.surface.withValues(alpha: 0.5),
              child: habit.completed
                  ? Icon(isBad ? Icons.block_rounded : Icons.check_rounded,
                      color: theme.colorScheme.onPrimary, size: 18)
                  : Icon(
                      isBad ? Icons.block_rounded : Icons.check_rounded,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.4),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isBad)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF007F).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'QUIT',
                            style: GoogleFonts.rajdhani(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF007F),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: habit.completed
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface,
                          decoration: habit.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  habit.category,
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: catColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isBad ? '+${habit.xp} 🛡️' : '+${habit.xp} XP',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),

          // Delete button
          if (showDelete && onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: theme.colorScheme.error,
              onPressed: () => _showDeleteConfirm(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('Remove "${habit.name}" from your habits?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
