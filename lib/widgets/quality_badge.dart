import 'package:flutter/material.dart';

import '../models/exercise_quality_result.dart';
import '../theme/app_theme.dart';

/// Animated badge that shows the current exercise quality classification.
///
/// Pulses gently when quality is POOR to draw attention.
class QualityBadge extends StatefulWidget {
  final ExerciseQualityResult? result;
  final double size;

  const QualityBadge({super.key, this.result, this.size = 200});

  @override
  State<QualityBadge> createState() => _QualityBadgeState();
}

class _QualityBadgeState extends State<QualityBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isPoor = result?.quality == QualityLevel.poor;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final scale = isPoor ? _pulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: _BadgeContent(result: result, size: widget.size),
    );
  }
}

class _BadgeContent extends StatelessWidget {
  final ExerciseQualityResult? result;
  final double size;

  const _BadgeContent({required this.result, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = result != null
        ? AppTheme.qualityColor(result!.quality)
        : AppTheme.textSecondary;

    final label = result?.label ?? 'Waiting…';
    final score = result?.confidence ?? 0.0;
    final icon = _qualityIcon(result?.quality);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: size * 0.22),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: size * 0.095,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
              height: 1.2,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 6),
            Text(
              '${(score * 100).toStringAsFixed(0)}% confidence',
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: size * 0.065,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _qualityIcon(QualityLevel? q) {
    switch (q) {
      case QualityLevel.good:
        return Icons.check_circle_rounded;
      case QualityLevel.needsImprovement:
        return Icons.warning_rounded;
      case QualityLevel.poor:
        return Icons.cancel_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }
}
