import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../data/ncert_topics_placeholder.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';

/// Student home: welcome, NCERT placeholders, latest notices.
class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null || user.role != UserRole.student) return const SizedBox.shrink();

    final hasClass = StudentClassLevels.isValid(user.studentClass);
    final classLevel = hasClass ? user.studentClass! : StudentClassLevels.min;
    final welcome = hasClass ? 'Welcome to Class ${user.studentClass}' : 'Welcome, ${user.displayName}';
    final sections = NcertTopicsPlaceholder.topicsForClass(classLevel);
    final repo = ref.watch(erpRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.deepBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  welcome,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.rollNumber != null ? 'Roll ${user.rollNumber}' : '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Latest notices',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.watchAnnouncementsStream(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Text(
                  'No announcements yet.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                );
              }
              final docs = snap.data!.docs.where((d) {
                final c = d.data()['classLevel'];
                if (c == null) return true;
                if (!hasClass) return false;
                return c == user.studentClass;
              }).take(4);
              final list = docs.toList();
              if (list.isEmpty) {
                return Text(
                  'No class-specific notices.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                );
              }
              return Column(
                children: list.map((d) {
                  final data = d.data();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(
                        data['type'] == 'holiday' ? Icons.beach_access : Icons.campaign_outlined,
                        color: AppTheme.deepBlue,
                      ),
                      title: Text(
                        data['title']?.toString() ?? '',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        data['body']?.toString() ?? '',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'NCERT topics (placeholders)',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map((s) => _TopicCard(section: s)),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.section});

  final NcertTopicSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surface,
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
              section.subject,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepBlue,
              ),
            ),
            const SizedBox(height: 8),
            ...section.topics.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· ', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.deepBlue, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(t, style: GoogleFonts.poppins(fontSize: 13, height: 1.35))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
