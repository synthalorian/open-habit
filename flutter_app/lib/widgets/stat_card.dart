import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neon_widgets.dart';

class StatCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeonCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
