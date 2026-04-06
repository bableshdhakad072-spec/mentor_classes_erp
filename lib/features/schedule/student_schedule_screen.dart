import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../data/erp_repository.dart';

/// Student/Parent: read-only view of today's classes and what to bring.
class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.read(erpRepositoryProvider).watchWeeklySchedule(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data?.data();
        final days = data?['days'];
        if (days is! Map<String, dynamic>) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No schedule published yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final key = ErpRepository.weekdayKeyFromDate(now);
        final dayLabel = key[0].toUpperCase() + key.substring(1);
        final slots = days[key];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MentorGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My schedule · $dayLabel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue, fontSize: 16),
                  ),
                  Text(
                    'Read-only · Updates sync from the institute in real time.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (slots is! List || slots.isEmpty)
              Text(
                'Nothing scheduled for today.',
                style: GoogleFonts.poppins(),
              )
            else
              ...slots.asMap().entries.map((e) {
                final i = e.key;
                final raw = e.value;
                if (raw is! Map) return const SizedBox.shrink();
                final m = Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)));
                final subject = m['subject']?.toString() ?? '—';
                final start = m['start']?.toString() ?? '';
                final end = m['end']?.toString() ?? '';
                final bring = m['bring']?.toString() ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.deepBlue.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period ${i + 1} · $subject',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (start.isNotEmpty || end.isNotEmpty)
                          Text(
                            '$start – $end',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                          ),
                        if (bring.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Bring',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.deepBlue, fontWeight: FontWeight.w600),
                          ),
                          Text(bring, style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
