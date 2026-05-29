class PainFatigueAssessment {
  final String id;
  final DateTime timestamp;
  final int painLevel; // 0-10
  final int fatigueLevel; // 0-10
  final String painLocation;
  final bool shouldContinue; // Can patient continue with exercise?

  PainFatigueAssessment({
    required this.id,
    required this.timestamp,
    required this.painLevel,
    required this.fatigueLevel,
    required this.painLocation,
    required this.shouldContinue,
  });

  factory PainFatigueAssessment.fromJson(Map<String, dynamic> json) {
    return PainFatigueAssessment(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      painLevel: json['painLevel'] as int,
      fatigueLevel: json['fatigueLevel'] as int,
      painLocation: json['painLocation'] as String,
      shouldContinue: json['shouldContinue'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'painLevel': painLevel,
      'fatigueLevel': fatigueLevel,
      'painLocation': painLocation,
      'shouldContinue': shouldContinue,
    };
  }
}
