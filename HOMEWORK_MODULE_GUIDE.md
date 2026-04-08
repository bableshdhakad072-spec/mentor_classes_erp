# Homework Module Implementation Guide

This guide explains how to integrate and use the Ultimate Homework Module in your Flutter ERP application.

## 📦 Installed Dependencies

The following dependencies have been added to your `pubspec.yaml`:

- `flutter_pdfview: ^1.3.0` - PDF viewing
- `cached_network_image: ^3.3.1` - Image caching
- `dio: ^5.4.0` - File downloads
- `permission_handler: ^11.4.4` - Permission management

## 📁 File Structure

```
lib/
├── services/
│   └── homework_service.dart        # File upload/download service
├── screens/
│   ├── homework_list_screen.dart    # List of homework files
│   ├── homework_upload_screen.dart  # Teacher upload interface
│   └── file_preview_screen.dart     # PDF/Image/Doc preview
└── providers/
    └── homework_provider.dart       # Riverpod providers
```

## 🚀 Quick Start

### 1. Display Homework List (For Students & Teachers)

```dart
import 'package:flutter/material.dart';
import 'lib/screens/homework_list_screen.dart';

// In your widget tree
HomeworkListScreen(
  classId: 'class_123',
  isTeacher: false, // true for teachers
)
```

### 2. Teacher Upload Interface

```dart
import 'package:flutter/material.dart';
import 'lib/screens/homework_upload_screen.dart';

// Navigate to upload screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HomeworkUploadScreen(
      classId: 'class_123',
      teacherName: 'John Doe',
      teacherId: 'teacher_456',
    ),
  ),
);
```

## 🔑 Key Features

### HomeworkService
The main service for managing homework files:

```dart
final homeworkService = HomeworkService();

// Upload homework
await homeworkService.uploadHomework(
  classId: 'class_123',
  file: File('/path/to/file'),
  fileName: 'assignment.pdf',
  fileType: 'pdf', // 'pdf', 'image', or 'doc'
  uploadedBy: 'teacher_456',
  teacherName: 'John Doe',
);

// Get homework files (Stream)
homeworkService.getHomeworkFiles('class_123').listen((files) {
  // files is List<HomeworkFile>
});

// Download file
final filePath = await homeworkService.downloadFile(
  downloadUrl,
  'filename.pdf',
);

// Delete homework
await homeworkService.deleteHomework('class_123', 'homework_id');
```

### File Type Support

| File Type | Extensions | Icon | Color |
|-----------|-----------|------|-------|
| PDF | `.pdf` | 📄 | Red |
| Images | `.jpg`, `.jpeg`, `.png` | 🖼️ | Green |
| Documents | `.doc`, `.docx` | 📋 | Blue |

### HomeworkFile Model

```dart
class HomeworkFile {
  final String id;
  final String fileName;
  final String fileType;      // 'pdf', 'image', 'doc'
  final String downloadUrl;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String teacherName;
  
  // ... methods
}
```

## 🎨 UI Components

### HomeworkFileCard
Individual homework item with preview and download buttons:

- File type icon with color coding
- File name with overflow handling
- Upload date and teacher name
- Preview button (navigates to FilePreviewScreen)
- Download button (saves to device)
- Delete button (teachers only)

### FilePreviewScreen
Full-screen preview with:

- **PDFs**: Uses `flutter_pdfview` for document viewing
- **Images**: Uses `cached_network_image` for optimized loading
- **Documents**: Shows file info with download option
- Download button in app bar
- Loading indicators
- Error handling

## 🔐 Firebase Setup

### Firestore Collection Structure

```
classes/
├── {classId}/
    └── homework/
        ├── {homeworkId}/
            ├── id: string
            ├── fileName: string
            ├── fileType: string ('pdf', 'image', 'doc')
            ├── downloadUrl: string
            ├── uploadedAt: timestamp
            ├── uploadedBy: string
            └── teacherName: string
```

### Firebase Storage Structure

```
storage/
└── homework/
    └── {classId}/
        └── {timestamp}_{fileName}
```

### Required Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /classes/{classId}/homework/{document=**} {
      // Teachers can upload
      allow create: if request.auth != null && isTeacher(request.auth.uid);
      // Everyone can read their class homework
      allow read: if request.auth != null && isUserInClass(classId);
      // Teachers can delete their uploads
      allow delete: if request.auth != null && isTeacher(request.auth.uid);
    }
  }
  
  function isTeacher(uid) {
    return get(/databases/$(database)/documents/users/$(uid)).data.role == 'teacher';
  }
  
  function isUserInClass(classId) {
    return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.classIds.hasAny([classId]);
  }
}
```

### Required Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /homework/{allPaths=**} {
      // Allow authenticated users to upload
      allow write: if request.auth != null;
      // Allow authenticated users to read
      allow read: if request.auth != null;
    }
  }
}
```

## 📲 Permissions Required

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Allow access to photos for homework documents</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>Allow access to documents for homework</string>
```

## 🔄 Integration Example

```dart
// Complete homework module integration in your app
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/screens/homework_list_screen.dart';
import 'lib/screens/homework_upload_screen.dart';

class HomeworkTabScreen extends ConsumerWidget {
  final String classId;
  final String userId;
  final String userName;
  final bool isTeacher;

  const HomeworkTabScreen({
    required this.classId,
    required this.userId,
    required this.userName,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework'),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeworkUploadScreen(
                    classId: classId,
                    teacherName: userName,
                    teacherId: userId,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: HomeworkListScreen(
        classId: classId,
        isTeacher: isTeacher,
      ),
    );
  }
}
```

## 🐛 Troubleshooting

### PDF not displaying
- Ensure `flutter_pdfview` is properly installed
- Check that PDF URL is valid and accessible
- Check Firestore and Storage permissions

### Images not loading
- Verify Firebase Storage URLs are accessible
- Check image file formats (jpg, jpeg, png)
- Clear app cache: `flutter clean`

### Download failing
- Check device storage space
- Verify `path_provider` permissions
- Check `dio` configuration and timeouts

### Upload failing
- Verify Firebase Storage rules
- Check file size limits in Firestore
- Ensure user has teacher role (if restricted)

## 📚 Additional Resources

- [Flutter PDF View](https://pub.dev/packages/flutter_pdfview)
- [Cached Network Image](https://pub.dev/packages/cached_network_image)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Firebase Storage](https://firebase.google.com/docs/storage)
- [File Picker](https://pub.dev/packages/file_picker)

## ✅ Checklist for Integration

- [ ] Run `flutter pub get`
- [ ] Update Firestore rules
- [ ] Update Storage rules
- [ ] Add Android permissions
- [ ] Add iOS permissions
- [ ] Create `homework_service.dart`
- [ ] Create `homework_list_screen.dart`
- [ ] Create `homework_upload_screen.dart`
- [ ] Create `file_preview_screen.dart`
- [ ] Create `homework_provider.dart`
- [ ] Test upload with sample PDF
- [ ] Test upload with sample image
- [ ] Test preview functionality
- [ ] Test download functionality
- [ ] Test for teachers and students

---

For issues or questions, refer to the official documentation or Firebase console logs.
