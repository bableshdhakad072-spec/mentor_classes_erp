import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Meet Our Faculty Screen - Display and manage faculty/teachers
class MeetOurFacultyScreen extends ConsumerStatefulWidget {
  const MeetOurFacultyScreen({super.key});

  @override
  ConsumerState<MeetOurFacultyScreen> createState() =>
      _MeetOurFacultyScreenState();
}

class _MeetOurFacultyScreenState extends ConsumerState<MeetOurFacultyScreen> {
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    // Check if user is admin by checking shared preferences or auth state
    // For now, using a simple flag that can be toggled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meet Our Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
        actions: [
          Tooltip(
            message: 'Admin Mode',
            child: IconButton(
              icon: Icon(_isAdminMode ? Icons.lock_open : Icons.lock),
              onPressed: () =>
                  setState(() => _isAdminMode = !_isAdminMode),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faculty')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final faculty = snapshot.data!.docs;

          if (faculty.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No faculty members added yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_isAdminMode) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddFacultyDialog(context),
                      child: const Text('Add Faculty Member'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faculty.length + (_isAdminMode ? 1 : 0),
            itemBuilder: (context, index) {
              // Add button at the bottom in admin mode
              if (_isAdminMode && index == faculty.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddFacultyDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Faculty Member'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                );
              }

              final member = faculty[index];
              final data = member.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Column(
                  children: [
                    // Course Image/Avatar
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: data['image_url'] != null
                          ? Image.network(
                              data['image_url'],
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person,
                              size: 80,
                              color: AppTheme.deepBlue.withValues(alpha: 0.3),
                            ),
                    ),
                    // Faculty Info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['designation'] ?? 'Faculty',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.deepBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (data['subject'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.book, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Subject: ${data['subject']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (data['email'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['email'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (data['experience'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.school, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${data['experience']} years experience',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Admin Actions
                    if (_isAdminMode)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showEditFacultyDialog(
                                context,
                                member.id,
                                data,
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteFaculty(member.id),
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFacultyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final designationController = TextEditingController();
    final subjectController = TextEditingController();
    final emailController = TextEditingController();
    final experienceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add Faculty Member',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Senior Teacher, Lab Assistant',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Mathematics',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('faculty').add({
                'name': nameController.text,
                'designation': designationController.text,
                'subject': subjectController.text,
                'email': emailController.text,
                'experience': int.tryParse(experienceController.text) ?? 0,
                'created_at': FieldValue.serverTimestamp(),
              }).then((_) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Faculty member added successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFacultyDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(text: data['name']);
    final designationController =
        TextEditingController(text: data['designation']);
    final subjectController = TextEditingController(text: data['subject']);
    final emailController = TextEditingController(text: data['email']);
    final experienceController =
        TextEditingController(text: '${data['experience'] ?? 0}');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit Faculty Member',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('faculty')
                  .doc(docId)
                  .update({
                'name': nameController.text,
                'designation': designationController.text,
                'subject': subjectController.text,
                'email': emailController.text,
                'experience': int.tryParse(experienceController.text) ?? 0,
              }).then((_) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Faculty member updated successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteFaculty(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Faculty Member?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('faculty')
                  .doc(docId)
                  .delete()
                  .then((_) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Faculty member deleted successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
