import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../data/erp_repository.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';

/// Student: charts, subject-wise averages, and overall series rank.
class StudentPerformanceScreen extends ConsumerStatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  ConsumerState<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends ConsumerState<StudentPerformanceScreen> {
  bool _bar = false;

  Map<String, double> _subjectAverages(List<(String, String, double, double)> data) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final t in data) {
      final sub = t.$2;
      final pct = t.$4 == 0 ? 0.0 : (100 * t.$3 / t.$4);
      sums[sub] = (sums[sub] ?? 0) + pct;
      counts[sub] = (counts[sub] ?? 0) + 1;
    }
    final out = <String, double>{};
    sums.forEach((k, v) {
      final c = counts[k] ?? 1;
      out[k] = v / c;
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null || user.rollNumber == null || !StudentClassLevels.isValid(user.studentClass)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Performance charts need your class and roll from Firestore.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    final roll = user.rollNumber!;
    final classLevel = user.studentClass!;

    return FutureBuilder<List<(String, String, double, double)>>(
      future: ref.read(erpRepositoryProvider).marksHistoryForStudent(
            classLevel: classLevel,
            roll: roll,
          ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No test marks uploaded for your class yet.',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        final spots = <FlSpot>[];
        for (var i = 0; i < data.length; i++) {
          final pct = data[i].$4 == 0 ? 0.0 : (100 * data[i].$3 / data[i].$4);
          spots.add(FlSpot(i.toDouble(), pct));
        }

        final bySubject = _subjectAverages(data);
        final subjectEntries = bySubject.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My scores (% of max)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Line')),
                      ButtonSegment(value: true, label: Text('Bar')),
                    ],
                    selected: {_bar},
                    onSelectionChanged: (s) => setState(() => _bar = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: _bar
                        ? BarChart(
                            BarChartData(
                              maxY: 100,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= data.length) return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'T${i + 1}',
                                          style: GoogleFonts.poppins(fontSize: 9),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    getTitlesWidget: (v, m) => Text(
                                      '${v.toInt()}',
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (var i = 0; i < data.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: data[i].$4 == 0 ? 0 : (100 * data[i].$3 / data[i].$4),
                                        color: AppTheme.deepBlue,
                                        width: 14,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 100,
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= data.length) return const SizedBox();
                                      return Text('${i + 1}', style: GoogleFonts.poppins(fontSize: 10));
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (v, m) => Text(
                                      '${v.toInt()}',
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: AppTheme.deepBlue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.deepBlue.withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MentorGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject-wise performance',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue),
                    ),
                    const SizedBox(height: 8),
                    ...subjectEntries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key, style: GoogleFonts.poppins(fontSize: 13))),
                            Text(
                              '${e.value.toStringAsFixed(1)}% avg',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  future: ref.read(erpRepositoryProvider).fetchSeriesForClass(classLevel),
                  builder: (context, seriesSnap) {
                    if (!seriesSnap.hasData || seriesSnap.data!.isEmpty) {
                      return ListView(
                        children: [
                          Text(
                            'No test series for your class — overall series rank appears when teachers create a series.',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Text('Tests (detail)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ...data.map(
                            (t) => ListTile(
                              dense: true,
                              title: Text(t.$1, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                '${t.$2} · ${t.$3.toStringAsFixed(1)} / ${t.$4.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return _SeriesRankBlock(
                      repo: ref.read(erpRepositoryProvider),
                      classLevel: classLevel,
                      roll: roll,
                      seriesDocs: seriesSnap.data!,
                      testDetailTiles: data
                          .map(
                            (t) => ListTile(
                              dense: true,
                              title: Text(t.$1, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                '${t.$2} · ${t.$3.toStringAsFixed(1)} / ${t.$4.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeriesRankBlock extends StatefulWidget {
  const _SeriesRankBlock({
    required this.repo,
    required this.classLevel,
    required this.roll,
    required this.seriesDocs,
    required this.testDetailTiles,
  });

  final ErpRepository repo;
  final int classLevel;
  final String roll;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> seriesDocs;
  final List<Widget> testDetailTiles;

  @override
  State<_SeriesRankBlock> createState() => _SeriesRankBlockState();
}

class _SeriesRankBlockState extends State<_SeriesRankBlock> {
  late String _seriesId;

  @override
  void initState() {
    super.initState();
    _seriesId = widget.seriesDocs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        MentorGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Overall series rank',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.deepBlue),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _seriesId,
                decoration: const InputDecoration(labelText: 'Test series'),
                isExpanded: true,
                items: [
                  for (final d in widget.seriesDocs)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.data()['name']?.toString() ?? 'Series',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _seriesId = v);
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<MapEntry<String, double>>>(
                future: widget.repo.seriesOverallRanking(seriesId: _seriesId, classLevel: widget.classLevel),
                builder: (context, rankSnap) {
                  if (!rankSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final ranking = rankSnap.data!;
                  final idx = ranking.indexWhere((e) => e.key == widget.roll);
                  if (idx < 0) {
                    return Text(
                      'You have no scored tests in this series yet (or all were NG).',
                      style: GoogleFonts.poppins(fontSize: 12),
                    );
                  }
                  final rank = idx + 1;
                  final pct = ranking[idx].value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your rank: #$rank of ${ranking.length}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'Series average: ${pct.toStringAsFixed(1)}% (mean of % scores across topics)',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Tests (detail)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ...widget.testDetailTiles,
      ],
    );
  }
}
