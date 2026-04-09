import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../auth/auth_service.dart';

/// Admin-only: Reset all data and manage system safety.
class AdminControlPanelScreen extends ConsumerStatefulWidget {
  const AdminControlPanelScreen({super.key});

  @override
  ConsumerState<AdminControlPanelScreen> createState() => _AdminControlPanelScreenState();
}

class _AdminControlPanelScreenState extends ConsumerState<AdminControlPanelScreen> {
  bool _isResetting = false;

  Future<void> _confirmReset() async {
    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Warning', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text(
          'This will delete ALL student data, fees records, attendance, test marks, and resources. This action CANNOT be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Double confirmation with typing challenge
    if (!mounted) return;
    final secondConfirm = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            'Double Confirmation',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type "DELETE ALL DATA" to confirm:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type to confirm',
                  errorText: null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: controller.text == 'DELETE ALL DATA'
                  ? () => Navigator.pop(context, 'CONFIRMED')
                  : null,
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (secondConfirm != 'CONFIRMED') return;

    // Perform reset
    if (!mounted) return;
    setState(() => _isResetting = true);

    try {
      await ref.read(erpRepositoryProvider).resetAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data has been reset. The app will restart.'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Sign out after reset
        await AuthService.logout();
        
        // Navigate to login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error during reset: $e')),
        );
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // Only admins can access this
    if (user == null || user.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Only administrators can access this panel',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Controls', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // System Information
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.deepBlue),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Admin User', style: GoogleFonts.poppins()),
                    subtitle: Text(user.email ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Role', style: GoogleFonts.poppins()),
                    subtitle: Text('Administrator', style: GoogleFonts.poppins(fontSize: 12, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Danger Zone
          Text(
            '🚨 Danger Zone',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset All Dat',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently delete all student records, fees data, attendance records, test marks, and academic resources. This action cannot be undone.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isResetting ? null : _confirmReset,
                      icon: _isResetting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_forever),
                      label: Text(
                        _isResetting ? 'Resetting...' : 'Reset All Data',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Features
          Text(
            '🛡️ Security',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.deepBlue),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SecurityFeatureItem(
                    icon: Icons.lock,
                    title: 'Firebase Security Rules',
                    description: 'Firestore is protected with strict rules\n- Students cannot modify other records\n- Only staff can mark attendance\n- Fee data is admin-only',
                  ),
                  const Divider(height: 24),
                  _SecurityFeatureItem(
                    icon: Icons.verified_user,
                    title: 'Role-Based Access Control',
                    description: 'Users have specific roles (Admin, Staff, Student)\nEach role has limited permissions by design',
                  ),
                  const Divider(height: 24),
                  _SecurityFeatureItem(
                    icon: Icons.backup,
                    title: 'Data Backup (Automatic)',
                    description: 'Firestore automatically backs up data daily\nRecovery available within 30 days',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SecurityFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppTheme.deepBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
