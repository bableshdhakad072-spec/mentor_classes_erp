# Quick Start: Accessing New Features

## 🚀 Immediate Access (Without Shell Changes)

### Option 1: Via Direct Routes
Add these navigation methods to any screen:

```dart
// Go to Batch Manager
Navigator.pushNamed(context, '/batch-manager');

// Go to Enhanced Marks Upload
Navigator.pushNamed(context, '/enhanced-marks-upload');

// Go to Academic Resources
Navigator.pushNamed(context, '/academic-resources');

// Go to Performance Analytics
Navigator.push(context, MaterialPageRoute(
  builder: (context) => PerformanceAnalyticsScreen(
    classLevel: 7,
    rollNumber: '12',
    studentName: 'John Doe',
  ),
));
```

### Option 2: Add Buttons to Existing Screens
Teachers can add FloatingActionButtons or menu items:

```dart
// In staff_home_page.dart or any teacher screen
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/batch-manager'),
  child: const Icon(Icons.people),
)

// Or in a dropdown menu
PopupMenuItem(
  child: const Text('Manage Batch'),
  onTap: () => Navigator.pushNamed(context, '/batch-manager'),
)
```

---

## 📋 Integration Steps

### Step 1: Update Staff Home Page
Add shortcuts to new features:

```dart
// In staff_home_page.dart
Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/batch-manager'),
        child: _buildActionCard(
          icon: Icons.people,
          title: 'Batch Manager',
          color: Colors.blue,
        ),
      ),
    ),
    Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/enhanced-marks-upload'),
        child: _buildActionCard(
          icon: Icons.edit,
          title: 'Upload Marks',
          color: Colors.green,
        ),
      ),
    ),
  ],
)
```

### Step 2: Update Shell Navigation (Optional)
To add to main shell, modify:

```dart
// In main_shell_screen.dart
static const _staffTitles = [
  'Home',
  'Attendance',
  'Batch Manager',        // NEW
  'Academic hub',
  'Enhanced Marks',       // NEW
  'Tests',
  'Leaderboard',
  'Schedule Management',
  'Homework',
  'Notices',
  'About',
];

List<Widget> _staffPages() => const [
  StaffHomePage(),
  TeacherAttendanceScreen(),
  BatchManagerScreen(),                    // NEW
  AcademicResourceHubScreen(),             // UPDATED
  EnhancedMarksUploadScreen(),             // NEW
  TestHubScreen(),
  EnhancedLeaderboardScreen(),
  ScheduleAdminScreen(),
  HomeworkTeacherScreen(),
  AnnouncementsStaffScreen(),
  AboutScreen(),
];

final icons = staff ? const [
  Icons.home_outlined,
  Icons.fact_check_outlined,
  Icons.people_outlined,                   // NEW
  Icons.menu_book_outlined,
  Icons.pencil_outlined,                   // NEW
  Icons.quiz_outlined,
  Icons.emoji_events_outlined,
  Icons.calendar_today_outlined,
  Icons.assignment_outlined,
  Icons.campaign_outlined,
  Icons.info_outlined,
] : ...;
```

### Step 3: Test Integration
```dart
// Run tests
flutter test

// Check for any import errors
dart analyze

// Build and run
flutter run
```

---

## 🔗 Navigation Helpers

### Create a navigation mixin for easy access:

```dart
// Create: lib/core/utils/navigation_helper.dart
mixin NavigationHelper {
  void goToBatchManager(BuildContext context) {
    Navigator.pushNamed(context, '/batch-manager');
  }

  void goToEnhancedMarksUpload(BuildContext context) {
    Navigator.pushNamed(context, '/enhanced-marks-upload');
  }

  void goToAcademicResources(BuildContext context) {
    Navigator.pushNamed(context, '/academic-resources');
  }

  void goToPerformanceAnalytics(
    BuildContext context, {
    required int classLevel,
    required String rollNumber,
    required String studentName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerformanceAnalyticsScreen(
          classLevel: classLevel,
          rollNumber: rollNumber,
          studentName: studentName,
        ),
      ),
    );
  }
}

// Usage in any screen:
class MyScreen extends ConsumerWidget with NavigationHelper {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => goToBatchManager(context),
    );
  }
}
```

---

## 🧪 Testing New Features

### Test Checklist:

#### Academic Resources
- [ ] Login as teacher
- [ ] Navigate to `/academic-resources`
- [ ] Try uploading a PDF
- [ ] Verify file appears in View tab
- [ ] Test subject filter
- [ ] Test resource type tabs
- [ ] Try downloading file
- [ ] Login as student
- [ ] Browse available resources
- [ ] Verify can't upload

#### Batch Manager
- [ ] Login as teacher
- [ ] Navigate to `/batch-manager`
- [ ] Select different classes
- [ ] Test search functionality
- [ ] Add a new student
- [ ] Edit student details
- [ ] Update student fees
- [ ] Remove and restore student
- [ ] Verify fees status displays

#### Enhanced Marks Upload
- [ ] Login as teacher
- [ ] Navigate to `/enhanced-marks-upload`
- [ ] Select class and test type
- [ ] Enter test details
- [ ] Add marks for students
- [ ] Test "NG" (Not Given) toggle
- [ ] Save and verify in Firestore
- [ ] Check ranks were calculated
- [ ] Check percentages were calculated

#### Performance Analytics
- [ ] Login as student
- [ ] Complete test marks entry (as teacher)
- [ ] Navigate to Performance Analytics
- [ ] Verify trend chart displays
- [ ] Check subject analysis
- [ ] View test history
- [ ] Verify calculations accurate

---

## 🔧 Troubleshooting

### Issue: Routes not found
**Solution**: Verify routes are in `app.dart`:
```dart
'/batch-manager': (context) => const BatchManagerScreen(),
'/enhanced-marks-upload': (context) => const EnhancedMarksUploadScreen(),
'/academic-resources': (context) => const AcademicResourceHubScreen(),
```

### Issue: Firestore permissions denied
**Solution**: Update Firestore rules:
```firestore
match /academic_resources/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth.token.isStaff == true;
}

match /students/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth.token.isStaff == true;
}

match /test_marks/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth.token.isStaff == true;
}
```

### Issue: Firebase Storage upload fails
**Solution**: Check storage rules:
```storage
match /academic_resources/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth.token.isStaff == true;
}
```

### Issue: Data not displaying
**Solution**: Verify:
1. Firestore data exists
2. Class level matches (int vs string)
3. active/isActive flags are true
4. User has reading permissions

---

## 📝 Environment Setup

### Required Firebase Configuration:
```json
// firebase.json snippet
{
  "firestore": {
    "collections": {
      "academic_resources": {},
      "students": {},
      "test_marks": {}
    }
  },
  "storage": {
    "rules": "storage.rules",
    "target": "academic-resources"
  }
}
```

### Environment Variables (Optional):
```dart
// Create lib/config/feature_flags.dart
class FeatureFlags {
  static const bool enableAcademicResources = true;
  static const bool enableBatchManager = true;
  static const bool enablePerformanceAnalytics = true;
  static const bool enableEnhancedMarksUpload = true;
  
  // Maximum file size (bytes)
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  
  // Pass percentage for calculations
  static const double passPercentage = 40.0;
}
```

---

## 🎓 User Documentation

### For Teachers:
1. **Academic Resources**: Menu → Upload Resources → Fill details → Upload file
2. **Batch Manager**: Menu → Manage Batch → Select class → Add/Edit/Remove students
3. **Enhanced Marks**: Menu → Upload Marks → Select class/type → Enter marks → Save

### For Students:
1. **Browse Resources**: Menu → Academic Resources → Select subject → View/Download
2. **Performance**: Dashboard → Click "Performance" → View analytics → Check topics
3. **Schedule**: Menu → My Schedule → View timetable

---

## 📞 Support

### Common Issues:
1. **Can't upload file**: Check file size < 50MB and format supported
2. **Marks not saving**: Verify at least 1 student has marks (not all NG)
3. **Student list empty**: Check `active: true` in Firestore
4. **Performance not showing**: Complete a test and wait ~5 seconds for calculation

---

## 📅 Version Info
- **Release**: April 2026
- **Status**: Beta
- **Compatibility**: Flutter 3.11.4+, Firestore 6.0+

---

## 🚀 Next Steps
1. Test all features with sample data
2. Integrate into shell navigation
3. Gather user feedback
4. Plan optimization for large datasets
5. Add offline support (Phase 2)
