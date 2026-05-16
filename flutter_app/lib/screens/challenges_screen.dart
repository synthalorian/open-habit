import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../widgets/neon_widgets.dart';
import '../widgets/challenge_card.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(habitProvider);
    final notifier = ref.read(habitProvider.notifier);

    final challenges = data.challenges;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: GradientBackground(
        child: challenges.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No challenges yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete habits to generate challenges!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeCardWidget(
                    challenge: challenges[i],
                    onProgress: challenges[i].completed
                        ? null
                        : () async {
                            await notifier.progressChallenge(
                                challenges[i].id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${challenges[i].title} — ${challenges[i].progress + 1} / ${challenges[i].target}',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ),
      ),
    );
  }
}
