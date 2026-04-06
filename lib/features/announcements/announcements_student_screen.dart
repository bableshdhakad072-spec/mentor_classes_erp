import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';

/// Full list of notices for the signed-in student.
class AnnouncementsStudentScreen extends ConsumerWidget {
  const AnnouncementsStudentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final repo = ref.watch(erpRepositoryProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchAnnouncementsStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.data!.docs;
        if (user != null && user.role == UserRole.student && StudentClassLevels.isValid(user.studentClass)) {
          final c = user.studentClass!;
          docs = docs.where((d) {
            final cl = d.data()['classLevel'];
            if (cl == null) return true;
            return cl == c;
          }).toList();
        }
        if (docs.isEmpty) {
          return Center(child: Text('No notices yet.', style: GoogleFonts.poppins()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Icon(
                  d['type'] == 'holiday' ? Icons.beach_access : Icons.notifications_active_outlined,
                  color: AppTheme.deepBlue,
                ),
                title: Text(d['title']?.toString() ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(d['body']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
              ),
            );
          },
        );
      },
    );
  }
}
