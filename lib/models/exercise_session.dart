class ExerciseSession {
  final String id;
  final String exerciseId;
  final DateTime startTime;
  final DateTime? endTime;
  final int completedReps;
  final int targetReps;
  final String qualityScore; // "Good", "Fair", "Poor"
  final String notes;

  ExerciseSession({
    required this.id,
    required this.exerciseId,
    required this.startTime,
    this.endTime,
    required this.completedReps,
    required this.targetReps,
    required this.qualityScore,
    required this.notes,
  });

  int get durationSeconds {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }

  factory ExerciseSession.fromJson(Map<String, dynamic> json) {
    return ExerciseSession(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime:
          json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      completedReps: json['completedReps'] as int,
      targetReps: json['targetReps'] as int,
      qualityScore: json['qualityScore'] as String,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedReps': completedReps,
      'targetReps': targetReps,
      'qualityScore': qualityScore,
      'notes': notes,
    };
  }
}
