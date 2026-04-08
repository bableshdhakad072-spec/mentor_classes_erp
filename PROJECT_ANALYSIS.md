# Mentor Classes ERP - Project Analysis

**Project**: Flutter-based Educational Resource Planning System  
**Firebase Backend**: Cloud Firestore + Remote Config  
**State Management**: Flutter Riverpod  
**Database**: Hive (local persistence for todos)  
**Build Date**: Lead Architect: Harshit Dhakad | Founder: Yogesh Udawat

---

## 1. FIRESTORE COLLECTIONS & DATABASE SCHEMA

### Active Collections

| Collection | Purpose | Key Fields | Document Structure |
|------------|---------|------------|-------------------|
| **students** | Student profiles & fees | name, rollNumber, studentClass, total_fees, remaining_fees, password, studentPhone, studentEmail, emergencyContact | Doc ID = Firestore auto-ID or teacher-set |
| **attendance** | Daily class attendance | classLevel, dateKey (YYYY-MM-DD), isHoliday, holidayMessage, records {roll: bool}, updatedAt, updatedBy | ID format: `{classLevel}_{dateKey}` |
| **test_marks** | Test results & rankings | classLevel, subject, topic, testName, testKind (single/series), seriesId, dateKey, maxMarks, marks {roll: score}, notGivenRolls[], rankByRoll, createdBy, createdAt | Auto-doc |
| **test_series** | Test series metadata | name, classLevel, subject, topics[], createdBy, createdAt | Auto-doc |
| **homework** | Daily assignments | classLevel, title, description, dateKey, assignedBy, createdAt | Auto-doc |
| **announcements** | Notices & updates | title, body, classLevel (nullable = all classes), type (info/holiday), createdAt | Auto-doc |
| **schedules** | Weekly timetable template | classLevel (doc ID), days {monday: [slot1, slot2], ...}, updatedAt | Doc ID = `{classLevel}` |
| **class_schedules** | Period-wise class info (legacy) | classLevel, subject, time, teacher, room, createdAt | Auto-doc |
| **test_schedules** | Test announcements | classLevel, testName, date, time, syllabus, maxMarks, createdAt | Auto-doc |
| **holidays** | Holiday declarations | classLevel, date, message, createdAt | Auto-doc |

### Data Structure Details

#### Student Document Example
```json
{
  "name": "Raj Kumar",
  "rollNumber": "15",
  "studentClass": 9,
  "password": "hashed_or_plain",
  "total_fees": 50000.0,
  "remaining_fees": 10000.0,
  "fees_updated_at": Timestamp,
  "studentPhone": "9999999999",
  "studentEmail": "student@example.com",
  "emergencyContact": {
    "name": "Parent Name",
    "phone": "8888888888"
  },
  "fees": {
    "sessionCleared": false,
    "sessionResetAt": Timestamp,
    "note": "New session after promotion"
  },
  "lastPromotion": {
    "fromClass": 8,
    "toClass": 9,
    "at": Timestamp
  }
}
```

#### Schedule Document Example (schedules/{classLevel})
```json
{
  "days": {
    "monday": [
      {"start": "09:00", "end": "10:00", "subject": "English", "bring": "Book, notebook"},
      {"start": "10:00", "end": "11:00", "subject": "Mathematics", "bring": "Calculator"}
    ],
    "tuesday": [...]
  },
  "updatedAt": Timestamp
}
```

#### Attendance Document Example (attendance/{classLevel}_{dateKey})
```json
{
  "classLevel": 9,
  "dateKey": "2026-04-08",
  "isHoliday": false,
  "records": {
    "15": true,
    "16": false,
    "17": true
  },
  "updatedAt": Timestamp,
  "updatedBy": "teacher@email.com"
}
```

#### Test Marks Document Example
```json
{
  "classLevel": 9,
  "subject": "Mathematics",
  "topic": "Algebra",
  "testName": "Unit Test 1",
  "testKind": "single",
  "seriesId": null,
  "dateKey": "2026-04-08",
  "maxMarks": 50,
  "marks": {
    "15": 42.5,
    "16": 38.0,
    "17": 45.0
  },
  "notGivenRolls": ["18"],
  "rankByRoll": {
    "17": 1,
    "15": 2,
    "16": 3,
    "18": 0
  },
  "createdBy": "teacher@email.com",
  "createdAt": Timestamp
}
```

---

## 2. ADMIN/TEACHER SCREENS & FEATURES

### Staff Navigation (from MainShellScreen)

#### Admin-Only Features
1. **Bulk Upload Students** (`features/staff/bulk_upload_screen.dart`)
   - Excel file import (Name, Roll Number, Password, Class, Phone, Email, Emergency Contact)
   - Batch upload to Firestore with validation
   - Supports .xlsx/.xls formats
   - Error reporting per row

2. **Promote Students to Next Class** (`features/staff/promote_class_screen.dart`)
   - Bulk move all students from class N → N+1
   - Resets fees status for new session
   - Maintains attendance history
   - Max class: 10

#### Teacher Features (Admin + Teacher Role)
1. **Attendance Management** (`features/attendance/teacher_attendance_screen.dart`)
   - Mark attendance by roll number
   - Mark-all-present button
   - Holiday declaration with message
   - Auto-notifies parents when attendance marked
   - Fetches existing attendance for date to allow edits
   - Updates homework date provider when attendance saved

2. **Marks Entry** (`features/tests/marks_entry_screen.dart`)
   - Enter student marks with NG (Not Given) checkbox per student
   - Auto-calculates ranks based on scores
   - Supports single tests and series topics
   - Subject + topic + max marks customizable
   - Sends parent notifications on submission

3. **Test Management** (`features/tests/test_hub_screen.dart`)
   - **Single Test Tab**: Create one-off tests (name, subject, topic, max marks, date)
   - **Test Series Tab**: Create series with multiple topics
   - Auto-open marks entry after series/test creation
   - Manages test metadata and topics

4. **Homework Entry** (`features/homework/homework_teacher_screen.dart`)
   - Title + description per class
   - Assigned by: teacher email
   - Date-keyed (defaults to today)
   - Simple CRUD in Firestore

5. **Weekly Schedule Editor** (`features/schedule/schedule_admin_screen.dart`)
   - Edit 2 time slots per day (Monday–Sunday)
   - Fields: Start time, End time, Subject, What to bring
   - Per-class schedule management

6. **Announcements/Notices** (`features/announcements/announcements_staff_screen.dart`)
   - Post institute-wide or class-specific notices
   - Types: info, holiday
   - Title + body required
   - Auto-filters by classLevel in student view

### UI/Navigation
- **Staff Home Page** with quick links to bulk upload & promote
- **Navigation Drawer**: Collects all tools in ordered list
- Role-aware menu rendering

---

## 3. MODELS & TYPE SYSTEM

### Key Models

#### AppUser (lib/models/user_model.dart)
```dart
class AppUser {
  final String id;              // lowercase email (staff) or Firestore ID (student)
  final UserRole role;          // admin, teacher, student
  final String displayName;
  final String? email;
  final String? rollNumber;
  final int? studentClass;      // CBSE class 5–10
  
  bool get isStaff => role == UserRole.admin || role == UserRole.teacher;
  String? get studentClassLabel => 'Class $studentClass';
}

enum UserRole { admin, teacher, student }
```

#### StudentPerformance (lib/models/performance_model.dart)
```dart
class StudentPerformance {
  final String studentRoll;
  final String studentName;
  final int classLevel;
  
  int totalTestsGiven = 0;
  int totalClassesAttended = 0;
  int totalClassesHeld = 0;
  double averageMarks = 0.0;
  double highestMarks = 0.0;
  double lowestMarks = 0.0;
  PerformanceCategory category;  // topper, average, needsImprovement
  
  double get attendancePercentage =>
    (totalClassesAttended / totalClassesHeld * 100).clamp(0.0, 100.0);
}

enum PerformanceCategory { topper, average, needsImprovement }
```

#### Supporting Models
- **StudentListItem**: Roll, name, docId, totalFees, remainingFees (for list views)
- **LeaderboardRow**: Roll, rank, score, isNg (for ranking displays)
- **TodoItem**: Local Hive-stored task with id, title, done (student to-do)
- **MarkEntryConfig**: Wraps test metadata for marks entry screen

#### StudentClassLevels
```dart
abstract final class StudentClassLevels {
  static const int min = 5;    // Class 5
  static const int max = 10;   // Class 10
}
```

---

## 4. CURRENT IMPLEMENTATION STATUS

### ✅ IMPLEMENTED FEATURES

#### Fees Module
- **Data Fields**: total_fees, remaining_fees (auto-calculated)
- **Student View**: `StudentFeesScreen` shows personal fees in read-only mode
- **Admin/Teacher View**: `StudentDetailScreen` allows edit total & paid amounts
- **Auto-Calculation**: remaining = total - paid (clamped)
- **Fee Reset**: Triggered on class promotion
- **Limitations**: No payment history, no invoice generation, no payment gateway

#### Tests Module
- **Single Tests**: Custom name, subject, topic, max marks
- **Test Series**: Grouped tests by topic for syllabus coverage
- **Marks Entry**: Per-roll input with NG support
- **Auto-Ranking**: Handles ties; NG students get rank 0
- **Leaderboard**: EnhancedLeaderboardScreen with tabbed views
- **Performance Tracking**: StudentPerformanceScreen with line chart & subject averages
- **Mark History**: Per-student test history across all tests
- **Series Ranking**: Overall % average per student within series
- **Limitations**: No time zone handling, no partial series tracking

#### Attendance Module
- **Daily Recording**: Class-level attendance per date
- **Holiday Support**: Mark as holiday with optional message
- **Marks Present/Absent**: Boolean per roll
- **Attendance History**: Fetch by class or month
- **Parent Notification**: Sends SMS/push on save (via stub)
- **Limitations**: No leave tracking, no late arrivals, no subject-wise attendance

#### Schedule Module
- **Weekly Template**: 2 slots × 7 days per class
- **Slot Metadata**: Start time, end time, subject, materials to bring
- **Student View**: Read-only schedule display (`StudentScheduleScreen`)
- **Admin Edit**: Full CRUD on schedule (`ScheduleAdminScreen`)
- **View Options**: Card-based and advanced (tabbed) views
- **Limitations**: No repeating schedule rules, no room/venue tracking

#### Homework Module
- **Assignment Entry**: Title + description per class
- **Date Keying**: Homework shown for specific date
- **Teacher Assignment**: Email of assigner stored
- **Student View**: Homework filtered by class + date
- **Limitations**: No due date, no submission tracking, no attachments

#### Announcements/Notices
- **Types**: info, holiday (extensible)
- **Scope**: Institute-wide or per-class
- **Display**: Real-time streaming (limit 40 latest)
- **Student Notifications**: Push/SMS on postings

---

## 5. NAVIGATION & ROUTING

### Route Map (app.dart)
```
/                    → SplashScreen (init check)
/login               → LoginScreen (role selection)
/dashboard           → MainShellScreen (role-aware body)

Direct Routes (can be accessed by name):
/staff-home          → StaffHomePage
/student-home        → StudentHomePage
/attendance-teacher  → TeacherAttendanceScreen
/attendance-student  → StudentAttendanceScreen
/student-fees        → StudentFeesScreen
/academic            → AcademicHubScreen
/tests               → TestHubScreen
/leaderboard         → LeaderboardScreen
/enhanced-leaderboard → EnhancedLeaderboardScreen
/performance         → StudentPerformanceScreen
/schedule-admin      → ScheduleAdminScreen
/schedule-student    → StudentScheduleScreen
/advanced-schedule   → AdvancedScheduleScreen
/homework-teacher    → HomeworkTeacherScreen
/homework-student    → HomeworkStudentScreen
/announcements-staff → AnnouncementsStaffScreen
/announcements-student → AnnouncementsStudentScreen
/updates-center      → UpdatesCenterScreen
/todo                → StudentTodoScreen
/about               → AboutScreen
```

### Navigation Structure
- **MainShellScreen**: Tab-based navigation (9 tabs for staff, 9 for students)
- **Drawer**: Scrollable list with role-aware icons
- **Bottom-up Routes**: Some screens pushed via `Navigator.push()` (e.g., MarksEntryScreen)
- **Page Transitions**: Custom transitions in `core/navigation/page_transitions.dart`
- **Global Navigator Key**: For showing dialogs from anywhere

---

## 6. STATE MANAGEMENT (Riverpod)

### Providers

```dart
// Repository
final erpRepositoryProvider = Provider<ErpRepository>
  → Returns singleton ErpRepository instance

// Auth
final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>
  → Manages login/logout, persists to SharedPreferences

// Homework Date
final currentHomeworkDateProvider = NotifierProvider<CurrentHomeworkDateNotifier, DateTime>
  → Tracks date for homework display, updates on attendance mark
```

### Data Flow
1. UI → `ref.read/watch(provider)`
2. Provider → Repository method call
3. Repository → Firestore query
4. Stream results → UI rebuild via Riverpod

---

## 7. AUTHENTICATION & AUTHORIZATION

### Auth System (features/auth/auth_service.dart)

**Staff Login:**
- Hardcoded credentials in `AppConfig` (MVP approach)
- 2 Admins + 3 Teachers defined
- Email validation (case-insensitive)
- Password plaintext match

**Student Login:**
- Roll number + Class Level + Password
- Queries Firestore `students` collection
- Supports multiple field name formats (rollNumber, Roll Number)
- Stores AppUser in SharedPreferences

**Credentials** (in app_config.dart):
```
Admins:
  yogesh.udawat@mentorclasses.in : Yogesh@Mentor2026
  desk.admin@mentorclasses.in : MentorDesk@2026

Teachers:
  vinita.sharma@mentorclasses.in : TeacherVinita@2026
  aadesh.dangi@mentorclasses.in : TeacherAadesh@2026
  neha.joshi@mentorclasses.in : TeacherNeha@2026
```

### Authorization
- **Role Checks**: `user.isStaff`, `user.role == UserRole.admin`
- **UI Filtering**: Admin-only screens shown conditionally
- **Data Access**: Repository methods called after role validation

---

## 8. LOCAL PERSISTENCE

### Hive Setup (core/hive/hive_setup.dart)
- **Todo Box** (`kTodoBoxName`): Stores JSON-serialized TodoItem list per student
- **Future**: Offline sync, caching attendance snapshots

### SharedPreferences
- **Auth Token**: Persists `AppUser` after login
- **Session**: Auto-hydrate on app launch

---

## 9. NOTIFICATIONS & INTEGRATIONS

### Parent Notifications (core/notifications/)
- **Stub Implementation**: `parentNotificationStub.dart`
- **Triggers**:
  - Attendance marked → "Absent rolls: X, Y, Z"
  - Test marks published → "Subject · Test Name (date)"
  - Holiday declared → Message + date
  - Test scheduled → Name + date + time
- **Placeholder**: Expects SMS/Firebase Cloud Messaging integration

### Remote Config
- **Update Check**: Async version checking at startup
- **Config Fields**: latest_version, download_url
- **Non-blocking**: Fails silently if no internet

### Emergency Contact
- **Field**: Stored in student document
- **Use Case**: For critical notifications

---

## 10. THEME & UI COMPONENTS

### Theme System (core/theme/app_theme.dart)
- **Colors**: 
  - Deep Blue (#2C5282 approx), Dark variant
  - Light Grey, Warning Orange
  - White, Black
- **Typography**: Google Fonts (Poppins)
- **Light/Dark Modes**: Material 3 theme

### Custom Widgets
- **MentorGlassCard**: Glassmorphism card with borders
- **MentorFooter**: Branding footer
- **MentorGlassButton**: Styled button (unused in main flow)

### UI Patterns
- Single/Multi-select dropdowns
- TextFields with validation hints
- Circular avatars for user icons
- Card-based layouts
- Tab bars for categorization
- Real-time list views with StreamBuilder

---

## 11. PERFORMANCE CONSIDERATIONS & OPTIMIZATION AREAS

### Current Performance Issues

1. **Firestore Query Inefficiencies**
   - `fetchTestsForClass()` fetches ALL tests per class (no pagination)
   - `fetchAttendanceForClass()` retrieves entire month, filters client-side
   - No indexes defined → sequential scans
   - ❌ **Impact**: Slow for large classes (100+ students, 50+ tests)

2. **Missing Pagination**
   - Announcements: Hardcoded limit(40)
   - Leaderboard: No lazy loading
   - Test history: Loads all at once
   - ❌ **Impact**: UI jank on slow network

3. **Image & Asset Loading**
   - No asset caching strategy
   - No lazy image loading
   - ❌ **Impact**: Initial load time slow

4. **State Management Inefficiency**
   - Full list rebuilds on any change
   - No selective rebuilds
   - ❌ **Impact**: Rebuilds unrelated widgets

5. **Excel Parsing**
   - Loads entire file into memory (`withData: true`)
   - ❌ **Impact**: Crashes on large files (1000+ rows)

### Recommended Optimizations

#### Database
- [ ] Add Firestore indexes for:
  - `test_marks` (classLevel, createdAt DESC)
  - `attendance` (classLevel, dateKey)
  - `homework` (classLevel, dateKey)
- [ ] Implement pagination with `limit()` + `startAfter()`
- [ ] Use batch reads for multiple documents

#### UI
- [ ] Lazy-load test history (paginate on scroll)
- [ ] Paginate announcements feed
- [ ] Cache frequently accessed leaderboards
- [ ] Use `const` constructors aggressively

#### State
- [ ] Split large providers into smaller, focused ones
- [ ] Use `select()` for partial rebuilds
- [ ] Memoize expensive computations

#### Asset Loading
- [ ] Use `cached_network_image` for profile pictures
- [ ] Compress images before upload
- [ ] Lazy-load tab contents

---

## 12. MISSING/INCOMPLETE FEATURES

### Critical Gaps
- [ ] **Payment Gateway**: No actual fee payment processing (only tracking)
- [ ] **SMS/Push Notifications**: Only stubs; needs Firebase Cloud Messaging + SMS provider
- [ ] **Student/Parent Portal**: No web version
- [ ] **Time Zone Support**: Hard-coded to server time
- [ ] **Offline Mode**: No sync when reconnected
- [ ] **File Attachments**: Homework/announcements can't have PDFs/images

### Nice-to-Have
- [ ] **Syllabus Tracker**: Academic Hub shows placeholders, no real content
- [ ] **Counselor Notes**: No logged observations per student
- [ ] **Parent Portal**: No separate parent app
- [ ] **API Docs**: No backend API documentation
- [ ] **Unit Tests**: No test coverage
- [ ] **Error Tracking**: No Sentry/Crashlytics integration

### Data Features
- [ ] **Leave Management**: No formal sick/casual leave
- [ ] **Late Arrivals**: Attendance only has present/absent
- [ ] **Grade Cutoffs**: No automatic grade assignment
- [ ] **Behavior Points**: No conduct tracking
- [ ] **Co-curricular Activities**: No sports/club participation
- [ ] **Medical Records**: No health/vaccination info

---

## 13. SECURITY CONCERNS

### High Priority
1. **Plaintext Credentials**: Staff passwords in code (app_config.dart)
   - 🔴 **Action**: Move to Firebase Auth or remote config
2. **No API Authentication**: Firestore security rules not shown
   - 🔴 **Action**: Verify Firestore rules enforce role-based access
3. **Student Passwords in Firestore**: Plain or unencrypted
   - 🔴 **Action**: Hash with bcrypt; use Firebase Auth
4. **No Rate Limiting**: Attendance/marks upload unprotected
   - 🔴 **Action**: Add Firestore rules with write rate limits

### Medium Priority
5. **No Audit Logs**: Who changed what/when not tracked
6. **No Activity Logging**: Teacher actions not recorded
7. **Data Encryption**: No encryption at rest or in transit (HTTPS is Firebase default)

---

## 14. DEPENDENCIES

### Core Packages
| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^3.3.1 | State management |
| cloud_firestore | ^6.2.0 | Database |
| firebase_core | ^4.6.0 | Firebase init |
| hive_flutter | ^1.1.0 | Local storage |
| shared_preferences | ^2.2.0 | Session persistence |
| google_fonts | ^8.0.2 | Typography |
| fl_chart | ^1.2.0 | Charts (performance) |
| excel | ^4.0.6 | Excel parsing |
| file_picker | ^11.0.1 | File selection |
| lottie | ^3.3.0 | Animations |
| url_launcher | ^6.3.1 | External links |
| intl | (implicit) | Localization/formatting |

### Minimum SDK
- Dart: ^3.11.4
- Flutter: Latest stable compatible

---

## 15. EXTENSION POINTS

### Adding New Features

#### Payment Module
1. Create `features/payments/` with screens
2. Add `payments` collection to Firestore
3. Extend `StudentDetailScreen` with payment history
4. Integrate payment gateway (Razorpay, PayU, etc.)

#### SMS Notifications
1. Implement `core/notifications/sms_service.dart`
2. Replace stub calls with real integration
3. Add phone number validation in student upload

#### Syllabus Tracker
1. Create `features/academic/syllabus_tracker_screen.dart`
2. Add `chapters` + `topics` collections
3. Add checklist per student + teacher
4. Link to test series topics

#### Counselor/Staff Notes
1. Add `staff_notes` collection with roll + date + note
2. Create staff-only "Student Insights" screen
3. Add note templates (behavior, academic, health)

#### Parent Portal
1. Duplicate student screens for parent view
2. Add `parents` collection (email → student mapping)
3. Parent login via student roll + parent password
4. Read-only access to fees, attendance, marks, announcements

---

## 16. BUILD INFO

- **App Name**: MENTOR CLASSES ERP
- **Current Version**: 1.0.0+1
- **Flutter Channels**: Android, iOS, Web, Windows, Linux, macOS (scaffolding exists)
- **Firebase Project**: Connected via `firebase_options.dart`
- **Min SDK**: Android API 21+ (from gradle)

---

## 17. QUICK START FOR EXTENSION

### To Add a New Module:

1. **Create Feature Folder**
   ```
   lib/features/module_name/
     ├── module_screen.dart       (main UI)
     ├── module_list_item.dart    (optional: list tile)
     └── constants.dart           (optional: defaults)
   ```

2. **Add to Navigation** (app.dart routes + shell tabs):
   ```dart
   '/module': (context) => const ModuleScreen(),
   ```

3. **Add Firestore Collection** (if needed):
   ```dart
   CollectionReference<Map<String, dynamic>> get _modules => 
     _db.collection('modules');
   ```

4. **Create Repository Methods** (erp_repository.dart):
   ```dart
   Future<void> saveModule(...) async { ... }
   Stream<QuerySnapshot> watchModules(...) { ... }
   ```

5. **Reference in UI** via `ref.read(erpRepositoryProvider)`:
   ```dart
   await ref.read(erpRepositoryProvider).saveModule(...);
   ```

---

## 18. FILE STRUCTURE SUMMARY

```
lib/
├── main.dart                     # Entry, update check
├── app.dart                      # Route definitions
├── firebase_options.dart         # Firebase config
│
├── models/
│   ├── user_model.dart          # AppUser, UserRole
│   └── performance_model.dart   # StudentPerformance
│
├── data/
│   ├── erp_repository.dart      # Firestore logic (primary)
│   ├── erp_providers.dart       # Riverpod providers
│   └── ncert_topics_placeholder.dart  # Mock data
│
├── core/
│   ├── app_config.dart          # Hardcoded credentials (MVP)
│   ├── theme/app_theme.dart     # Colors, fonts
│   ├── widgets/                 # Custom components
│   ├── hive/hive_setup.dart     # Local DB init
│   ├── notifications/           # Stubs for SMS/push
│   └── navigation/page_transitions.dart  # Route animations
│
└── features/
    ├── auth/                    # Login (no signup UI)
    ├── splash/                  # Startup screen
    ├── home/                    # Staff + Student home
    ├── shell/                   # Tab-based shell
    ├── attendance/              # Marking + view
    ├── tests/                   # Marks, leaderboard, performance
    ├── schedule/                # Timetable views
    ├── homework/                # Assignment entry + view
    ├── student/                 # Fees, detail screens
    ├── announcements/           # Notices
    ├── academic/                # Study resources (placeholder)
    ├── todo/                    # Local task list (Hive)
    ├── staff/                   # Admin tools (bulk upload, promote)
    └── about/                   # App info

Test: widget_test.dart
```

---

## SUMMARY TABLE: Implementation Timeline

| Feature | Status | Collection | Key Screens | Data Model | Gaps |
|---------|--------|-----------|------------|-----------|------|
| Auth | ✅ DONE | — | LoginScreen | AppUser | No signup UI; hardcoded credentials |
| Attendance | ✅ DONE | attendance | Teacher/Student view | bool per roll | No leaves, lates, export |
| Tests & Marks | ✅ DONE | test_marks, test_series | Hub, Leaderboard, Performance | Score, Rank, NG | No time zone, partial series |
| Fees | ⚠️ PARTIAL | students | Detail, StudentFeesScreen | total, remaining | No payment gateway, no history |
| Schedule | ✅ DONE | schedules | Admin edit, Student view | 2 slots/day | No room booking, repeats |
| Homework | ✅ DONE | homework | Teacher assign, Student view | title, description | No due date, submission tracking |
| Announcements | ✅ DONE | announcements | Staff create, Student view | title, body, type | No attachment, no read receipts |
| Student Records | ⚠️ PARTIAL | students | Bulk upload, Detail edit | Name, class, contact | No excel export, limited fields |
| Performance Tracking | ✅ DONE | test_marks | Charts, Averages | Marks, Rank, Subjects | No percentile, no predictions |
| Parent Notifications | ⚠️ PARTIAL | — | — | SMS/Push stubs | Not integrated; SMS provider TBD |
| Todo (Student) | ✅ DONE | Hive (local) | TodoScreen | title, done | Not synced to server |
| Academic Hub | ❌ TODO | — | AcademicHubScreen | PDF URLs (mock) | No real content, no tracking |

---

**Generated**: April 8, 2026  
**Project Lead**: Harshit Dhakad  
**Founder**: Yogesh Udawat
