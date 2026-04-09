import 'package:cloud_firestore/cloud_firestore.dart';

/// Core subjects for all classes
enum CoreSubject {
  sst('SST'),
  science('Science'),
  maths('Maths'),
  english('English');

  final String displayName;
  const CoreSubject(this.displayName);

  String get id => name;
}

/// Single chapter in a subject
class SyllabusChapter {
  final String id;
  final String title;
  final int? chapterNumber;
  final String? description;
  final bool isCompleted;
  final DateTime? completedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyllabusChapter({
    required this.id,
    required this.title,
    this.chapterNumber,
    this.description,
    this.isCompleted = false,
    this.completedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Percentage complete is calculated based on chapters
  double get completionPercentage => isCompleted ? 100.0 : 0.0;

  factory SyllabusChapter.fromFirestore(Map<String, dynamic> data, String docId) {
    return SyllabusChapter(
      id: docId,
      title: data['title']?.toString() ?? 'Chapter',
      chapterNumber: (data['chapterNumber'] as num?)?.toInt(),
      description: data['description']?.toString(),
      isCompleted: (data['isCompleted'] as bool?) ?? false,
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'chapterNumber': chapterNumber,
        'description': description,
        'isCompleted': isCompleted,
        'completedDate': completedDate,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  SyllabusChapter copyWith({
    String? id,
    String? title,
    int? chapterNumber,
    String? description,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyllabusChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Syllabus for one subject with all chapters
class SubjectSyllabus {
  final String subjectId;
  final String subjectName;
  final int classLevel;
  final List<SyllabusChapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // Teacher email

  SubjectSyllabus({
    required this.subjectId,
    required this.subjectName,
    required this.classLevel,
    required this.chapters,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  int get totalChapters => chapters.length;
  int get completedChapters => chapters.where((c) => c.isCompleted).length;
  double get progressPercentage => totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0;

  factory SubjectSyllabus.fromFirestore(Map<String, dynamic> data, String docId) {
    final chaptersList = (data['chapters'] as List<dynamic>?)
            ?.asMap()
            .entries
            .map((e) => SyllabusChapter.fromFirestore(
                  Map<String, dynamic>.from(e.value as Map),
                  e.key.toString(),
                ))
            .toList() ??
        [];

    return SubjectSyllabus(
      subjectId: data['subjectId']?.toString() ?? docId,
      subjectName: data['subjectName']?.toString() ?? 'Subject',
      classLevel: (data['classLevel'] as num?)?.toInt() ?? 0,
      chapters: chaptersList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'classLevel': classLevel,
        'chapters': chapters.map((c) => c.toFirestore()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'createdBy': createdBy,
      };
}

/// Complete syllabus for a class (all 4 subjects)
class ClassSyllabus {
  final String docId;
  final int classLevel;
  final Map<String, SubjectSyllabus> subjects; // Key: subject name
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassSyllabus({
    required this.docId,
    required this.classLevel,
    required this.subjects,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get progress for all subjects combined
  double get overallProgressPercentage {
    if (subjects.isEmpty) return 0;
    final totalProgress = subjects.values.fold<double>(0, (sum, subject) => sum + subject.progressPercentage);
    return totalProgress / subjects.length;
  }

  /// Get all 4 core subjects - fill missing ones with empty syllabi
  Map<String, SubjectSyllabus> getAllCoreSubjects() {
    final allSubjects = <String, SubjectSyllabus>{};

    for (final subject in CoreSubject.values) {
      if (subjects.containsKey(subject.displayName)) {
        allSubjects[subject.displayName] = subjects[subject.displayName]!;
      } else {
        // Create empty subject if not found
        allSubjects[subject.displayName] = SubjectSyllabus(
          subjectId: subject.id,
          subjectName: subject.displayName,
          classLevel: classLevel,
          chapters: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: '',
        );
      }
    }

    return allSubjects;
  }

  factory ClassSyllabus.fromFirestore(Map<String, dynamic> data, String docId) {
    final subjectsMap = <String, SubjectSyllabus>{};

    if (data['subjects'] is Map) {
      (data['subjects'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          subjectsMap[key] = SubjectSyllabus.fromFirestore(value, key);
        }
      });
    }

    return ClassSyllabus(
      docId: docId,
      classLevel: (data['classLevel'] as num?)?.toInt() ?? 0,
      subjects: subjectsMap,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final subjectsData = <String, dynamic>{};
    subjects.forEach((key, subject) {
      subjectsData[key] = subject.toFirestore();
    });

    return {
      'classLevel': classLevel,
      'subjects': subjectsData,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
