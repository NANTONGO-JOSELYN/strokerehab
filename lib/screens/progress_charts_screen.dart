import 'package:flutter/material.dart';

class ProgressChartsScreen extends StatefulWidget {
  const ProgressChartsScreen({super.key});

  @override
  State<ProgressChartsScreen> createState() => _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2B),
        elevation: 0,
        title: const Text(
          'Progress & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Quality'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _QualityTab(),
          _SessionsTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly stats
          const Text(
            'This Week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                title: 'Sessions',
                value: '12',
                unit: 'completed',
                icon: Icons.fitness_center,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'Total Reps',
                value: '156',
                unit: 'reps',
                icon: Icons.repeat,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                title: 'Avg Quality',
                value: '76%',
                unit: 'accuracy',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'Streak',
                value: '5',
                unit: 'days',
                icon: Icons.local_fire_department,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress trend
          const Text(
            'Quality Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _SimpleLineChart(),
          ),
        ],
      ),
    );
  }
}

class _QualityTab extends StatelessWidget {
  const _QualityTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercise Quality Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _QualityItem(
            exercise: 'Shoulder Flexion',
            quality: 85,
            sessions: 4,
          ),
          _QualityItem(
            exercise: 'Elbow Flexion',
            quality: 72,
            sessions: 3,
          ),
          _QualityItem(
            exercise: 'Wrist Rotation',
            quality: 68,
            sessions: 2,
          ),
          _QualityItem(
            exercise: 'Grip Strengthening',
            quality: 79,
            sessions: 5,
          ),
          _QualityItem(
            exercise: 'Standing Balance',
            quality: 62,
            sessions: 1,
          ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Sessions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SessionItem(
            date: 'Today • 2:30 PM',
            exercises: 'Shoulder Flexion, Elbow Flexion',
            reps: '32/35',
            quality: 78,
          ),
          _SessionItem(
            date: 'Yesterday • 10:15 AM',
            exercises: 'Grip Strengthening, Wrist Rotation',
            reps: '28/30',
            quality: 72,
          ),
          _SessionItem(
            date: 'May 26 • 3:45 PM',
            exercises: 'Standing Balance, Shoulder Flexion',
            reps: '15/15',
            quality: 81,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceLotevenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _BarChart(value: 65, day: 'Mon'),
                _BarChart(value: 70, day: 'Tue'),
                _BarChart(value: 68, day: 'Wed'),
                _BarChart(value: 78, day: 'Thu'),
                _BarChart(value: 82, day: 'Fri'),
                _BarChart(value: 76, day: 'Sat'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Improvement: +12% this week',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final int value;
  final String day;

  const _BarChart({required this.value, required this.day});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: (value * 1.2).toDouble(),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityItem extends StatelessWidget {
  final String exercise;
  final int quality;
  final int sessions;

  const _QualityItem({
    required this.exercise,
    required this.quality,
    required this.sessions,
  });

  Color _getQualityColor() {
    if (quality >= 80) return Colors.green;
    if (quality >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getQualityColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$quality%',
                  style: TextStyle(
                    color: _getQualityColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quality / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getQualityColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$sessions sessions',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final String date;
  final String exercises;
  final String reps;
  final int quality;

  const _SessionItem({
    required this.date,
    required this.exercises,
    required this.reps,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$quality%',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercises,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reps: $reps',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
