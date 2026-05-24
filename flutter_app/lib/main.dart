import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart' as home;
import 'services/widget_data_service.dart';
import 'services/local_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(WidgetDataService.backgroundCallback);

  // Push widget data on startup (widgets need fresh state after app launch)
  final db = LocalDatabaseService();
  await db.init();
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode') ?? 'synthwave';
  WidgetDataService.pushAll(db, themeName: savedTheme);

  runApp(
    ProviderScope(
      child: const OpenHabitApp(),
    ),
  );
}

class OpenHabitApp extends ConsumerWidget {
  const OpenHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = AppThemes.fromMode(themeMode);

    return MaterialApp(
      title: 'Open Habit',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const home.HomeScreen(),
    );
  }
}
