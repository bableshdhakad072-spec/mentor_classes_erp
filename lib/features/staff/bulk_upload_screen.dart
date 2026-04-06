import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mentor_footer.dart';
import 'student_excel_parser.dart';
import 'student_upload_repository.dart';

/// Picks an Excel file (Name, RollNo, Password, Class) and uploads rows to Firestore.
class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final _repo = StudentUploadRepository();
  bool _busy = false;
  String? _status;
  StudentExcelParseResult? _lastParse;

  Future<void> _pickAndUpload() async {
    setState(() {
      _busy = true;
      _status = null;
      _lastParse = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _status = 'No file selected.');
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _status =
              'Could not read file in memory. Enable file content loading or pick a smaller .xlsx file.';
        });
        return;
      }

      final parsed = StudentExcelParser.parse(bytes);
      setState(() => _lastParse = parsed);

      if (parsed.rows.isEmpty) {
        setState(() => _status = 'No valid data rows found.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid data rows found in this sheet.')),
          );
        }
        return;
      }

      final count = await _repo.uploadRows(parsed.rows);
      setState(() {
        _status =
            'Uploaded $count student record(s).${parsed.errors.isNotEmpty ? ' Some rows had warnings — see below.' : ''}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded $count student record(s).')),
        );
      }
    } on ExcelParseException catch (e) {
      setState(() => _status = e.message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade800),
        );
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Bulk upload students',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Excel format',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'First row must include: Name, RollNo, Password, Class.\n'
                            'Optional: MobileNumber, EmergencyContact.\n'
                            'Class must be 5–10. Rows merge into Firestore students by roll.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _busy ? null : _pickAndUpload,
                            icon: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _busy ? 'Working…' : 'Choose Excel file',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _status!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.4,
                            color: AppTheme.deepBlueDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_lastParse != null && _lastParse!.errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Row warnings',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._lastParse!.errors.take(20).map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $e',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ),
                        ),
                    if (_lastParse!.errors.length > 20)
                      Text(
                        '… and ${_lastParse!.errors.length - 20} more',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const MentorFooter(),
        ],
      ),
    );
  }
}
