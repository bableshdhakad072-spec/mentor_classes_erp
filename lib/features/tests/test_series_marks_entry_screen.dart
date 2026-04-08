import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../data/erp_repository.dart';
import '../auth/auth_service.dart';

/// Enhanced test series marks entry: upload marks for all subjects in one frame.
/// Subjects: Science, SST, Maths, English
class TestSeriesMarksEntryScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesName;
  final int classLevel;
  final List<String> topics;

  const TestSeriesMarksEntryScreen({
    super.key,
    required this.seriesId,
    required this.seriesName,
    required this.classLevel,
    required this.topics,
  });

  @override
  ConsumerState<TestSeriesMarksEntryScreen> createState() =>
      _TestSeriesMarksEntryScreenState();
}

class _TestSeriesMarksEntryScreenState
    extends ConsumerState<TestSeriesMarksEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subjectTabs;
  List<StudentListItem> _students = [];
  bool _loading = true;
  bool _saving = false;
  DateTime _testDate = DateTime.now();

  // Subjects: Science, SST, Maths, English
  static const List<String> _subjectsWithTopics = [
    'Science',
    'SST',
    'Maths',
    'English',
  ];

  // Mark storage: subject -> (roll -> marks)
  late Map<String, Map<String, TextEditingController>> _marksBySubject;
  // NG storage: subject -> (roll -> isNG)
  late Map<String, Map<String, bool>> _ngBySubject;

  @override
  void initState() {
    super.initState();
    _subjectTabs = TabController(length: _subjectsWithTopics.length, vsync: this);
    _initializeMapsForSubjects();
    _load();
  }

  void _initializeMapsForSubjects() {
    _marksBySubject = {};
    _ngBySubject = {};
    for (final subject in _subjectsWithTopics) {
      _marksBySubject[subject] = {};
      _ngBySubject[subject] = {};
    }
  }

  @override
  void dispose() {
    _subjectTabs.dispose();
    for (final subjectMarks in _marksBySubject.values) {
      for (final controller in subjectMarks.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await ref.read(erpRepositoryProvider).fetchStudentsByClass(widget.classLevel);
      
      // Initialize controllers for each subject and student
      _marksBySubject.clear();
      _ngBySubject.clear();
      
      for (final subject in _subjectsWithTopics) {
        _marksBySubject[subject] = {};
        _ngBySubject[subject] = {};
        for (final s in list) {
          _marksBySubject[subject]![s.roll] = TextEditingController();
          _ngBySubject[subject]![s.roll] = false;
        }
      }

      setState(() {
        _students = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAllSubjects() async {
    final user = ref.read(authProvider);
    if (user == null || !user.isStaff || user.email == null) return;

    // Validate that at least one subject has marks
    bool hasAnyMarks = false;
    for (final subjectMarks in _marksBySubject.values) {
      if (subjectMarks.values
          .any((ctrl) => ctrl.text.trim().isNotEmpty)) {
        hasAnyMarks = true;
        break;
      }
    }

    if (!hasAnyMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter marks for at least one subject'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Save marks for each subject
      for (final subject in _subjectsWithTopics) {
        final marks = <String, double>{};
        final ngList = <String>[];

        for (final s in _students) {
          final isNG = _ngBySubject[subject]?[s.roll] ?? false;
          if (isNG) {
            ngList.add(s.roll);
            continue;
          }

          final text = _marksBySubject[subject]?[s.roll]?.text.trim() ?? '';
          if (text.isEmpty) continue;

          final value = double.tryParse(text);
          if (value != null) {
            marks[s.roll] = value;
          }
        }

        if (marks.isNotEmpty || ngList.isNotEmpty) {
          await ref.read(erpRepositoryProvider).saveTestMarksExtended(
                classLevel: widget.classLevel,
                subject: subject,
                topic: _getTopicForSubject(subject),
                testName: widget.seriesName,
                testKind: 'series',
                seriesId: widget.seriesId,
                date: _testDate,
                maxMarks: 100.0,
                marksByRoll: marks,
                notGivenRolls: ngList,
                savedBy: user.email!,
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All marks saved! Leaderboards updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _getTopicForSubject(String subject) {
    return widget.topics.isNotEmpty ? widget.topics[0] : 'General';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.seriesName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _subjectTabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _subjectsWithTopics
              .map((s) => Tab(text: s, height: 48))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Test info card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Series: ${widget.seriesName}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Class ${widget.classLevel} · ${_students.length} students',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _testDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (p != null) setState(() => _testDate = p);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat.yMMMd().format(_testDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Subject tabs content
          Expanded(
            child: TabBarView(
              controller: _subjectTabs,
              children: _subjectsWithTopics.map((subject) {
                return _SubjectMarksEntry(
                  subject: subject,
                  students: _students,
                  marksBySubject: _marksBySubject,
                  ngBySubject: _ngBySubject,
                );
              }).toList(),
            ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving ? null : _saveAllSubjects,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    _saving ? 'Saving...' : 'Save All Subjects & Generate Leaderboard',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

/// Marks entry UI for a single subject
class _SubjectMarksEntry extends StatelessWidget {
  final String subject;
  final List<StudentListItem> students;
  final Map<String, Map<String, TextEditingController>> marksBySubject;
  final Map<String, Map<String, bool>> ngBySubject;

  const _SubjectMarksEntry({
    required this.subject,
    required this.students,
    required this.marksBySubject,
    required this.ngBySubject,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (context, i) {
        final s = students[i];
        final ng = ngBySubject[subject]?[s.roll] ?? false;
        final marksCtrl = marksBySubject[subject]?[s.roll];

        if (marksCtrl == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: ng ? Colors.red.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Roll ${s.roll}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: marksCtrl,
                    enabled: !ng,
                    decoration: const InputDecoration(
                      labelText: 'Marks',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NG',
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                      StatefulBuilder(
                        builder: (ctx, setState) => Checkbox(
                          value: ng,
                          onChanged: (v) {
                            setState(() {
                              ngBySubject[subject]?[s.roll] = v ?? false;
                              if (ngBySubject[subject]?[s.roll] == true) {
                                marksCtrl.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
