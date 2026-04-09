# Three New Major Features - Implementation Guide

## Overview
This document outlines three major new features added to the Mentor Classes ERP application:
1. **Academic Hub (Resource Center)** - Resource management system
2. **Student & Batch Management** - Enhanced student management with class selection
3. **Test & Performance System** - Advanced testing and analytics

---

## 1. 📚 Academic Hub (Resource Center)

### What It Does
Teachers can upload study materials (PDFs, images, documents) organized by:
- **Class** (5-10)
- **Subject** (Maths, Science, Hindi, etc.)
- **Resource Type** (नोट्स/टेस्ट पेपर्स/वर्कशीट)

Students can browse, preview, and download resources.

### For Students
- **Route**: `/academic-resources` or `/academic`
- **Location in Shell**: Tab in sidebar
- **Features**:
  - Browse resources by subject
  - Preview PDFs and images
  - Download files
  - Filter by resource type

### For Teachers
- **Upload**: Full upload interface with metadata
- **Manage**: Deactivate resources
- **Organize**: By class, subject, type
- **Storage**: Firebase Storage at `academic_resources/class_X/subject/type/`

### Database Schema
```dart
Collection: academic_resources
{
  classLevel: int (5-10)
  subject: string (e.g., "Maths", "Science")
  resourceType: string ("notes", "test_papers", "worksheets")
  title: string
  description: string
  fileUrl: string (Firebase Storage URL)
  fileName: string
  fileType: string ("pdf", "image", "doc")
  uploadedBy: string (teacher email)
  uploadedAt: Timestamp
  isActive: boolean
}
```

### Key Files
- Models: `lib/models/academic_resource_model.dart`
- Screens: 
  - `lib/features/academic/academic_resource_hub_screen.dart` (Main hub)
  - `lib/features/academic/resources_view_screen.dart` (Browse)
  - `lib/features/academic/resource_upload_screen.dart` (Upload)
- Repository: Methods in `lib/data/erp_repository.dart`
- Providers: `lib/data/erp_providers.dart`

### Usage Example
1. **Teacher uploads**: Click "Upload" tab → Select class, subject, resource type → Upload file
2. **Student browses**: Click "Academic Resources" → Select class → Browse resources → Click "Download"

---

## 2. 👥 Student & Batch Management

### What It Does
Teachers can manage complete class batches with:
- Add students manually (no Excel needed)
- Edit student details
- Remove/restore students
- View and update fees per student
- See student performance summaries

### For Staff
- **Route**: `/batch-manager`
- **Access**: Staff menu or sidebar button
- **Features**:
  - Select class (5-10)
  - View all students with fees status
  - Search by name or roll number
  - Add new student (name, roll, mobile, fees)
  - Edit student details
  - Update fees (total and paid amount)
  - Remove student
  - Color-coded fees status (Green = Paid, Orange = Pending)

### Database Schema
```dart
Collection: students (Enhanced)
{
  studentClass: int (5-10)
  rollNumber: string
  name: string
  mobile_contact: string (optional)
  emergency_contact: string (optional)
  total_fees: double
  remaining_fees: double
  fees_updated_at: Timestamp
  active: boolean
  enrolledDate: Timestamp
  ...(existing fields)
}
```

### Key Files
- Models: `lib/models/student_batch_model.dart`
- Screens: `lib/features/student/batch_manager_screen.dart`
- Repository: Methods in `lib/data/erp_repository.dart`
- Providers: `lib/data/erp_providers.dart`

### Usage Example
```
1. Open Batch Manager
2. Select Class 7
3. See all students with:
   - Roll number & name
   - Fees paid status (progress bar)
   - Remaining dues (₹ amount)
4. Actions:
   - Edit: Change name or roll
   - Fees: Update total/paid amounts
   - Remove: Deactivate student
5. Add new: Click FAB "Add Student" → Fill form → Save
```

---

## 3. 📈 Test & Performance System

### What It Does
Enhanced testing system with:
- Class and test type selection
- Automatic percentage and rank calculation
- Detailed performance analytics and graphs
- Test history with performance trends

### For Teachers
- **Route**: `/enhanced-marks-upload`
- **Features**:
  - Select class (5-10)
  - Select test type (साप्ताहिक/मासिक/यूनिट/सेमेस्टर)
  - Enter test details (name, subject, topic, max marks)
  - Add marks for each student
  - Mark students as "NG" (Not Given)
  - Auto-saves tests with ranks and percentages

### For Students
- **Route**: `/performance/:classLevel/:rollNumber/:studentName`
- **Display**: Performance analytics dashboard
- **Features**:
  - Summary cards: Average, best, trend, tests count
  - Performance trend graph (line chart)
  - Subject analysis (strongest/weakest subject)
  - Complete test history with:
    - Marks and percentage
    - Class rank
    - Performance band (A+/A/B/C/D/F)
    - Progress bar
    - Test date

### Database Schema
```dart
Collection: test_marks (Enhanced)
{
  classLevel: int (5-10)
  subject: string
  topic: string
  testName: string
  testType: string ("weekly", "monthly", "unit", "term")
  testKind: string ("single", "series")
  maxMarks: double
  marksByRoll: map<string, double>
  percentageByRoll: map<string, double> // Auto-calculated
  ranksByRoll: map<string, int> // Auto-calculated
  notGivenRolls: list<string>
  createdAt: Timestamp
  createdBy: string
}
```

### Key Files
- Models: `lib/models/performance_analytics_model.dart`
- Screens:
  - `lib/features/tests/enhanced_marks_upload_screen.dart` (Mark entry)
  - `lib/features/tests/performance_analytics_screen.dart` (Analytics)
- Repository: Methods in `lib/data/erp_repository.dart`
- Providers: `lib/data/erp_providers.dart`

### Usage Example - Teacher

```
1. Open Enhanced Marks Upload
2. Select Class 7
3. Select Test Type "साप्ताहिक (Weekly)"
4. Enter test details:
   - Name: "Chapter 5 Quiz"
   - Subject: "Maths"
   - Topic: "Algebra"
   - Max Marks: 50
5. Enter marks for each student:
   - Student A: 45 marks (OK)
   - Student B: 38 marks (OK)
   - Student C: (checked NG - Not Given)
6. Click "Save Marks"
7. System auto-calculates:
   - Student A: 90%
   - Student B: 76%
   - Rank 1: Student A, Rank 2: Student B
```

### Usage Example - Student
```
1. Open Performance Analytics
2. See Summary Dashboard:
   - Average Score: 75.5%
   - Best Score: 92%
   - Tests Given: 8
   - Trend: 📈 Improving
3. View Performance Trend Chart
4. See Subject Analysis:
   - Strongest: Maths (82% avg)
   - Needs Work: Science (65% avg)
5. Browse Test History:
   - Test 1: 75% (Rank 3/20)
   - Test 2: 80% (Rank 2/20)
   - Test 3: 92% (Rank 1/20)
```

---

## Firestore Collections

### New Collections
```
academic_resources/
  - classLevel
  - subject
  - resourceType
  - title
  - description
  - fileUrl
  - fileName
  - fileType
  - uploadedBy
  - uploadedAt
  - isActive
```

### Enhanced Collections
- `students` - Added: enrolledDate, active flag
- `test_marks` - Ready to use with new UI

---

## Firebase Storage

### Structure
```
academic_resources/
├── class_5/
│   ├── Maths/
│   │   ├── notes/
│   │   ├── test_papers/
│   │   └── worksheets/
│   ├── Science/
│   ├── Hindi/
│   └── ...
├── class_6/
│   └── ...
└── class_10/
    └── ...
```

### File Types Supported
- **PDFs**: For notes and test papers
- **Images**: JPG, PNG, GIF, WebP (for visual content)
- **Documents**: DOCX files

### Max File Size
- 50MB per file (configurable in resource_upload_screen.dart)

---

## Providers (State Management)

### Class Selection (Shared)
```dart
selectedClassProvider // Current class level (5-10)
```

### Academic Resources
```dart
selectedResourceTypeProvider // Filter: notes, test_papers, worksheets
selectedSubjectProvider // Filter: subject name
academicResourcesProvider // Stream of resources
subjectsForClassProvider // Available subjects for class
```

### Batch Management
```dart
studentsByClassEnhancedProvider // Enhanced student list
refreshTriggerProvider // Manual refresh trigger
```

### Performance Analytics
```dart
selectedTestTypeProvider // Filter: weekly, monthly, unit, term
testMarksForClassProvider // Test marks with filters
studentPerformanceProvider // Individual student analytics
classPerformanceSummaryProvider // Class-wide summary
```

---

## App Routes

### New Routes
```dart
'/academic-resources'      // Main academic resource hub
'/academic'                // Alias for academic-resources
'/batch-manager'           // Batch management
'/enhanced-marks-upload'   // Enhanced marks entry
'/performance'             // Performance analytics (base)
```

---

## Configuration & Customization

### Change Test Types
Edit in `enhanced_marks_upload_screen.dart`:
```dart
final List<String> _testTypes = ['weekly', 'monthly', 'unit', 'term'];
```

### Change Subject List
Edit in `resource_upload_screen.dart`:
```dart
final List<String> _subjects = [
  'Maths', 'Science', 'Hindi', 'English', 
  'Social Studies', 'History', 'Geography', ...
];
```

### Change Max File Size
Edit in `resource_upload_screen.dart`:
```dart
// Modify FilePicker settings or add validation before upload
```

### Change Pass Percentage
Edit in `performance_analytics_model.dart`:
```dart
// In getPassFailStats method:
bool get isPassed => percentage >= 40; // Change 40 to desired value
```

---

## Integration Notes

### Authentication
Currently uses stub: `teacher@mentorclasses.com`
**TODO**: Replace with actual auth provider in:
- `resource_upload_screen.dart:_uploadResource()`
- `enhanced_marks_upload_screen.dart:_uploadMarks()`

### Notifications
Parent notifications are currently stubs. To activate:
1. Implement FCM in `lib/core/notifications/parent_notification_stub.dart`
2. Create Cloud Functions for sending notifications
3. Uncomment notification calls in repository methods

### Performance Optimization
- Pagination not implemented for large student lists
- Consider adding for 1000+ students
- Firestore queries use `.limit(10)` for analytics

---

## Testing Checklist

- [ ] Upload resource as teacher
- [ ] Download resource as student
- [ ] Add student manually
- [ ] Edit student details
- [ ] Update student fees
- [ ] Remove and restore student
- [ ] Upload marks with ranks
- [ ] View performance analytics
- [ ] Test class selector across screens
- [ ] Test search functionality
- [ ] Verify Firebase Storage upload
- [ ] Check Firestore data structure

---

## Troubleshooting

### Resources not appearing
1. Check Firebase collection: `academic_resources`
2. Verify `isActive: true`
3. Check `classLevel` matches selected class
4. Verify `fileUrl` is accessible

### Student list not loading
1. Check Firebase `students` collection
2. Verify `studentClass` field exists
3. Check `active: true` flag
4. Verify data format (string vs int)

### Marks upload fails
1. Check max marks is > 0
2. Verify test name is not empty
3. Check at least one student has marks
4. Verify class level is valid (5-10)

---

## Future Enhancements

1. **Bulk operations**: Bulk import/export students
2. **Performance reports**: Generate PDF reports
3. **Leaderboard redesign**: Weekly/monthly/overall filtering
4. **Student messaging**: Direct communication system
5. **Assignment tracking**: Assignment upload and submission
6. **Parent portal**: Dedicated parent app
7. **Mobile optimization**: Better mobile UX
8. **Offline sync**: Work offline, sync when online

---

## Tech Stack

- **Frontend**: Flutter + Riverpod
- **Backend**: Firebase (Firestore + Storage)
- **Charts**: FL Chart
- **File Management**: File Picker + Firebase Storage
- **UI**: Material 3 + Custom theme

---

## Support & Maintenance

For issues or features:
1. Check Firestore console for data validation
2. Verify Firebase permissions
3. Check app logs for error details
4. Review this guide for configuration options

---

Generated: April 2026
Version: 1.0.0
