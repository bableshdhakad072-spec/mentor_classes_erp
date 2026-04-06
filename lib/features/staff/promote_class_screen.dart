import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../models/user_model.dart';

/// Admin: promote an entire class to the next level; fees reset placeholder; history kept.
class PromoteClassScreen extends ConsumerStatefulWidget {
  const PromoteClassScreen({super.key});

  @override
  ConsumerState<PromoteClassScreen> createState() => _PromoteClassScreenState();
}

class _PromoteClassScreenState extends ConsumerState<PromoteClassScreen> {
  int _from = 8;
  bool _busy = false;

  Future<void> _confirmAndPromote() async {
    if (_from >= StudentClassLevels.max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class 10 cannot be promoted further.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Promote Class $_from?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'All students in Class $_from move to Class ${_from + 1}. Fee fields reset for the new session. '
          'Attendance and old records are not deleted.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final n = await ref.read(erpRepositoryProvider).promoteClassToNext(_from);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promoted $n student(s) from Class $_from to ${_from + 1}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MentorGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promote to next class',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Increments studentClass (e.g. 8 → 9), resets fees placeholder on each profile, '
                'and keeps historical attendance rows keyed by the old class.',
                style: GoogleFonts.poppins(fontSize: 12, height: 1.4, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          // ignore: deprecated_member_use
          value: _from,
          decoration: const InputDecoration(labelText: 'Promote from class'),
          items: [
            for (var c = StudentClassLevels.min; c < StudentClassLevels.max; c++)
              DropdownMenuItem(value: c, child: Text('Class $c → ${c + 1}')),
          ],
          onChanged: _busy ? null : (v) => setState(() => _from = v ?? 8),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _confirmAndPromote,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Promote to next class', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
