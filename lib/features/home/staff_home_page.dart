import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';
import '../staff/bulk_upload_screen.dart';
import '../staff/promote_class_screen.dart';
import 'widgets/staff_class_performance_widget.dart';

/// Staff dashboard body (embedded in [MainShellScreen]).
class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null || !user.isStaff) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hello, ${user.displayName}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${user.role.label} · Classes ${StudentClassLevels.min}–${StudentClassLevels.max}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Open the menu for attendance, tests hub, weekly schedule, homework, and notices.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          if (user.role == UserRole.admin) ...[
            _HomeCard(
              icon: Icons.groups_2_outlined,
              title: 'Bulk upload students',
              subtitle: 'Excel → Firestore (incl. mobile & emergency contact).',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const BulkUploadScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _HomeCard(
              icon: Icons.trending_up,
              title: 'Promote to next class',
              subtitle: 'Move an entire class up one level; fees reset for new session.',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const PromoteClassScreen()),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Class Performance Analytics
          Text(
            'Class Performance',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 12),
          StaffClassPerformanceWidget(classLevel: 11),
          const SizedBox(height: 24),
          _HomeCard(
            icon: Icons.menu_open,
            title: 'Navigation drawer',
            subtitle: 'Attendance, academic hub, tests, leaderboard, schedule, homework, notices.',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MentorGlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.deepBlue.withValues(alpha: 0.12),
          foregroundColor: AppTheme.deepBlue,
          child: Icon(icon),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, height: 1.35)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
