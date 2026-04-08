import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faculty_model.dart';

/// Repository for Faculty CRUD operations
class FacultyRepository {
  static final FacultyRepository _instance = FacultyRepository._internal();

  factory FacultyRepository() {
    return _instance;
  }

  FacultyRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'faculty';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_collectionName);

  /// Get all faculty members as a stream
  Stream<List<Faculty>> getAllFacultyStream() {
    return _collection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Faculty.fromSnapshot(doc)).toList());
  }

  /// Get all faculty members (one-time fetch)
  Future<List<Faculty>> getAllFaculty() async {
    try {
      final snapshot = await _collection.orderBy('name').get();
      return snapshot.docs.map((doc) => Faculty.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch faculty: $e');
    }
  }

  /// Get faculty member by ID
  Future<Faculty?> getFacultyById(String facultyId) async {
    try {
      final doc = await _collection.doc(facultyId).get();
      if (!doc.exists) return null;
      return Faculty.fromSnapshot(doc);
    } catch (e) {
      throw Exception('Failed to fetch faculty: $e');
    }
  }

  /// Get faculty stream by ID (for real-time updates)
  Stream<Faculty?> getFacultyByIdStream(String facultyId) {
    return _collection.doc(facultyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Faculty.fromSnapshot(doc);
    });
  }

  /// Get faculty members by subject
  Future<List<Faculty>> getFacultyBySubject(String subject) async {
    try {
      final snapshot =
          await _collection.where('subject', isEqualTo: subject).get();
      return snapshot.docs.map((doc) => Faculty.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch faculty by subject: $e');
    }
  }

  /// Get faculty members by subject (stream)
  Stream<List<Faculty>> getFacultyBySubjectStream(String subject) {
    return _collection
        .where('subject', isEqualTo: subject)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Faculty.fromSnapshot(doc)).toList());
  }

  /// Add a new faculty member
  Future<String> addFaculty(Faculty faculty) async {
    try {
      final docRef = await _collection.add(faculty.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add faculty: $e');
    }
  }

  /// Update an existing faculty member
  Future<void> updateFaculty(String facultyId, Faculty faculty) async {
    try {
      await _collection.doc(facultyId).update({
        ...faculty.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update faculty: $e');
    }
  }

  /// Partial update of faculty member (only specified fields)
  Future<void> updateFacultyPartial(
      String facultyId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _collection.doc(facultyId).update(updates);
    } catch (e) {
      throw Exception('Failed to update faculty: $e');
    }
  }

  /// Delete a faculty member
  Future<void> deleteFaculty(String facultyId) async {
    try {
      await _collection.doc(facultyId).delete();
    } catch (e) {
      throw Exception('Failed to delete faculty: $e');
    }
  }

  /// Delete multiple faculty members
  Future<void> deleteMultipleFaculty(List<String> facultyIds) async {
    try {
      final batch = _db.batch();
      for (final id in facultyIds) {
        batch.delete(_collection.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete faculty members: $e');
    }
  }

  /// Search faculty by name
  Future<List<Faculty>> searchFacultyByName(String query) async {
    try {
      if (query.isEmpty) return getAllFaculty();

      // Firestore doesn't support LIKE queries, so we fetch all and filter
      final allFaculty = await getAllFaculty();
      return allFaculty
          .where((faculty) =>
              faculty.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search faculty: $e');
    }
  }

  /// Get count of faculty members
  Future<int> getFacultyCount() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get faculty count: $e');
    }
  }

  /// Check if faculty exists by email
  Future<bool> facultyExistsByEmail(String email) async {
    try {
      final snapshot = await _collection.where('email', isEqualTo: email).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check faculty existence: $e');
    }
  }

  /// Get faculty by email
  Future<Faculty?> getFacultyByEmail(String email) async {
    try {
      final snapshot = await _collection.where('email', isEqualTo: email).get();
      if (snapshot.docs.isEmpty) return null;
      return Faculty.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch faculty by email: $e');
    }
  }

  /// Batch import faculty from list
  Future<void> batchImportFaculty(List<Faculty> facultyList) async {
    try {
      const batchSize = 500; // Firestore batch write limit is 500
      for (var i = 0; i < facultyList.length; i += batchSize) {
        final batch = _db.batch();
        final end = (i + batchSize < facultyList.length)
            ? i + batchSize
            : facultyList.length;

        for (var j = i; j < end; j++) {
          final docRef = _collection.doc();
          batch.set(docRef, facultyList[j].toMap());
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to batch import faculty: $e');
    }
  }
}
