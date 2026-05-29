import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/imu_frame.dart';
import '../theme/app_theme.dart';

/// Real-time line chart that plots accel X/Y/Z from the latest IMU window.
///
/// Uses a custom painter for performance — no heavy charting library needed
/// for a simple 3-axis scrolling waveform.
class LiveChartWidget extends StatelessWidget {
  final List<ImuFrame> frames;
  final double height;

  const LiveChartWidget({
    super.key,
    required this.frames,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceCard.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  'LIVE ACCELEROMETER',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Outfit',
                  ),
                ),
                const Spacer(),
                _LegendDot(color: AppTheme.accentBlue, label: 'X'),
                const SizedBox(width: 10),
                _LegendDot(color: AppTheme.qualityGood, label: 'Y'),
                const SizedBox(width: 10),
                _LegendDot(color: AppTheme.qualityWarning, label: 'Z'),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: frames.isEmpty
                  ? const Center(
                      child: Text(
                        'No data — connect sensor to start',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _WaveformPainter(frames: frames),
                      child: const SizedBox.expand(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<ImuFrame> frames;

  _WaveformPainter({required this.frames});

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.isEmpty) return;

    // Find range for normalisation
    double minVal = double.infinity, maxVal = double.negativeInfinity;
    for (final f in frames) {
      minVal = math.min(minVal, math.min(f.accelX, math.min(f.accelY, f.accelZ)));
      maxVal = math.max(maxVal, math.max(f.accelX, math.max(f.accelY, f.accelZ)));
    }
    final range = (maxVal - minVal).abs();
    if (range < 0.001) return;

    double norm(double v) => 1.0 - (v - minVal) / range;

    void drawLine(
      List<double> values,
      Color color,
    ) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final x = (i / (values.length - 1)) * size.width;
        final y = norm(values[i]) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(frames.map((f) => f.accelX).toList(), AppTheme.accentBlue);
    drawLine(frames.map((f) => f.accelY).toList(), AppTheme.qualityGood);
    drawLine(frames.map((f) => f.accelZ).toList(), AppTheme.qualityWarning);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.frames != frames;
}
