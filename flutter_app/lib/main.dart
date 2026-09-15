import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart' as home;
import 'services/local_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final db = LocalDatabaseService();
  await db.init();

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
