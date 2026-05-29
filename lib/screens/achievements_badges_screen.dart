import 'package:flutter/material.dart';

class AchievementsBadgesScreen extends StatefulWidget {
  const AchievementsBadgesScreen({super.key});

  @override
  State<AchievementsBadgesScreen> createState() => _AchievementsBadgesScreenState();
}

class _AchievementsBadgesScreenState extends State<AchievementsBadgesScreen> {
  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'First Step',
      'description': 'Complete your first exercise',
      'icon': '👣',
      'unlocked': true,
      'date': 'May 15, 2024',
    },
    {
      'title': 'Week Warrior',
      'description': 'Complete 7 sessions in a week',
      'icon': '⚔️',
      'unlocked': true,
      'date': 'May 22, 2024',
    },
    {
      'title': 'Perfect Form',
      'description': 'Achieve 90% quality score',
      'icon': '✨',
      'unlocked': true,
      'date': 'May 25, 2024',
    },
    {
      'title': 'Month Milestone',
      'description': 'Exercise for 30 consecutive days',
      'icon': '🏔️',
      'unlocked': false,
      'progress': 24,
    },
    {
      'title': 'Strength Builder',
      'description': 'Complete 100 total reps',
      'icon': '💪',
      'unlocked': true,
      'date': 'May 28, 2024',
    },
    {
      'title': 'Recovery Champion',
      'description': 'Improve quality score by 20%',
      'icon': '🏆',
      'unlocked': false,
      'progress': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a['unlocked'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2B),
        elevation: 0,
        title: const Text(
          'Achievements & Badges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '$unlockedCount',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${_achievements.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${((unlockedCount / _achievements.length) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Complete',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Achievements grid
            const Text(
              'Your Achievements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return _AchievementCard(achievement: achievement);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement['unlocked'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF1A1F2B)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? Colors.white24 : Colors.white12,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement['icon'],
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  achievement['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                if (isUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      achievement['date'],
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (achievement['progress'] as int) / 100,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement['progress']}/100',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isUnlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ),
          if (isUnlocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
