import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../services/widget_data_service.dart';
import '../services/local_database_service.dart';

// ─── Theme Provider (riverpod v3: uses Notifier instead of StateNotifier) ──

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    _loadSaved();
    // Return default immediately; _loadSaved async-updates later
    return AppThemeMode.synthwave;
  }

  static const _key = 'theme_mode';

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      final mode = AppThemeMode.fromName(saved ?? '');
      if (mode != null) {
        state = mode;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
      // Push theme to widgets so they recolor immediately
      final db = LocalDatabaseService();
      await db.init();
      await WidgetDataService.pushAll(db, themeName: mode.name);
    } catch (_) {}
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeMode>(() => ThemeNotifier());
