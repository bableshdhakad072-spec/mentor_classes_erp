import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../data/erp_repository.dart';
import '../../models/user_model.dart';

/// Full ranked list for a selected test (top to bottom); NG at end; medals for ranks 1–3.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _classLevel = 8;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _tests = [];
  String? _selectedId;
  List<LeaderboardRow> _board = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tests = await ref.read(erpRepositoryProvider).fetchTestsForClass(_classLevel);
    final selId = tests.isNotEmpty ? tests.first.id : null;
    List<LeaderboardRow> board = [];
    if (selId != null) {
      board = ref.read(erpRepositoryProvider).leaderboardForTest(tests.first);
    }
    setState(() {
      _tests = tests;
      _selectedId = selId;
      _board = board;
      _loading = false;
    });
  }

  void _applyTest(String? id) {
    if (id == null) return;
    final match = _tests.where((d) => d.id == id);
    if (match.isEmpty) return;
    final doc = match.first;
    final board = ref.read(erpRepositoryProvider).leaderboardForTest(doc);
    setState(() {
      _selectedId = id;
      _board = board;
    });
  }

  Widget _rankLeading(LeaderboardRow row) {
    if (row.isNg) {
      return SizedBox(
        width: 36,
        child: Text('NG', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      );
    }
    final r = row.rank;
    if (r == 1) {
      return Icon(Icons.emoji_events, color: Colors.amber.shade700);
    }
    if (r == 2) {
      return Icon(Icons.emoji_events, color: Colors.blueGrey.shade400);
    }
    if (r == 3) {
      return Icon(Icons.emoji_events, color: Colors.brown.shade400);
    }
    return SizedBox(
      width: 36,
      child: Text(
        '#$r',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: MentorGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _classLevel,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    for (var c = StudentClassLevels.min; c <= StudentClassLevels.max; c++)
                      DropdownMenuItem(value: c, child: Text('Class $c')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _classLevel = v);
                    await _load();
                  },
                ),
                const SizedBox(height: 8),
                if (_tests.isNotEmpty)
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Test'),
                    items: _tests
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.data()['testName']} · ${d.data()['dateKey']}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _applyTest,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _board.isEmpty
                  ? Center(child: Text('No marks for this test yet.', style: GoogleFonts.poppins()))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _board.length,
                      itemBuilder: (context, i) {
                        final row = _board[i];
                        final highlight = !row.isNg && row.rank <= 3;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: highlight ? AppTheme.deepBlue.withValues(alpha: 0.35) : Colors.grey.shade200,
                              width: highlight ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: _rankLeading(row),
                            title: Text(
                              'Roll ${row.roll}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: row.isNg
                                ? Text('Not given', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600))
                                : null,
                            trailing: row.isNg
                                ? null
                                : Text(
                                    row.score!.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.deepBlue,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Sorted rank 1 → last · NG listed after scored students',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
