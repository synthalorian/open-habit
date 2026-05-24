import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Simple gradient background for the synthwave theme
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color? startColor;
  final Color? endColor;

  const GradientBackground({
    super.key,
    required this.child,
    this.startColor,
    this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSynthwave = theme.brightness == Brightness.dark &&
        theme.colorScheme.primary.toARGB32() == 0xFF8F00FF;

    return isSynthwave
        ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  startColor ?? const Color(0xFF0d0221),
                  endColor ?? const Color(0xFF240037),
                ],
              ),
            ),
            child: child,
          )
        : child;
  }
}

/// Neon-bordered card with glow effect
class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool neonGlow;          // extra glow for completed / one-tap items

  const NeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.neonGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final glowLayer = neonGlow
        ? BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 6,
          )
        : const BoxShadow(color: Colors.transparent);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          glowLayer,
        ],
      ),
      child: child,
    );
  }
}

/// XP progress bar with animated-style gradient
class XPProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentXP;
  final int neededXP;
  final int level;

  const XPProgressBar({
    super.key,
    required this.progress,
    required this.currentXP,
    required this.neededXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '$currentXP / $neededXP XP',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
