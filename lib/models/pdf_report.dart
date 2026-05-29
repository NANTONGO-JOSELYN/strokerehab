class PDFReport {
  final String id;
  final DateTime generatedDate;
  final String patientName;
  final int totalSessions;
  final int totalReps;
  final double averageQuality;
  final List<String> exercisesCompleted;
  final int daysActive;

  PDFReport({
    required this.id,
    required this.generatedDate,
    required this.patientName,
    required this.totalSessions,
    required this.totalReps,
    required this.averageQuality,
    required this.exercisesCompleted,
    required this.daysActive,
  });

  String generatePDFContent() {
    return '''
Stroke Rehabilitation Progress Report
Generated: ${generatedDate.toString()}

Patient: $patientName
Report ID: $id

SUMMARY
Total Sessions: $totalSessions
Total Reps Completed: $totalReps
Average Quality Score: ${averageQuality.toStringAsFixed(1)}%
Days Active: $daysActive

EXERCISES COMPLETED
${exercisesCompleted.join('\n')}

Recommendations:
1. Continue current exercise routine
2. Focus on form improvement
3. Increase session frequency if possible
4. Consult with clinician for personalized adjustments
''';
  }
}
