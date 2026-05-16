import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import 'neon_widgets.dart';

class ChallengeCardWidget extends StatelessWidget {
  final AppChallenge challenge;
  final VoidCallback? onProgress;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = challenge.target > 0
        ? (challenge.progress / challenge.target).clamp(0.0, 1.0)
        : 0.0;

    return NeonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: theme.colorScheme.secondary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: challenge.completed
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${challenge.xp} XP',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.primary,
                      ]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.progress} / ${challenge.target}',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              if (!challenge.completed && onProgress != null)
                TextButton.icon(
                  onPressed: onProgress,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Progress',
                    style: GoogleFonts.rajdhani(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
