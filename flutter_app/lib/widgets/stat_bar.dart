import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';

/// A sleek RPG-style stat bar with animated fill + pulse on level-up.
class StatBarWidget extends StatefulWidget {
  final PlayerStat stat;
  final VoidCallback? onTap;
  final bool compact;

  const StatBarWidget({
    super.key,
    required this.stat,
    this.onTap,
    this.compact = false,
  });

  @override
  State<StatBarWidget> createState() => _StatBarWidgetState();
}

class _StatBarWidgetState extends State<StatBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(StatBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stat.level > oldWidget.stat.level ||
        widget.stat.xpInStat != oldWidget.stat.xpInStat) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double decayWidthFactor() {
    final used = widget.stat.xpInStat + widget.stat.decayAmount;
    final avail = widget.stat.xpToNext - used;
    return avail <= 0 ? 0.0 : (widget.stat.decayAmount / avail).clamp(0.0, 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.stat.displayColor;
    final progress = widget.stat.progress;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glowIntensity = _pulseController.isAnimating
              ? (_pulse.value * 0.6).clamp(0.0, 0.6)
              : 0.0;
          return Container(
            padding: EdgeInsets.all(widget.compact ? 10 : 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor
                    .withValues(alpha: 0.3 + glowIntensity),
                width: 1.0 + glowIntensity,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.stat.icon,
                        style:
                            TextStyle(fontSize: widget.compact ? 20 : 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.compact
                            ? [
                                Text(
                                  widget.stat.name,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ]
                            : [
                                Text(
                                  widget.stat.name,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.stat.level}',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                      ),
                    ),
                    if (!widget.compact)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lv. ${widget.stat.level}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    if (widget.compact)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.stat.level}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!widget.compact)
                  const SizedBox(height: 8),
                if (!widget.compact)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.7),
                                  accentColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.stat.decayAmount > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: widget.stat.xpToNext > 0
                                  ? decayWidthFactor()
                                  : 0.0,
                              child: Container(
                                height: 8,
                                margin: const EdgeInsets.only(left: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4444)
                                      .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFFF4444)
                                        .withValues(alpha: 0.75),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!widget.compact)
                  const SizedBox(height: 4),
                if (!widget.compact)
                  Text(
                    '${widget.stat.xpInStat} / ${widget.stat.xpToNext} XP',
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

