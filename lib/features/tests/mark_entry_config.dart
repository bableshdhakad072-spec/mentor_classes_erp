class MarkEntryConfig {
  const MarkEntryConfig({
    required this.classLevel,
    required this.subject,
    required this.topic,
    required this.testName,
    required this.maxMarks,
    required this.date,
    required this.testKind,
    this.seriesId,
  });

  final int classLevel;
  final String subject;
  final String topic;
  final String testName;
  final double maxMarks;
  final DateTime date;
  final String testKind;
  final String? seriesId;
}
