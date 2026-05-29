import 'package:flutter/material.dart';

import '../services/recommendations_engine.dart';
import '../theme/app_theme.dart';

/// Displays a single coaching [Recommendation] in a glassmorphic card.
class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final int index;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceCard,
        border: Border.all(
          color: _priorityColor().withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _priorityColor().withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _priorityColor(),
                boxShadow: [
                  BoxShadow(
                    color: _priorityColor().withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _categoryIcon(),
                        size: 15,
                        color: _priorityColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        recommendation.category.toUpperCase(),
                        style: TextStyle(
                          color: _priorityColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommendation.message,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Outfit',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor() {
    switch (recommendation.priority) {
      case 'high':
        return AppTheme.qualityPoor;
      case 'medium':
        return AppTheme.qualityWarning;
      default:
        return AppTheme.qualityGood;
    }
  }

  IconData _categoryIcon() {
    switch (recommendation.category.toLowerCase()) {
      case 'movement':
        return Icons.fitness_center_rounded;
      case 'posture':
      case 'alignment':
        return Icons.accessibility_new_rounded;
      case 'breathing':
        return Icons.air_rounded;
      case 'pace':
      case 'speed':
        return Icons.timer_rounded;
      default:
        return Icons.tips_and_updates_rounded;
    }
  }
}
