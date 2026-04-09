import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../models/syllabus_tracker_model.dart';

/// Student view: see syllabus progress for their class
class SyllabusTrackerStudentScreen extends ConsumerStatefulWidget {
  final int classLevel;

  const SyllabusTrackerStudentScreen({super.key, required this.classLevel});

  @override
  ConsumerState<SyllabusTrackerStudentScreen> createState() => _SyllabusTrackerStudentScreenState();
}

class _SyllabusTrackerStudentScreenState extends ConsumerState<SyllabusTrackerStudentScreen> {
  late Future<ClassSyllabus> _syllabusFuture;

  @override
  void initState() {
    super.initState();
    _syllabusFuture = ref.read(erpRepositoryProvider).getClassSyllabus(widget.classLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syllabus Tracker',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your subject progress and see what chapters are coming next.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),

        // Subjects Cards
        Expanded(
          child: FutureBuilder<ClassSyllabus>(
            future: _syllabusFuture,
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
                      Text('Error loading syllabus', style: GoogleFonts.poppins()),
                    ],
                  ),
                );
              }

              final syllabus = snapshot.data ?? ClassSyllabus(
                docId: '',
                classLevel: widget.classLevel,
                subjects: {},
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final coreSubjects = syllabus.getAllCoreSubjects();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: coreSubjects.length,
                itemBuilder: (context, index) {
                  final subjectName = coreSubjects.keys.elementAt(index);
                  final subject = coreSubjects[subjectName]!;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject Name & Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subjectName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppTheme.deepBlue,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: subject.progressPercentage >= 100
                                      ? Colors.green.shade100
                                      : subject.progressPercentage >= 75
                                          ? Colors.blue.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${subject.progressPercentage.toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: subject.progressPercentage >= 100
                                        ? Colors.green.shade700
                                        : subject.progressPercentage >= 75
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: subject.progressPercentage / 100,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                subject.progressPercentage >= 100
                                    ? Colors.green
                                    : subject.progressPercentage >= 75
                                        ? Colors.blue
                                        : subject.progressPercentage >= 50
                                            ? Colors.orange
                                            : Colors.red,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${subject.completedChapters}/${subject.totalChapters} chapters',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              if (subject.progressPercentage == 100)
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Complete!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Chapters Preview
                          if (subject.chapters.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Text(
                              'Chapters',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...subject.chapters.take(5).map((chapter) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      chapter.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: chapter.isCompleted ? Colors.green : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        chapter.chapterNumber != null
                                            ? 'Ch ${chapter.chapterNumber}: ${chapter.title}'
                                            : chapter.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          decoration: chapter.isCompleted ? TextDecoration.lineThrough : null,
                                          color: chapter.isCompleted ? Colors.grey : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (subject.chapters.length > 5) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+${subject.chapters.length - 5} more chapters',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'No chapters added yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
