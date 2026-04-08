import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/homework_service.dart';

// Homework Service Provider
final homeworkServiceProvider = Provider((ref) {
  return HomeworkService();
});

// Get homework files for a class
final homeworkFilesProvider =
    StreamProvider.family<List<HomeworkFile>, String>((ref, classId) {
  final service = ref.watch(homeworkServiceProvider);
  return service.getHomeworkFiles(classId);
});

// Upload state - using NotifierProvider
class HomeworkUploadNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setUploading(bool val) => state = val;
}

final homeworkUploadStateProvider = 
    NotifierProvider<HomeworkUploadNotifier, bool>(HomeworkUploadNotifier.new);

// Selected file - using NotifierProvider
class SelectedHomeworkNotifier extends Notifier<HomeworkFile?> {
  @override
  HomeworkFile? build() => null;
  
  void setSelected(HomeworkFile? file) => state = file;
}

final selectedHomeworkFileProvider = 
    NotifierProvider<SelectedHomeworkNotifier, HomeworkFile?>(SelectedHomeworkNotifier.new);
