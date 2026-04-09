// Fees Analytics & Financial Dashboard

class FeesAnalytics {
  final double totalCollected;
  final double totalPending;
  final int totalStudents;
  final int paidStudentsCount;
  final List<ClassFeesBreakdown> classwiseBreakdown;
  final DateTime lastUpdated;

  FeesAnalytics({
    required this.totalCollected,
    required this.totalPending,
    required this.totalStudents,
    required this.paidStudentsCount,
    required this.classwiseBreakdown,
    required this.lastUpdated,
  });

  double get totalExpected => totalCollected + totalPending;
  double get collectionPercentage => totalExpected > 0 ? (totalCollected / totalExpected) * 100 : 0;
  double get pendingPercentage => 100 - collectionPercentage;

  factory FeesAnalytics.fromFirestore(Map<String, dynamic> data) {
    return FeesAnalytics(
      totalCollected: (data['totalCollected'] as num?)?.toDouble() ?? 0,
      totalPending: (data['totalPending'] as num?)?.toDouble() ?? 0,
      totalStudents: (data['totalStudents'] as num?)?.toInt() ?? 0,
      paidStudentsCount: (data['paidStudentsCount'] as num?)?.toInt() ?? 0,
      classwiseBreakdown: (data['classwiseBreakdown'] as List<dynamic>?)
              ?.map((e) => ClassFeesBreakdown.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: (data['lastUpdated'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'totalStudents': totalStudents,
        'paidStudentsCount': paidStudentsCount,
        'classwiseBreakdown': classwiseBreakdown.map((e) => e.toMap()).toList(),
        'lastUpdated': lastUpdated,
      };
}

class ClassFeesBreakdown {
  final int classLevel;
  final int totalStudents;
  final int paidStudents;
  final int pendingStudents;
  final double totalCollected;
  final double totalPending;
  final double averageFeesPerStudent;
  final List<StudentFeesStatus> pendingStudentsList;

  ClassFeesBreakdown({
    required this.classLevel,
    required this.totalStudents,
    required this.paidStudents,
    required this.pendingStudents,
    required this.totalCollected,
    required this.totalPending,
    required this.averageFeesPerStudent,
    required this.pendingStudentsList,
  });

  double get totalExpected => totalCollected + totalPending;
  double get collectionPercentage => totalExpected > 0 ? (totalCollected / totalExpected) * 100 : 0;
  String get statusLabel {
    if (collectionPercentage >= 90) return '✅ Complete';
    if (collectionPercentage >= 70) return '⚠️ Mostly Paid';
    if (collectionPercentage > 0) return '🔴 Partial';
    return '❌ Pending';
  }

  factory ClassFeesBreakdown.fromMap(Map<String, dynamic> data) {
    return ClassFeesBreakdown(
      classLevel: (data['classLevel'] as num?)?.toInt() ?? 0,
      totalStudents: (data['totalStudents'] as num?)?.toInt() ?? 0,
      paidStudents: (data['paidStudents'] as num?)?.toInt() ?? 0,
      pendingStudents: (data['pendingStudents'] as num?)?.toInt() ?? 0,
      totalCollected: (data['totalCollected'] as num?)?.toDouble() ?? 0,
      totalPending: (data['totalPending'] as num?)?.toDouble() ?? 0,
      averageFeesPerStudent: (data['averageFeesPerStudent'] as num?)?.toDouble() ?? 0,
      pendingStudentsList: (data['pendingStudentsList'] as List<dynamic>?)
              ?.map((e) => StudentFeesStatus.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'classLevel': classLevel,
        'totalStudents': totalStudents,
        'paidStudents': paidStudents,
        'pendingStudents': pendingStudents,
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'averageFeesPerStudent': averageFeesPerStudent,
        'pendingStudentsList': pendingStudentsList.map((e) => e.toMap()).toList(),
      };
}

class StudentFeesStatus {
  final String studentDocId;
  final String roll;
  final String name;
  final double totalFees;
  final double paidFees;
  final double duesFees;
  final DateTime? lastPaidDate;
  final String phoneNumberParent;

  StudentFeesStatus({
    required this.studentDocId,
    required this.roll,
    required this.name,
    required this.totalFees,
    required this.paidFees,
    required this.duesFees,
    this.lastPaidDate,
    required this.phoneNumberParent,
  });

  double get duesPercentage => totalFees > 0 ? (duesFees / totalFees) * 100 : 0;
  String get statusLabel {
    if (duesFees == 0) return '✅ Paid';
    if (paidFees > 0) return '⚠️ Partial';
    return '❌ Pending';
  }

  factory StudentFeesStatus.fromMap(Map<String, dynamic> data) {
    return StudentFeesStatus(
      studentDocId: data['studentDocId']?.toString() ?? '',
      roll: data['roll']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      totalFees: (data['totalFees'] as num?)?.toDouble() ?? 0,
      paidFees: (data['paidFees'] as num?)?.toDouble() ?? 0,
      duesFees: (data['duesFees'] as num?)?.toDouble() ?? 0,
      lastPaidDate: (data['lastPaidDate'] as dynamic)?.toDate(),
      phoneNumberParent: data['phoneNumberParent']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'studentDocId': studentDocId,
        'roll': roll,
        'name': name,
        'totalFees': totalFees,
        'paidFees': paidFees,
        'duesFees': duesFees,
        'lastPaidDate': lastPaidDate,
        'phoneNumberParent': phoneNumberParent,
      };
}
