import 'package:flutter/material.dart';

import 'results_corrections_screen.dart';

class LiveMonitoringScreen extends StatefulWidget {
  final List<String> selectedExerciseIds;
  final String connectedDevice;

  const LiveMonitoringScreen({
    super.key,
    required this.selectedExerciseIds,
    required this.connectedDevice,
  });

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  final int _currentExerciseIndex = 0;
  int _completedReps = 0;
  final int _targetReps = 10;
  bool _isExercising = false;
  double _accuracyScore = 0.0;

  @override
  void initState() {
    super.initState();
    _startExercise();
  }

  void _startExercise() {
    setState(() => _isExercising = true);
    _simulateExerciseData();
  }

  void _simulateExerciseData() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isExercising) {
        setState(() {
          _accuracyScore = 65 + (DateTime.now().millisecond % 30).toDouble();
          if (_completedReps < _targetReps) {
            _completedReps++;
          }
        });
        _simulateExerciseData();
      }
    });
  }

  void _stopExercise() {
    setState(() => _isExercising = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsCorrectionScreen(
          exerciseId: widget.selectedExerciseIds[_currentExerciseIndex],
          completedReps: _completedReps,
          targetReps: _targetReps,
          qualityScore: _accuracyScore.toStringAsFixed(1),
          accuracyScore: _accuracyScore,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isExercising = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseNumber = _currentExerciseIndex + 1;
    final totalExercises = widget.selectedExerciseIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Exercise $exerciseNumber/$totalExercises',
          style: const TextStyle(
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
            // Device connection status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Connected: ${widget.connectedDevice}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main monitoring display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Accuracy circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F1419),
                      border: Border.all(
                        color: _getAccuracyColor(_accuracyScore),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_accuracyScore.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _getAccuracyColor(_accuracyScore),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accuracy',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reps counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Reps',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_completedReps/$_targetReps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Progress bar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _completedReps / _targetReps,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Real-time sensor data
            _SensorDataCard(
              icon: Icons.show_chart,
              title: 'Acceleration (m/s²)',
              value: (9.8 + (DateTime.now().millisecond % 5).toDouble()).toStringAsFixed(2),
              unit: 'm/s²',
            ),
            const SizedBox(height: 12),
            _SensorDataCard(
              icon: Icons.settings_backup_restore,
              title: 'Rotation (°/s)',
              value: (DateTime.now().millisecond % 60).toString(),
              unit: '°/s',
            ),
            const SizedBox(height: 24),

            // Control buttons
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _stopExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _SensorDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _SensorDataCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value $unit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
