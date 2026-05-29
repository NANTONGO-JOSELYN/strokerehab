import 'package:flutter/material.dart';

class ResultsCorrectionScreen extends StatelessWidget {
  final String exerciseId;
  final int completedReps;
  final int targetReps;
  final String qualityScore;
  final double accuracyScore;

  const ResultsCorrectionScreen({
    super.key,
    required this.exerciseId,
    required this.completedReps,
    required this.targetReps,
    required this.qualityScore,
    required this.accuracyScore,
  });

  String _getQualityFeedback() {
    final accuracy = double.tryParse(qualityScore) ?? 0;
    if (accuracy >= 80) {
      return 'Excellent form! Keep up the great work!';
    } else if (accuracy >= 60) {
      return 'Good effort! Try to improve your form.';
    } else {
      return 'Keep practicing! Your form needs adjustment.';
    }
  }

  List<String> _getCorrections() {
    final accuracy = double.tryParse(qualityScore) ?? 0;
    if (accuracy >= 80) {
      return ['Keep your movements smooth', 'Maintain this speed'];
    } else if (accuracy >= 60) {
      return [
        'Slow down your movement',
        'Keep your arm straighter',
        'Maintain better control'
      ];
    } else {
      return [
        'Move slower and more controlled',
        'Check your starting position',
        'Reduce your range of motion initially',
        'Focus on correct technique over speed'
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2B),
        elevation: 0,
        title: const Text(
          'Results & Feedback',
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
            // Performance summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Quality score circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F1419),
                      border: Border.all(
                        color: _getScoreColor(accuracyScore),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            qualityScore,
                            style: TextStyle(
                              color: _getScoreColor(accuracyScore),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quality Score',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        label: 'Reps',
                        value: '$completedReps/$targetReps',
                        color: Colors.blue,
                      ),
                      _StatItem(
                        label: 'Duration',
                        value: '45s',
                        color: Colors.green,
                      ),
                      _StatItem(
                        label: 'Speed',
                        value: 'Moderate',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Feedback
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getScoreColor(accuracyScore).withValues(alpha: 0.15),
                border: Border.all(
                  color: _getScoreColor(accuracyScore).withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFeedbackIcon(accuracyScore),
                    color: _getScoreColor(accuracyScore),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getQualityFeedback(),
                      style: TextStyle(
                        color: _getScoreColor(accuracyScore),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Corrections & Tips
            const Text(
              'Points for Improvement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._getCorrections().map(
              (correction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        size: 12,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        correction,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
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
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to home or next exercise
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getFeedbackIcon(double score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.info;
    return Icons.warning;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
