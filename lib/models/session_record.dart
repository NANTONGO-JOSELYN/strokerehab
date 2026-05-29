import 'dart:convert';
import 'package:stroke_rehab_app/theme/app_theme.dart';

import 'exercise_quality_result.dart';

/// One completed rehabilitation session stored in SharedPreferences.
class SessionRecord {
  final String id;         // timestamp-based unique ID
  final int exerciseIndex; // 0–5, indexes into _exerciseNames below
  final DateTime startTime;
  final DateTime endTime;
  final List<ExerciseQualityResult> results;

  // FIX: Removed `const` from the constructor — List<ExerciseQualityResult>
  // is not a compile-time constant type, so a const constructor is illegal.
  SessionRecord({
    required this.id,
    required this.exerciseIndex,
    required this.startTime,
    required this.endTime,
    required this.results,
  });

  Duration get duration => endTime.difference(startTime);

  // These three getters use r.label (QualityClass), consistent with how
  // _runInference() in rehab_session_provider.dart now writes the field.
  int get goodCount =>
      results.where((r) => r.label == QualityLevel.good).length;

  int get warningCount =>
      results.where((r) => r.label == QualityLevel.needsImprovement).length;

  int get poorCount =>
      results.where((r) => r.label == QualityLevel.poor).length;

  /// Average confidence across all results.
  double get avgConfidence {
    if (results.isEmpty) return 0;
    return results.map((r) => r.confidence).reduce((a, b) => a + b) /
        results.length;
  }

  /// Dominant quality label by count.
  QualityLevel get dominantQuality {
    if (goodCount >= warningCount && goodCount >= poorCount) {
      return QualityLevel.good;
    }
    if (warningCount >= poorCount) return QualityLevel.needsImprovement;
    return QualityLevel.poor;
  }

  /// Overall quality score 0–100 (weighted: good=100, warning=50, poor=0).
  double get qualityScore {
    if (results.isEmpty) return 0;
    return (goodCount * 100 + warningCount * 50) / results.length;
  }

  // FIX: Synced to match kExerciseNames in rehab_session_provider.dart.
  // The old list had 5 stale entries; the provider defines 6 exercises.
  // A mismatch caused exerciseName to return 'Unknown Exercise' for index 5
  // (Ankle Dorsiflexion) and stored wrong names in history records.
  static const List<String> _exerciseNames = [
    'Shoulder Flexion',
    'Elbow Extension',
    'Wrist Rotation',
    'Hip Abduction',
    'Knee Extension',
    'Ankle Dorsiflexion',
  ];

  String get exerciseName =>
      exerciseIndex < _exerciseNames.length
          ? _exerciseNames[exerciseIndex]
          : 'Unknown Exercise';

  // ── Serialization ─────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseIndex': exerciseIndex,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        id: j['id'] as String,
        exerciseIndex: j['exerciseIndex'] as int,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(j['startTime'] as int),
        endTime:
            DateTime.fromMillisecondsSinceEpoch(j['endTime'] as int),
        results: (j['results'] as List)
            .map((e) => ExerciseQualityResult.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory SessionRecord.fromJsonString(String s) =>
      SessionRecord.fromJson(
          Map<String, dynamic>.from(jsonDecode(s) as Map));

  @override
  String toString() =>
      'SessionRecord($exerciseName, ${results.length} results, '
      'score=${qualityScore.toStringAsFixed(0)})';
}