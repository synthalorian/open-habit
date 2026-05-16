import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_habit/main.dart';

void main() {
  testWidgets('App loads successfully', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: const OpenHabitApp()),
    );
    await tester.pump();
  });
}
