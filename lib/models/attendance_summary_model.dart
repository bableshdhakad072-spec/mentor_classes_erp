// Attendance Summary & Analytics
import 'package:intl/intl.dart';

/// Comprehensive attendance summary for a student over a period
class AttendanceSummary {
  final String rollNumber;
  final String studentName;
  final int classLevel;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int holidayCount;
  final double attendancePercentage;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> monthlyBreakdown; // 'YYYY-MM' -> present days

  AttendanceSummary({
    required this.rollNumber,
    required this.studentName,
    required this.classLevel,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.holidayCount,
    required this.attendancePercentage,
    required this.startDate,
    required this.endDate,
    required this.monthlyBreakdown,
  });

  /// Get status badge color based on attendance percentage
  String get statusLabel {
    if (attendancePercentage >= 95) return 'Excellent';
    if (attendancePercentage >= 85) return 'Good';
    if (attendancePercentage >= 75) return 'Satisfactory';
    if (attendancePercentage >= 65) return 'Fair';
    return 'Poor';
  }

  /// Get status badge color
  int get statusColor {
    if (attendancePercentage >= 95) return 0xFF4CAF50; // Green
    if (attendancePercentage >= 85) return 0xFF8BC34A; // Light Green
    if (attendancePercentage >= 75) return 0xFFFFC107; // Amber
    if (attendancePercentage >= 65) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Calculate consecutive absent days (if needed for warnings)
  bool isAttendanceLow() => attendancePercentage < 75;

  factory AttendanceSummary.fromMap(Map<String, dynamic> data) {
    return AttendanceSummary(
      rollNumber: data['rollNumber'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      classLevel: data['classLevel'] as int? ?? 0,
      totalWorkingDays: data['totalWorkingDays'] as int? ?? 0,
      presentDays: data['presentDays'] as int? ?? 0,
      absentDays: data['absentDays'] as int? ?? 0,
      holidayCount: data['holidayCount'] as int? ?? 0,
      attendancePercentage: (data['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as dynamic)?.toDate() ?? DateTime.now(),
      monthlyBreakdown: Map<String, int>.from(data['monthlyBreakdown'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'rollNumber': rollNumber,
        'studentName': studentName,
        'classLevel': classLevel,
        'totalWorkingDays': totalWorkingDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'holidayCount': holidayCount,
        'attendancePercentage': attendancePercentage,
        'startDate': startDate,
        'endDate': endDate,
        'monthlyBreakdown': monthlyBreakdown,
      };

  /// Format percentage as string with 1 decimal place
  String get formattedPercentage => '${attendancePercentage.toStringAsFixed(1)}%';

  /// Human-readable date range
  String get dateRange {
    final fmt = DateFormat('MMM d, yyyy');
    return '${fmt.format(startDate)} - ${fmt.format(endDate)}';
  }
}

/// Attendance record for a single day with all students
class AttendanceRecord {
  final String date; // YYYY-MM-DD format
  final int classLevel;
  final bool isHoliday;
  final String? holidayReason;
  final Map<String, bool> records; // rollNumber -> isPresent
  final DateTime recordedAt;

  AttendanceRecord({
    required this.date,
    required this.classLevel,
    required this.isHoliday,
    this.holidayReason,
    required this.records,
    required this.recordedAt,
  });

  int get totalPresent => records.values.where((v) => v).length;
  int get totalAbsent => records.values.where((v) => !v).length;

  factory AttendanceRecord.fromFirestore(Map<String, dynamic> data) {
    return AttendanceRecord(
      date: data['date'] as String? ?? '',
      classLevel: data['classLevel'] as int? ?? 0,
      isHoliday: data['isHoliday'] as bool? ?? false,
      holidayReason: data['holidayReason'] as String?,
      records: Map<String, bool>.from(data['records'] as Map? ?? {}),
      recordedAt: (data['recordedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': date,
        'classLevel': classLevel,
        'isHoliday': isHoliday,
        'holidayReason': holidayReason,
        'records': records,
        'recordedAt': recordedAt,
      };
}
