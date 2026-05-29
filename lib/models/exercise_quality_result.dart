import '../theme/app_theme.dart';

/// Result of one ONNX inference pass on a 10-second IMU window.
///
/// Label mapping (exercise quality terminology):
///   0 → Poor Exercise Quality
///   1 → Good Exercise Quality
///   2 → Needs Improvement
class ExerciseQualityResult {
  /// The predicted quality level (uses app-wide QualityLevel enum).
  final QualityLevel quality;

  /// Model confidence for the winning class (0.0 – 1.0).
  final double confidence;

  /// Per-class probabilities in ONNX output order [POOR=0, GOOD=1, WARNING=2].
  final List<double> probabilities;

  /// Wall-clock time of inference.
  final DateTime timestamp;

  const ExerciseQualityResult({
    required this.quality,
    required this.confidence,
    required this.probabilities,
    required this.timestamp,
  });

  /// Human-readable label for the quality level.
  String get label => AppTheme.qualityLabel(quality);

  /// Emoji indicator for the quality level.
  String get emoji => AppTheme.qualityEmoji(quality);

  /// Whether this result requires corrective feedback.
  bool get requiresFeedback =>
      quality == QualityLevel.needsImprovement || quality == QualityLevel.poor;

  /// Integer encoding used for JSON serialisation.
  int get _intValue {
    switch (quality) {
      case QualityLevel.good:            return 1;
      case QualityLevel.needsImprovement: return 2;
      case QualityLevel.poor:            return 0;
    }
  }

  /// Reconstruct [QualityLevel] from the classifier's raw integer output.
  static QualityLevel _qualityFromInt(int v) {
    switch (v) {
      case 1:  return QualityLevel.good;
      case 2:  return QualityLevel.needsImprovement;
      default: return QualityLevel.poor;
    }
  }

  /// Fallback result when the pipeline hasn't run yet.
  factory ExerciseQualityResult.initial() => ExerciseQualityResult(
    quality: QualityLevel.good,
    confidence: 0,
    probabilities: [0, 0, 0],
    timestamp: DateTime.now(),
  );

  /// Serialize to a flat map for SharedPreferences history storage.
  Map<String, dynamic> toJson() => {
    'quality': _intValue,
    'confidence': confidence,
    'probs': probabilities,
    'ts': timestamp.millisecondsSinceEpoch,
  };

  factory ExerciseQualityResult.fromJson(Map<String, dynamic> j) =>
      ExerciseQualityResult(
        quality: _qualityFromInt(j['quality'] as int? ?? j['label'] as int? ?? 1),
        confidence: (j['confidence'] as num).toDouble(),
        probabilities: (j['probs'] as List).map((e) => (e as num).toDouble()).toList(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
      );

  @override
  String toString() =>
      'ExerciseQualityResult($label, conf=${(confidence * 100).toStringAsFixed(1)}%)';
}
