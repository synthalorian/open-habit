import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Mode Enum ──────────────────────────────────────────────────

class AppThemeMode {
  static const light = AppThemeMode._('light', 'Light', 'Clean and bright');
  static const dark = AppThemeMode._('dark', 'Dark', 'Easy on the eyes');
  static const synthwave =
      AppThemeMode._('synthwave', "Synthwave '84", '🎹 Neon grid');

  const AppThemeMode._(this.name, this.displayName, this.description);

  final String name;
  final String displayName;
  final String description;

  static const all = [light, dark, synthwave];

  static AppThemeMode? fromName(String n) =>
      all.where((m) => m.name == n).firstOrNull;
}

// ─── Synthwave '84 Palette — Omarchy Match ─────────────────────────

class SynthwaveColors {
  // Backgrounds — deep purple space from Omarchy synthwave84
  static const bgPrimary = Color(0xFF0d0221);
  static const bgSecondary = Color(0xFF1a0030);
  static const bgSurface = Color(0xFF240037);
  static const bgElevated = Color(0xFF2d004d);

  // Neon accents — purple family
  static const neonPurple = Color(0xFF8F00FF); // @primary / active border
  static const neonMagenta = Color(0xFFdf00ff); // secondary accent
  static const neonPink = Color(0xFFff00ff); // tertiary accent
  static const neonYellow = Color(0xFFFFFF66); // @foreground — warm amber

  // Text
  static const textPrimary = Color(0xFFFFFF66);
  static const textSecondary = Color(0xFFCCAA44);
  static const textMuted = Color(0xFF663388);

  // Status
  static const xpGold = Color(0xFFFFDD44);
  static const streakFlame = Color(0xFFFF5500);
  static const success = Color(0xFF00FF88);
  static const warning = Color(0xFFFFFF66);
  static const error = Color(0xFFdf00ff);
}

// ─── Theme Definitions ──────────────────────────────────────────────

class AppThemes {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8F00FF),
          brightness: Brightness.light,
          primary: const Color(0xFF8F00FF),
          secondary: const Color(0xFF663388),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Typography.whiteMountainView),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8F00FF),
          secondary: Color(0xFFdf00ff),
          surface: Color(0xFF1C1C2E),
          onSurface: Color(0xFFE0E0F0),
          tertiary: Color(0xFFff00ff),
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0C18),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFE0E0F0),
          displayColor: const Color(0xFF8F00FF),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF2A2A44),
              width: 1,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0C0C18),
        ),
      );

  static ThemeData get synthwaveTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: SynthwaveColors.neonPurple,
          secondary: SynthwaveColors.neonMagenta,
          tertiary: SynthwaveColors.neonPink,
          surface: SynthwaveColors.bgSurface,
          onSurface: SynthwaveColors.textPrimary,
          background: SynthwaveColors.bgPrimary,
          error: SynthwaveColors.error,
        ),
        scaffoldBackgroundColor: SynthwaveColors.bgPrimary,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: SynthwaveColors.textPrimary,
          displayColor: SynthwaveColors.neonPurple,
        ),
        cardTheme: CardThemeData(
          color: SynthwaveColors.bgSurface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: SynthwaveColors.neonPurple,
              width: 1.5,
            ),
          ),
          shadowColor: SynthwaveColors.neonPurple.withValues(alpha: 0.3),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: SynthwaveColors.bgPrimary,
          foregroundColor: SynthwaveColors.textPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SynthwaveColors.neonPurple,
            foregroundColor: SynthwaveColors.bgSecondary,
            elevation: 4,
            shadowColor: SynthwaveColors.neonPurple.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: SynthwaveColors.neonMagenta,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: CircleBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: SynthwaveColors.bgSecondary,
          selectedItemColor: SynthwaveColors.neonPurple,
          unselectedItemColor: SynthwaveColors.textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: SynthwaveColors.bgElevated,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SynthwaveColors.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: SynthwaveColors.textMuted,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: SynthwaveColors.neonMagenta,
              width: 2,
            ),
          ),
          hintStyle: GoogleFonts.rajdhani(
            color: SynthwaveColors.textMuted,
            fontSize: 14,
          ),
        ),
      );

  static ThemeData fromMode(AppThemeMode mode) {
    return switch (mode.name) {
      'dark' => darkTheme,
      'synthwave' => synthwaveTheme,
      _ => lightTheme,
    };
  }
}
