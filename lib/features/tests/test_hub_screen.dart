import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';
import 'mark_entry_config.dart';
import 'marks_entry_screen.dart';

/// Create a single test or a test series, then open marks entry.
class TestHubScreen extends ConsumerStatefulWidget {
  const TestHubScreen({super.key});

  @override
  ConsumerState<TestHubScreen> createState() => _TestHubScreenState();
}

class _TestHubScreenState extends ConsumerState<TestHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  int _classSingle = 8;
  final _subSingle = TextEditingController(text: 'Mathematics');
  final _topicSingle = TextEditingController(text: 'Algebra');
  final _nameSingle = TextEditingController(text: 'Unit Test');
  final _maxSingle = TextEditingController(text: '50');
  DateTime _dateSingle = DateTime.now();

  int _classSeries = 8;
  final _seriesName = TextEditingController(text: 'PT Series 1');
  final _subSeries = TextEditingController(text: 'Science');
  final _topicsSeries = TextEditingController(text: 'Physics,Chemistry,Biology');
  String? _createdSeriesId;
  List<String> _seriesTopics = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _subSingle.dispose();
    _topicSingle.dispose();
    _nameSingle.dispose();
    _maxSingle.dispose();
    _seriesName.dispose();
    _subSeries.dispose();
    _topicsSeries.dispose();
    super.dispose();
  }

  void _openMarks(MarkEntryConfig cfg) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => MarksEntryScreen(config: cfg)),
    );
  }

  Future<void> _createSeries() async {
    final user = ref.read(authProvider);
    if (user == null || !user.isStaff || user.email == null) return;

    final topics = _topicsSeries.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one topic (comma-separated).')),
      );
      return;
    }

    try {
      final id = await ref.read(erpRepositoryProvider).createTestSeries(
            name: _seriesName.text.trim().isEmpty ? 'Series' : _seriesName.text.trim(),
            classLevel: _classSeries,
            subject: _subSeries.text.trim().isEmpty ? 'Subject' : _subSeries.text.trim(),
            topics: topics,
            savedBy: user.email!,
          );
      setState(() {
        _createdSeriesId = id;
        _seriesTopics = topics;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Series created. Tap a topic to enter marks.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final user = ref.watch(authProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: AppTheme.deepBlue,
          indicatorColor: AppTheme.deepBlue,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Single test'),
            Tab(text: 'Test series'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  MentorGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('1. Meta', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: _classSingle,
                          decoration: const InputDecoration(labelText: 'Class'),
                          items: [
                            for (var c = StudentClassLevels.min; c <= StudentClassLevels.max; c++)
                              DropdownMenuItem(value: c, child: Text('Class $c')),
                          ],
                          onChanged: (v) => setState(() => _classSingle = v ?? 8),
                        ),
                        TextField(controller: _subSingle, decoration: const InputDecoration(labelText: 'Subject')),
                        TextField(controller: _topicSingle, decoration: const InputDecoration(labelText: 'Topic')),
                        TextField(controller: _nameSingle, decoration: const InputDecoration(labelText: 'Test name')),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _maxSingle,
                                decoration: const InputDecoration(labelText: 'Max marks'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: _dateSingle,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2035),
                                  );
                                  if (p != null) setState(() => _dateSingle = p);
                                },
                                child: Text(df.format(_dateSingle), style: GoogleFonts.poppins(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: user == null || !user.isStaff
                              ? null
                              : () {
                                  final max = double.tryParse(_maxSingle.text.trim());
                                  if (max == null || max <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Enter valid max marks')),
                                    );
                                    return;
                                  }
                                  _openMarks(
                                    MarkEntryConfig(
                                      classLevel: _classSingle,
                                      subject: _subSingle.text.trim(),
                                      topic: _topicSingle.text.trim(),
                                      testName: _nameSingle.text.trim().isEmpty ? 'Test' : _nameSingle.text.trim(),
                                      maxMarks: max,
                                      date: _dateSingle,
                                      testKind: 'single',
                                    ),
                                  );
                                },
                          child: Text('2. Enter marks', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  MentorGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create series', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue)),
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: _classSeries,
                          decoration: const InputDecoration(labelText: 'Class'),
                          items: [
                            for (var c = StudentClassLevels.min; c <= StudentClassLevels.max; c++)
                              DropdownMenuItem(value: c, child: Text('Class $c')),
                          ],
                          onChanged: (v) => setState(() => _classSeries = v ?? 8),
                        ),
                        TextField(controller: _seriesName, decoration: const InputDecoration(labelText: 'Series name')),
                        TextField(controller: _subSeries, decoration: const InputDecoration(labelText: 'Subject')),
                        TextField(
                          controller: _topicsSeries,
                          decoration: const InputDecoration(
                            labelText: 'Topics (comma-separated)',
                            hintText: 'Topic A, Topic B, Topic C',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _createSeries,
                          child: Text('Save series', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  if (_createdSeriesId != null && _seriesTopics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Enter marks per topic', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ..._seriesTopics.map(
                      (t) => Card(
                        child: ListTile(
                          title: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final max = double.tryParse(_maxSingle.text.trim()) ?? 50;
                            _openMarks(
                              MarkEntryConfig(
                                classLevel: _classSeries,
                                subject: _subSeries.text.trim(),
                                topic: t,
                                testName: '${_seriesName.text.trim()} · $t',
                                maxMarks: max,
                                date: DateTime.now(),
                                testKind: 'series',
                                seriesId: _createdSeriesId,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
