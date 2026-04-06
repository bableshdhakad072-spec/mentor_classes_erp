import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_excel_parser.dart';

class StudentUploadRepository {
  StudentUploadRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String documentIdForRoll(String rollNo) {
    var s = rollNo.trim();
    if (s.isEmpty) {
      return 'student_${DateTime.now().microsecondsSinceEpoch}';
    }
    s = s.replaceAll(RegExp(r'[/\\\s]+'), '_');
    if (s.length > 700) s = s.substring(0, 700);
    return s;
  }

  /// Writes [rows] to `students` with fields aligned to login + Excel upload.
  Future<int> uploadRows(List<ParsedStudentRow> rows) async {
    if (rows.isEmpty) return 0;

    const chunk = 450;
    var written = 0;
    for (var i = 0; i < rows.length; i += chunk) {
      final batch = _db.batch();
      final part = rows.skip(i).take(chunk);
      for (final row in part) {
        final ref = _db.collection('students').doc(documentIdForRoll(row.rollNo));
        batch.set(
          ref,
          {
            'name': row.name,
            'rollNumber': row.rollNo,
            'Password': row.password,
            'studentClass': row.classLevel,
            if (row.mobileNumber.isNotEmpty) 'mobileNumber': row.mobileNumber,
            if (row.emergencyContact.isNotEmpty) 'emergencyContact': row.emergencyContact,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      written += part.length;
    }
    return written;
  }
}
