import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_glass_card.dart';
import '../../data/erp_providers.dart';
import '../../models/fees_analytics_model.dart';

/// Admin-only: Financial dashboard showing total fees, pending by class, and quick update.
class FeesAnalyticsPanelScreen extends ConsumerStatefulWidget {
  const FeesAnalyticsPanelScreen({super.key});

  @override
  ConsumerState<FeesAnalyticsPanelScreen> createState() => _FeesAnalyticsPanelScreenState();
}

class _FeesAnalyticsPanelScreenState extends ConsumerState<FeesAnalyticsPanelScreen> {
  late Future<FeesAnalytics> _feesAnalyticsFuture;
  final _currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    _feesAnalyticsFuture = ref.read(erpRepositoryProvider).getFeesAnalytics();
  }

  Future<void> _markStudentAsPaid(String studentDocId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Paid?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Mark $studentName\'s fees as fully paid?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(erpRepositoryProvider).markStudentFeesPaid(studentDocId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $studentName marked as paid')),
        );
        _loadAnalytics();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeesAnalytics>(
      future: _feesAnalyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  'Error loading fees data',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() => _loadAnalytics()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final analytics = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header: Summary Stats
            Text(
              'Fees Dashboard 💰',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.deepBlue),
            ),
            const SizedBox(height: 16),

            // Total Collected vs Pending Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Collected',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormatter.format(analytics.totalCollected),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${analytics.paidStudentsCount}/${analytics.totalStudents} students',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pending',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormatter.format(analytics.totalPending),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${analytics.totalStudents - analytics.paidStudentsCount} pending',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Collection Pie Chart
            MentorGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection Status',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.deepBlue),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: analytics.collectionPercentage,
                            title: '${analytics.collectionPercentage.toStringAsFixed(1)}%',
                            color: Colors.green.shade500,
                            radius: 60,
                            titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: analytics.pendingPercentage,
                            title: '${analytics.pendingPercentage.toStringAsFixed(1)}%',
                            color: Colors.red.shade300,
                            radius: 60,
                            titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Collected', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red.shade300, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Pending', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Class-wise Breakdown
            Text(
              'Class-wise Breakdown',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.deepBlue),
            ),
            const SizedBox(height: 12),
            for (final classBreakdown in analytics.classwiseBreakdown) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Class ${classBreakdown.classLevel}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: classBreakdown.collectionPercentage >= 90
                                  ? Colors.green.shade100
                                  : classBreakdown.collectionPercentage >= 70
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              classBreakdown.statusLabel,
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: classBreakdown.collectionPercentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          classBreakdown.collectionPercentage >= 90
                              ? Colors.green
                              : classBreakdown.collectionPercentage >= 70
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${classBreakdown.paidStudents}/${classBreakdown.totalStudents} paid',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${classBreakdown.totalCollected.toStringAsFixed(0)} / ₹${classBreakdown.totalExpected.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (classBreakdown.pendingStudentsList.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: Text(
                            '${classBreakdown.pendingStudentsList.length} Pending Students',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            for (final student in classBreakdown.pendingStudentsList)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${student.roll} - ${student.name}',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
                                          ),
                                          Text(
                                            '₹${student.duesFees.toStringAsFixed(0)} due',
                                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.red.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 32,
                                      child: FilledButton.tonal(
                                        onPressed: () => _markStudentAsPaid(student.studentDocId, student.name),
                                        child: Text(
                                          'Mark Paid',
                                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Refresh Button
            FilledButton.icon(
              onPressed: () => setState(() => _loadAnalytics()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        );
      },
    );
  }
}
