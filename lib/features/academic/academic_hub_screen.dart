import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// NCERT worksheets, papers, syllabus — opens placeholder PDF URLs.
class AcademicHubScreen extends StatelessWidget {
  const AcademicHubScreen({super.key, required this.isStaffView});

  final bool isStaffView;

  static const _samplePdf = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.deepBlue,
            indicatorColor: AppTheme.deepBlue,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: const [
              Tab(text: 'NCERT Worksheets'),
              Tab(text: 'Question Papers'),
              Tab(text: 'Syllabus Tracker'),
            ],
          ),
          if (isStaffView)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Staff preview — replace links with your Drive / portal URLs later.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _ResourceList(
                  items: const [
                    ('Number systems drill', _samplePdf),
                    ('Algebra practice set', _samplePdf),
                    ('Science lab worksheet', _samplePdf),
                  ],
                  onOpen: (u) => _open(context, u),
                ),
                _ResourceList(
                  items: const [
                    ('Half-yearly (sample)', _samplePdf),
                    ('MCQ bank Class 9', _samplePdf),
                    ('Previous year (placeholder)', _samplePdf),
                  ],
                  onOpen: (u) => _open(context, u),
                ),
                _ResourceList(
                  items: const [
                    ('Term-wise outline', _samplePdf),
                    ('NCERT mapping sheet', _samplePdf),
                    ('Practical list', _samplePdf),
                  ],
                  onOpen: (u) => _open(context, u),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceList extends StatelessWidget {
  const _ResourceList({
    required this.items,
    required this.onOpen,
  });

  final List<(String label, String url)> items;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (label, url) = items[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text('PDF / external', style: GoogleFonts.poppins(fontSize: 12)),
            trailing: FilledButton.tonal(
              onPressed: () => onOpen(url),
              child: Text('Open', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        );
      },
    );
  }
}
