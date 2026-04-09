import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../core/theme/app_theme.dart';
import '../../data/erp_providers.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';

/// Teacher/Admin: assign today's homework for a class.
class HomeworkTeacherScreen extends ConsumerStatefulWidget {
  const HomeworkTeacherScreen({super.key});

  @override
  ConsumerState<HomeworkTeacherScreen> createState() => _HomeworkTeacherScreenState();
}

class _HomeworkTeacherScreenState extends ConsumerState<HomeworkTeacherScreen> {
  int _classLevel = 8;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  
  // File attachment state
  final List<PlatformFile> _selectedFiles = [];
  final Map<String, double> _uploadProgress = {}; // filename -> progress
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickAndAddFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Added ${result.files.length} file(s)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error picking file: $e')),
      );
    }
  }

  Future<List<Map<String, String>>> _uploadFilesToStorage() async {
    if (_selectedFiles.isEmpty) return [];

    final uploadedUrls = <Map<String, String>>[];
    setState(() => _uploading = true);

    try {
      for (final file in _selectedFiles) {
        if (file.path == null) continue;

        final fileName = file.name;
        final fileExtension = fileName.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        const folder = 'homework_attachments';
        final storagePath = '$folder/class_$_classLevel/${timestamp}_$fileName';

        try {
          final fileToUpload = File(file.path!);
          final task = FirebaseStorage.instance.ref(storagePath).putFile(fileToUpload);

          task.snapshotEvents.listen((event) {
            final progress = event.bytesTransferred / event.totalBytes;
            setState(() => _uploadProgress[fileName] = progress);
          });

          final snapshot = await task;
          final url = await snapshot.ref.getDownloadURL();

          uploadedUrls.add({
            'fileName': fileName,
            'url': url,
            'fileType': fileExtension,
          });

          setState(() => _uploadProgress.remove(fileName));
        } catch (e) {
          debugPrint('Error uploading $fileName: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading $fileName: $e')),
          );
        }
      }
    } finally {
      setState(() => _uploading = false);
    }

    return uploadedUrls;
  }

  Future<void> _save() async {
    final user = ref.read(authProvider);
    if (user == null || !user.isStaff || user.email == null) return;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Upload files first
      final attachments = await _uploadFilesToStorage();

      // Save homework with file URLs
      await ref.read(erpRepositoryProvider).saveHomeworkWithAttachments(
            classLevel: _classLevel,
            title: _title.text.trim(),
            description: _body.text.trim(),
            assignedBy: user.email!,
            attachments: attachments,
          );

      if (mounted) {
        _title.clear();
        _body.clear();
        setState(() => _selectedFiles.clear());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Homework posted for Class $_classLevel${_selectedFiles.isNotEmpty ? ' with ${_selectedFiles.length} file(s)' : ''}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Today's homework",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students see this under Homework for the date you post.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _classLevel,
            decoration: const InputDecoration(labelText: 'Class'),
            items: [
              for (var c = StudentClassLevels.min; c <= StudentClassLevels.max; c++)
                DropdownMenuItem(value: c, child: Text('Class $c')),
            ],
            onChanged: (v) => setState(() => _classLevel = v ?? 8),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            decoration: const InputDecoration(
              labelText: 'Details',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),

          // File Attachments Section
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
                        'Attachments',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _pickAndAddFile,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Add File'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDFs, images (jpg, png, gif)',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  ),

                  // Selected Files List
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...List.generate(_selectedFiles.length, (index) {
                      final file = _selectedFiles[index];
                      final isUploading = _uploadProgress.containsKey(file.name);
                      final progress = _uploadProgress[file.name] ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              file.extension == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                              size: 24,
                              color: AppTheme.deepBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  if (isUploading)
                                    SizedBox(
                                      height: 4,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(value: progress, minHeight: 4),
                                      ),
                                    ),
                                  if (isUploading)
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            if (!isUploading)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() => _selectedFiles.removeAt(index));
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No files selected',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_saving || _uploading) ? null : _save,
            child: _saving || _uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _uploading ? 'Uploading files...' : 'Publish homework',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
