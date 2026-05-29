import 'dart:convert';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A single coaching recommendation shown in the UI.
class Recommendation {
  final String message;
  final String priority; // 'high' | 'medium' | 'low'
  final String category; // 'movement' | 'alignment' | 'pace' | 'breathing' | etc.

  const Recommendation({
    required this.message,
    required this.priority,
    required this.category,
  });
}

/// Loads exercise-specific coaching tips from [assets/config/recommendations.json]
/// and returns the appropriate list for the current exercise + quality level.
class RecommendationsEngine {
  Map<String, dynamic>? _config;
  bool _ready = false;

  bool get isReady => _ready;

  // ── Initialisation ─────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_ready) return;
    try {
      final raw = await rootBundle.loadString('assets/config/recommendations.json');
      _config = jsonDecode(raw) as Map<String, dynamic>;
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  // ── Recommendation lookup ──────────────────────────────────────────────────
  /// Returns a list of coaching [Recommendation]s for the given exercise
  /// index and quality level. Returns an empty list for [QualityLevel.good].
  Future<List<Recommendation>> getRecommendations({
    required int exerciseIndex,
    required QualityLevel quality,
  }) async {
    if (quality == QualityLevel.good) return [];

    final qualityKey = quality == QualityLevel.poor ? 'poor' : 'needs_improvement';

    try {
      final exercises = _config?['exercises'] as Map<String, dynamic>?;
      final exercise  = exercises?['$exerciseIndex'] as Map<String, dynamic>?;
      final recs      = exercise?['recommendations'] as Map<String, dynamic>?;
      final tipList   = recs?[qualityKey] as List<dynamic>?;

      if (tipList != null && tipList.isNotEmpty) {
        return tipList.map((tip) {
          final t = tip as Map<String, dynamic>;
          return Recommendation(
            message:  t['message']  as String? ?? '',
            priority: t['priority'] as String? ?? 'medium',
            category: t['category'] as String? ?? 'movement',
          );
        }).toList();
      }
    } catch (_) {}

    // ── Generic fallback ────────────────────────────────────────────────────
    return [
      if (quality == QualityLevel.poor) ...[
        const Recommendation(
          message: 'Significant form issue detected. Slow down, reset, and restart.',
          priority: 'high',
          category: 'movement',
        ),
        const Recommendation(
          message: 'Focus on completing the full range of motion deliberately.',
          priority: 'high',
          category: 'alignment',
        ),
      ] else ...[
        const Recommendation(
          message: 'Good effort! Fine-tune your control and alignment.',
          priority: 'medium',
          category: 'movement',
        ),
        const Recommendation(
          message: 'Maintain a steady pace throughout the exercise.',
          priority: 'low',
          category: 'pace',
        ),
      ],
    ];
  }
}
