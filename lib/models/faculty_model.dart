import 'package:cloud_firestore/cloud_firestore.dart';

/// Faculty/Teacher model for managing staff profiles
class Faculty {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String? qualifications;
  final String? experience;
  final String? imageUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    this.qualifications,
    this.experience,
    this.imageUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert Faculty instance to Firestore-compatible map
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'subject': subject,
    'qualifications': qualifications,
    'experience': experience,
    'image_url': imageUrl,
    'bio': bio,
    'createdAt': createdAt ?? DateTime.now(),
    'updatedAt': updatedAt ?? DateTime.now(),
  };

  /// Create Faculty instance from Firestore document
  factory Faculty.fromMap(String id, Map<String, dynamic> map) => Faculty(
    id: id,
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    subject: map['subject'] ?? '',
    qualifications: map['qualifications'],
    experience: map['experience'],
    imageUrl: map['image_url'],
    bio: map['bio'],
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );

  /// Create Faculty from DocumentSnapshot
  factory Faculty.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Faculty.fromMap(doc.id, data);
  }

  /// Copy with updated values
  Faculty copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? subject,
    String? qualifications,
    String? experience,
    String? imageUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Faculty(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    subject: subject ?? this.subject,
    qualifications: qualifications ?? this.qualifications,
    experience: experience ?? this.experience,
    imageUrl: imageUrl ?? this.imageUrl,
    bio: bio ?? this.bio,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => 'Faculty(id: $id, name: $name, subject: $subject)';
}
