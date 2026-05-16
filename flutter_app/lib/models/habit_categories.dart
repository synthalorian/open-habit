import 'package:flutter/material.dart';

// ─── Category Data ─────────────────────────────────────────────────────

class HabitCategoryInfo {
  final String name;
  final IconData icon;
  final String emoji;
  final Color color;
  final String description;

  const HabitCategoryInfo({
    required this.name,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.description,
  });
}

/// All available habit categories with their visual identity
class HabitCategories {
  static const categories = <HabitCategoryInfo>[
    HabitCategoryInfo(
      name: 'Fitness',
      icon: Icons.fitness_center,
      emoji: '🏋️',
      color: Color(0xFFFF5500),
      description: 'Physical exercise and body training',
    ),
    HabitCategoryInfo(
      name: 'Mindfulness',
      icon: Icons.self_improvement,
      emoji: '🧘',
      color: Color(0xFFB026FF),
      description: 'Meditation, reflection, and mental clarity',
    ),
    HabitCategoryInfo(
      name: 'Learning',
      icon: Icons.menu_book,
      emoji: '📚',
      color: Color(0xFF00E5FF),
      description: 'Reading, studying, and skill acquisition',
    ),
    HabitCategoryInfo(
      name: 'Nutrition',
      icon: Icons.restaurant,
      emoji: '🥗',
      color: Color(0xFF00FF88),
      description: 'Healthy eating and dietary habits',
    ),
    HabitCategoryInfo(
      name: 'Finance',
      icon: Icons.account_balance_wallet,
      emoji: '💰',
      color: Color(0xFFFFD700),
      description: 'Saving, budgeting, and financial planning',
    ),
    HabitCategoryInfo(
      name: 'Social',
      icon: Icons.people,
      emoji: '👥',
      color: Color(0xFFFF9B71),
      description: 'Relationships, communication, and community',
    ),
    HabitCategoryInfo(
      name: 'Creative',
      icon: Icons.palette,
      emoji: '🎨',
      color: Color(0xFFFF2D95),
      description: 'Art, writing, music, and creative expression',
    ),
    HabitCategoryInfo(
      name: 'Productivity',
      icon: Icons.rocket_launch,
      emoji: '⚡',
      color: Color(0xFF00BFFF),
      description: 'Organization, efficiency, and time management',
    ),
    HabitCategoryInfo(
      name: 'General',
      icon: Icons.check_circle_outline,
      emoji: '📋',
      color: Color(0xFFA0A0CC),
      description: 'General habits and miscellaneous goals',
    ),
  ];

  static HabitCategoryInfo? find(String name) {
    return categories.cast<HabitCategoryInfo?>().firstWhere(
      (c) => c!.name.toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
  }

  static IconData iconFor(String name) =>
      find(name)?.icon ?? Icons.check_circle_outline;

  static String emojiFor(String name) => find(name)?.emoji ?? '📋';

  static Color colorFor(String name) =>
      find(name)?.color ?? const Color(0xFFA0A0CC);

  static const List<String> names = [
    'Fitness', 'Mindfulness', 'Learning', 'Nutrition',
    'Finance', 'Social', 'Creative', 'Productivity', 'General',
  ];
}

// ─── Healthy Habit Library ─────────────────────────────────────────────

class SuggestedHabit {
  final String name;
  final String category;
  final String description;
  final String difficulty;
  final String emoji;

  const SuggestedHabit({
    required this.name,
    required this.category,
    required this.description,
    required this.difficulty,
    required this.emoji,
  });
}

class HabitLibrary {
  static const habits = <SuggestedHabit>[
    // Fitness
    SuggestedHabit(name: 'Morning Run', category: 'Fitness', description: 'Run 30 minutes every morning', difficulty: 'Medium', emoji: '🏃'),
    SuggestedHabit(name: 'Push-ups', category: 'Fitness', description: 'Do 20 push-ups', difficulty: 'Easy', emoji: '💪'),
    SuggestedHabit(name: 'Yoga Stretch', category: 'Fitness', description: '15 minute morning yoga', difficulty: 'Easy', emoji: '🧘'),
    SuggestedHabit(name: 'Weight Training', category: 'Fitness', description: '45 minute strength session', difficulty: 'Hard', emoji: '🏋️'),
    SuggestedHabit(name: 'Evening Walk', category: 'Fitness', description: '20 minute walk after dinner', difficulty: 'Easy', emoji: '🚶'),
    SuggestedHabit(name: 'Swim Laps', category: 'Fitness', description: 'Swim 20 laps', difficulty: 'Medium', emoji: '🏊'),
    SuggestedHabit(name: 'HIIT Workout', category: 'Fitness', description: '15 minute high-intensity interval training', difficulty: 'Hard', emoji: '🔥'),
    SuggestedHabit(name: 'Stretch Routine', category: 'Fitness', description: '10 minute full body stretch', difficulty: 'Easy', emoji: '🤸'),
    SuggestedHabit(name: 'Bike Ride', category: 'Fitness', description: 'Cycle for 30 minutes', difficulty: 'Medium', emoji: '🚴'),
    SuggestedHabit(name: 'Plank Challenge', category: 'Fitness', description: 'Hold plank for 2 minutes', difficulty: 'Medium', emoji: '📐'),

    // Mindfulness
    SuggestedHabit(name: 'Meditate', category: 'Mindfulness', description: '10 minute guided meditation', difficulty: 'Easy', emoji: '🧘'),
    SuggestedHabit(name: 'Gratitude Journal', category: 'Mindfulness', description: 'Write 3 things you\'re grateful for', difficulty: 'Easy', emoji: '📝'),
    SuggestedHabit(name: 'Deep Breathing', category: 'Mindfulness', description: '5 minutes box breathing', difficulty: 'Easy', emoji: '🌬️'),
    SuggestedHabit(name: 'Digital Detox', category: 'Mindfulness', description: '1 hour no phone/screens', difficulty: 'Medium', emoji: '📵'),
    SuggestedHabit(name: 'Mindful Eating', category: 'Mindfulness', description: 'Eat one meal without distractions', difficulty: 'Medium', emoji: '🍽️'),
    SuggestedHabit(name: 'Body Scan', category: 'Mindfulness', description: '10 minute body scan meditation', difficulty: 'Easy', emoji: '🔍'),
    SuggestedHabit(name: 'Nature Walk', category: 'Mindfulness', description: 'Walk in nature without headphones', difficulty: 'Easy', emoji: '🌲'),
    SuggestedHabit(name: 'Evening Reflection', category: 'Mindfulness', description: 'Review your day and set intentions', difficulty: 'Easy', emoji: '🌅'),
    SuggestedHabit(name: 'Silent Morning', category: 'Mindfulness', description: 'First 30 minutes of day in silence', difficulty: 'Medium', emoji: '🤫'),
    SuggestedHabit(name: 'Loving Kindness', category: 'Mindfulness', description: '5 minute loving kindness meditation', difficulty: 'Easy', emoji: '💛'),

    // Learning
    SuggestedHabit(name: 'Read 30 Pages', category: 'Learning', description: 'Read 30 pages of a book', difficulty: 'Medium', emoji: '📖'),
    SuggestedHabit(name: 'Learn a Word', category: 'Learning', description: 'Learn one new word and its meaning', difficulty: 'Easy', emoji: '📚'),
    SuggestedHabit(name: 'Online Course', category: 'Learning', description: 'Watch 20 minutes of an online course', difficulty: 'Medium', emoji: '💻'),
    SuggestedHabit(name: 'Practice Language', category: 'Learning', description: '15 minutes of language practice', difficulty: 'Medium', emoji: '🗣️'),
    SuggestedHabit(name: 'Listen to Podcast', category: 'Learning', description: 'Listen to an educational podcast episode', difficulty: 'Easy', emoji: '🎧'),
    SuggestedHabit(name: 'Skill Practice', category: 'Learning', description: '30 minutes deliberate practice of a skill', difficulty: 'Medium', emoji: '🎯'),
    SuggestedHabit(name: 'Documentary', category: 'Learning', description: 'Watch a documentary or TED talk', difficulty: 'Easy', emoji: '🎬'),
    SuggestedHabit(name: 'Write Summary', category: 'Learning', description: 'Write a summary of what you learned today', difficulty: 'Medium', emoji: '✍️'),
    SuggestedHabit(name: 'Quiz Yourself', category: 'Learning', description: 'Test yourself on recent learning material', difficulty: 'Medium', emoji: '❓'),
    SuggestedHabit(name: 'Teach Someone', category: 'Learning', description: 'Explain a concept you learned to someone', difficulty: 'Hard', emoji: '👨‍🏫'),

    // Nutrition
    SuggestedHabit(name: 'Drink Water', category: 'Nutrition', description: 'Drink 8 glasses of water', difficulty: 'Easy', emoji: '💧'),
    SuggestedHabit(name: 'Eat Vegetables', category: 'Nutrition', description: 'Eat 5 servings of vegetables', difficulty: 'Easy', emoji: '🥦'),
    SuggestedHabit(name: 'No Sugar', category: 'Nutrition', description: 'One day with no added sugar', difficulty: 'Hard', emoji: '🚫'),
    SuggestedHabit(name: 'Meal Prep', category: 'Nutrition', description: 'Prepare healthy meals for the week', difficulty: 'Medium', emoji: '🥘'),
    SuggestedHabit(name: 'Green Smoothie', category: 'Nutrition', description: 'Drink a green smoothie', difficulty: 'Easy', emoji: '🥤'),
    SuggestedHabit(name: 'Intermittent Fast', category: 'Nutrition', description: '16:8 intermittent fasting window', difficulty: 'Hard', emoji: '⏰'),
    SuggestedHabit(name: 'Cook at Home', category: 'Nutrition', description: 'Cook a meal from scratch', difficulty: 'Medium', emoji: '👨‍🍳'),
    SuggestedHabit(name: 'Read Labels', category: 'Nutrition', description: 'Read nutrition labels before buying', difficulty: 'Easy', emoji: '🏷️'),
    SuggestedHabit(name: 'Probiotics', category: 'Nutrition', description: 'Eat fermented foods for gut health', difficulty: 'Easy', emoji: '🦠'),
    SuggestedHabit(name: 'Portion Control', category: 'Nutrition', description: 'Eat sensible portions at every meal', difficulty: 'Medium', emoji: '⚖️'),

    // Finance
    SuggestedHabit(name: 'Track Spending', category: 'Finance', description: 'Log all expenses for the day', difficulty: 'Easy', emoji: '📊'),
    SuggestedHabit(name: 'Save \$10', category: 'Finance', description: 'Put \$10 into savings', difficulty: 'Easy', emoji: '💰'),
    SuggestedHabit(name: 'No Impulse Buy', category: 'Finance', description: 'Go one day without an unnecessary purchase', difficulty: 'Medium', emoji: '🚫'),
    SuggestedHabit(name: 'Review Budget', category: 'Finance', description: 'Review and adjust monthly budget', difficulty: 'Medium', emoji: '📋'),
    SuggestedHabit(name: 'Invest Reading', category: 'Finance', description: 'Read 15 minutes about investing', difficulty: 'Medium', emoji: '📈'),
    SuggestedHabit(name: 'Cancel Subscription', category: 'Finance', description: 'Cancel one unused subscription', difficulty: 'Easy', emoji: '✂️'),
    SuggestedHabit(name: 'Round Up Savings', category: 'Finance', description: 'Round up purchases and save the difference', difficulty: 'Easy', emoji: '🪙'),
    SuggestedHabit(name: 'Financial Review', category: 'Finance', description: 'Weekly net worth check-in', difficulty: 'Easy', emoji: '📉'),
    SuggestedHabit(name: 'Meal Plan Budget', category: 'Finance', description: 'Plan meals to reduce food spending', difficulty: 'Medium', emoji: '🛒'),
    SuggestedHabit(name: 'Learn Investing', category: 'Finance', description: 'Study one investment concept', difficulty: 'Medium', emoji: '🎓'),

    // Social
    SuggestedHabit(name: 'Call a Friend', category: 'Social', description: 'Call a friend or family member', difficulty: 'Easy', emoji: '📞'),
    SuggestedHabit(name: 'Send Kind Message', category: 'Social', description: 'Send an encouraging message to someone', difficulty: 'Easy', emoji: '💬'),
    SuggestedHabit(name: 'Volunteer', category: 'Social', description: 'Volunteer for 1 hour', difficulty: 'Medium', emoji: '🤝'),
    SuggestedHabit(name: 'Join Community', category: 'Social', description: 'Attend a local community event', difficulty: 'Medium', emoji: '🏘️'),
    SuggestedHabit(name: 'Compliment Someone', category: 'Social', description: 'Give a genuine compliment', difficulty: 'Easy', emoji: '🌟'),
    SuggestedHabit(name: 'Host Gathering', category: 'Social', description: 'Host a small get-together', difficulty: 'Hard', emoji: '🎉'),
    SuggestedHabit(name: 'Network', category: 'Social', description: 'Connect with one new professional contact', difficulty: 'Medium', emoji: '🔗'),
    SuggestedHabit(name: 'Family Time', category: 'Social', description: '30 minutes quality time with family', difficulty: 'Easy', emoji: '👨‍👩‍👧'),
    SuggestedHabit(name: 'Listen Actively', category: 'Social', description: 'Practice active listening in a conversation', difficulty: 'Medium', emoji: '👂'),
    SuggestedHabit(name: 'Write a Letter', category: 'Social', description: 'Write a handwritten letter to someone', difficulty: 'Easy', emoji: '✉️'),

    // Creative
    SuggestedHabit(name: 'Write 500 Words', category: 'Creative', description: 'Free write 500 words', difficulty: 'Medium', emoji: '✍️'),
    SuggestedHabit(name: 'Sketch Something', category: 'Creative', description: 'Spend 15 minutes sketching', difficulty: 'Easy', emoji: '🎨'),
    SuggestedHabit(name: 'Play Music', category: 'Creative', description: 'Practice an instrument for 20 minutes', difficulty: 'Medium', emoji: '🎵'),
    SuggestedHabit(name: 'Brainstorm Ideas', category: 'Creative', description: 'Write down 10 creative ideas', difficulty: 'Easy', emoji: '💡'),
    SuggestedHabit(name: 'Photography', category: 'Creative', description: 'Take 5 interesting photos', difficulty: 'Easy', emoji: '📷'),
    SuggestedHabit(name: 'DIY Project', category: 'Creative', description: 'Work on a hands-on creative project', difficulty: 'Medium', emoji: '🔨'),
    SuggestedHabit(name: 'Learn a Song', category: 'Creative', description: 'Learn to play a new song', difficulty: 'Hard', emoji: '🎸'),
    SuggestedHabit(name: 'Dance Freely', category: 'Creative', description: 'Dance to one song with full expression', difficulty: 'Easy', emoji: '💃'),
    SuggestedHabit(name: 'Color/Doodle', category: 'Creative', description: 'Fill a page with doodles or coloring', difficulty: 'Easy', emoji: '🖍️'),
    SuggestedHabit(name: 'Record Ideas', category: 'Creative', description: 'Voice record creative ideas as they come', difficulty: 'Easy', emoji: '🎙️'),

    // Productivity
    SuggestedHabit(name: 'Pomodoro Session', category: 'Productivity', description: 'Complete 4 pomodoro cycles', difficulty: 'Medium', emoji: '🍅'),
    SuggestedHabit(name: 'Make Bed', category: 'Productivity', description: 'Make your bed first thing', difficulty: 'Easy', emoji: '🛏️'),
    SuggestedHabit(name: 'Clean Desk', category: 'Productivity', description: 'Organize and clean your workspace', difficulty: 'Easy', emoji: '🧹'),
    SuggestedHabit(name: 'Plan Tomorrow', category: 'Productivity', description: 'Write tomorrow\'s to-do list tonight', difficulty: 'Easy', emoji: '📋'),
    SuggestedHabit(name: 'Morning Routine', category: 'Productivity', description: 'Follow a consistent morning routine', difficulty: 'Medium', emoji: '🌅'),
    SuggestedHabit(name: 'Deep Work Block', category: 'Productivity', description: '2 hours of focused deep work', difficulty: 'Hard', emoji: '🎯'),
    SuggestedHabit(name: 'Inbox Zero', category: 'Productivity', description: 'Clear your email inbox', difficulty: 'Medium', emoji: '📥'),
    SuggestedHabit(name: 'Declutter Space', category: 'Productivity', description: 'Declutter one area of your home', difficulty: 'Easy', emoji: '🧹'),
    SuggestedHabit(name: 'Batch Tasks', category: 'Productivity', description: 'Group similar tasks and complete them together', difficulty: 'Medium', emoji: '📦'),
    SuggestedHabit(name: 'Time Audit', category: 'Productivity', description: 'Track how you spend your time for a day', difficulty: 'Easy', emoji: '⏱️'),

    // Bad habits to quit
    SuggestedHabit(name: 'No Smoking', category: 'General', description: 'One day without smoking', difficulty: 'Hard', emoji: '🚭'),
    SuggestedHabit(name: 'No Social Media', category: 'Productivity', description: 'No social media today', difficulty: 'Hard', emoji: '📵'),
    SuggestedHabit(name: 'No Junk Food', category: 'Nutrition', description: 'One day without junk food', difficulty: 'Medium', emoji: '🍔'),
    SuggestedHabit(name: 'No Snooze', category: 'Productivity', description: 'Get up on first alarm', difficulty: 'Medium', emoji: '⏰'),
    SuggestedHabit(name: 'No Alcohol', category: 'Mindfulness', description: 'One alcohol-free day', difficulty: 'Easy', emoji: '🚫'),
  ];
}

// ─── Stat Icon Gallery ─────────────────────────────────────────────────

class StatIconGallery {
  static const categories = <String, List<String>>{
    'Strength': ['💪', '🏋️', '🦾', '🔥', '⚡', '🛡️', '⚔️', '💢'],
    'Intelligence': ['🧠', '📚', '💡', '🔬', '🎓', '🧮', '📐', '💎'],
    'Vitality': ['❤️', '💚', '💛', '🧬', '🌿', '🍎', '💧', '☀️'],
    'Agility': ['⚡', '💨', '🏃', '🦅', '🌀', '🌪️', '🎯', '🎪'],
    'Wisdom': ['🔮', '🦉', '👁️', '🌟', '🌙', '📜', '🧿', '🏛️'],
    'Charisma': ['🎭', '💫', '👑', '🎤', '💃', '🦋', '🌹', '✨'],
    'Luck': ['🍀', '🎲', '🃏', '🌈', '⭐', '💫', '🔱', '🎰'],
    'Magic': ['🔮', '✨', '🪄', '🧙', '🌟', '🌙', '💫', '🌀'],
    'Nature': ['🌲', '🌊', '🌋', '🍃', '🌸', '🌺', '🌴', '🍄'],
    'Tech': ['💻', '🤖', '🦾', '⚙️', '🔧', '🛠️', '📡', '🔋'],
    'Elements': ['🔥', '💧', '🌪️', '🌍', '⚡', '❄️', '🌋', '💨'],
    'Weapons': ['⚔️', '🗡️', '🛡️', '🏹', '🔫', '💣', '🔪', '🪓'],
    'Cosmic': ['🌌', '⭐', '🌙', '☀️', '🪐', '🌠', '🚀', '👽'],
    'Food': ['🍎', '🥦', '🍗', '🥑', '🍫', '🍩', '🥗', '🍵'],
    'Symbols': ['❤️', '💎', '👑', '⭐', '🔥', '💀', '👁️', '💢'],
  };

  static List<String> get allIcons {
    return categories.values.expand((v) => v).toList()
      ..sort()
      ..toSet().toList();
  }
}
