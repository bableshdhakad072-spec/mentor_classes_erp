import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../data/erp_repository.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';

/// Student: today's homework for their class.
class HomeworkStudentScreen extends ConsumerWidget {
  const HomeworkStudentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null || !StudentClassLevels.isValid(user.studentClass)) {
      return Center(
        child: Text(
          'Homework requires your class on file.',
          style: GoogleFonts.poppins(),
        ),
      );
    }

    final c = user.studentClass!;
    final dk = ErpRepository.dateKey(DateTime.now());
    final stream = ref.watch(erpRepositoryProvider).watchHomeworkForClassAndDate(
          classLevel: c,
          dateKeyStr: dk,
        );

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      key: ValueKey('$c-$dk'),
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No homework posted for Class $c today ($dk).',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['description']?.toString() ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By ${d['assignedBy'] ?? 'Teacher'}',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
