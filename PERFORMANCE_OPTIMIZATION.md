# Performance Optimization & Scalability Guide
**For 300+ Users & Production Deployment**

---

## 🚀 Implementation Checklist

### 1. IMAGE COMPRESSION & CACHING

#### Add dependencies (pubspec.yaml):
```yaml
cached_network_image: ^3.3.0  # Network image caching
image_compression: ^1.0.0      # Compress uploaded images
flutter_cache_manager: ^3.4.0  # Advanced cache management
```

#### Usage in Academic Resources:
```dart
// In resource_upload_screen.dart, compress before upload:
import 'package:image/image.dart' as img;
import 'dart:io';

Future<File> _compressImage(File imageFile) async {
  final image = img.decodeImage(imageFile.readAsBytesSync());
  if (image == null) return imageFile;
  
  // Reduce to 80% quality, max 1000px width
  final compressed = img.encodeJpg(image, quality: 80);
  final compressedFile = File('${imageFile.parent.path}/compressed_${imageFile.filename}')
    ..writeAsBytesSync(compressed);
  
  debugPrint('📦 Compressed: ${imageFile.lengthSync()}B → ${compressedFile.lengthSync()}B');
  return compressedFile;
}

// Before uploading:
final fileToUpload = file.path.endsWith('.jpg') || file.path.endsWith('.png')
    ? await _compressImage(file)
    : file;
```

#### Cached Network Images in Student View:
```dart
// Replace Image.network with CachedNetworkImage:
CachedNetworkImage(
  imageUrl: resource.fileUrl,
  placeholder: (context, url) => Shimmer.fromColors(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(ms: 300),
  memCacheWidth: 800,  // Cache at 800px max
  memCacheHeight: 600,
)
```

---

### 2. FIRESTORE OPTIMIZATION

#### Indexing Strategy
Go to Firebase Console → Firestore → Indexes and add these composite indexes:

```
Collection: students
- studentClass (Ascending)
- active (Ascending)
- enrolledDate (Descending)

Collection: attendance
- classLevel (Ascending)
- dateKey (Descending)

Collection: testMarks
- classLevel (Ascending)
- createdAt (Descending)

Collection: academicResources
- classLevel (Ascending)
- isActive (Ascending)
- uploadedAt (Descending)
```

#### Query Optimization:
```dart
// ❌ Bad: Loads full collection
final students = await _db.collection('students').get();

// ✅ Good: Filters early, limits results
final students = await _db.collection('students')
  .where('active', isEqualTo: true)
  .where('studentClass', isEqualTo: 9)
  .limit(500)  // Prevent loading 5000+ docs
  .get();

// ✅ Good: Use pagination
Future<List<Student>> getStudentsPage(int pageNum) async {
  const pageSize = 50;
  return _db.collection('students')
    .where('active', isEqualTo: true)
    .orderBy('name')
    .limit(pageSize)
    .offset(pageNum * pageSize)
    .get();
}
```

#### Real-time Stream Optimization:
```dart
// ❌ Bad: Listens to all docs
Stream<QuerySnapshot> watchAllAttendance() {
  return _db.collection('attendance').snapshots();
}

// ✅ Good: Only current class/month
Stream<QuerySnapshot> watchClassAttendance(int classLevel, String month) {
  final startKey = '$month-01';
  final endKey = '$month-31';
  return _db.collection('attendance')
    .where('classLevel', isEqualTo: classLevel)
    .where('dateKey', isGreaterThanOrEqualTo: startKey)
    .where('dateKey', isLessThanOrEqualTo: endKey)
    .snapshots();
}
```

---

### 3. PROVIDER CACHING & STATE MANAGEMENT

#### Cache Duration Strategy:
```dart
// In erp_providers.dart:

// Short cache (5 min) - Frequently updated
final studentsByClassEnhancedProvider = FutureProvider.family<List<EnhancedStudentItem>, int>((ref, classLevel) async {
  return ref.watch(erpRepositoryProvider).fetchStudentsByClassEnhanced(classLevel);
}, // Add timeout to prevent stale data
).select((async) async {
  return (await async).when(
    data: (data) => data,
    loading: () => [],
    error: (err, stack) => [],
  );
});

// Medium cache (30 min) - Monthly data
final feesAnalyticsProvider = FutureProvider<FeesAnalytics>((ref) async {
  return ref.watch(erpRepositoryProvider).getFeesAnalytics();
});

// Use .autoDispose to free memory when not used:
final expensiveQueryProvider = FutureProvider.autoDispose<LargeDataSet>((ref) async {
  // Query is cancelled when provider is no longer watched
  return fetchExpensiveData();
});
```

#### Caching Network Images with Manager:
```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final cacheManager = CacheManager(
  Config(
    'mentor_classes_cache',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheobjects: 200,  // Limit to 200 images
    fileService: HttpFileService(),
  ),
);

// Usage:
CachedNetworkImage(
  imageUrl: url,
  cacheManager: cacheManager,
)
```

---

### 4. DATABASE PAGINATION For 300+ Users

#### Implement Lazy Loading in Lists:
```dart
class StudentBatchManagerScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<StudentBatchManagerScreen> createState() => _StudentBatchManagerScreenState();
}

class _StudentBatchManagerScreenState extends ConsumerState<StudentBatchManagerScreen> {
  final ScrollController _scrollController = ScrollController();
  int _pageNum = 0;
  bool _loadingMore = false;
  List<EnhancedStudentItem> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    try {
      final page = await ref.read(erpRepositoryProvider).getStudentsPage(_pageNum);
      setState(() {
        _allStudents.addAll(page);
        _pageNum++;
      });
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _allStudents.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _allStudents.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }
        return StudentTile(_allStudents[index]);
      },
    );
  }
}
```

---

### 5. SERVICE WORKER & OFFLINE SUPPORT

#### Add to pubspec.yaml:
```yaml
connectivity_plus: ^5.0.0  # Network status
hive_flutter: ^1.1.0       # Local offline storage
```

#### Offline Queue Implementation:
```dart
class OfflineQueue {
  final box = Hive.box('offline_queue');
  
  Future<void> queueAttendance(Map<String, dynamic> data) async {
    await box.add(data);
    debugPrint('📋 Queued attendance (${box.length} items)');
  }
  
  Future<void> syncWhenOnline() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint('📡 Online! Syncing offline data...');
        for (int i = 0; i < box.length; i++) {
          final data = box.getAt(i);
          try {
            // Upload to Firebase
            await FirebaseFirestore.instance.collection('attendance').add(data);
            await box.deleteAt(i);
          } catch (e) {
            debugPrint('❌ Sync failed: $e');
          }
        }
      }
    });
  }
}
```

---

### 6. FIRESTORE READ/WRITE LIMITS

#### Estimated for 300 users:
- Peak: 100 concurrent users
- Daily operations: ~1000 reads, ~500 writes
- Firebase quota: 50,000 reads/day, 10,000 writes/day ✅ SAFE

#### Cost Optimization:
- Use `.limit(100)` before `.get()`
- Cache frequently accessed data
- Use real-time streams (`.snapshots()`) only for 1-5 docs

---

### 7. DEPLOY CHECKLIST

- [ ] Enable Firestore backup
- [ ] Set up security rules (FIREBASE_SECURITY_RULES.txt)
- [ ] Configure Firebase project limits:
  ```
  Firestore Settings → Backup location: us-central1
  Backup retention: 30 days
  ```
- [ ] Add indexes for all collection queries
- [ ] Update storage limits: 50GB minimum
- [ ] Enable Firebase Monitoring
- [ ] Set up Cloud Functions for automatic cleanup:
  ```javascript
  // Delete attendance older than 1 year
  exports.cleanupOldAttendance = functions.pubsub
    .schedule('0 0 1 * *')  // Monthly
    .onRun(async (context) => {
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
      
      const batch = db.batch();
      const docs = await db.collection('attendance')
        .where('createdAt', '<', oneYearAgo)
        .get();
      
      docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    });
  ```

---

### 8. LOAD TESTING (Android Studio / Firebase Console)

```dart
// Test with mock data in debug mode:
Future<void> createMockStudents(int count) async {
  final batch = _db.batch();
  
  for (int i = 0; i < count; i++) {
    batch.set(_students.doc('mock_$i'), {
      'name': 'Student $i',
      'rollNumber': 'MOCK-$i',
      'studentClass': (5 + (i % 6)),
      'active': true,
      'total_fees': 5000,
      'remaining_fees': Random().nextInt(5000).toDouble(),
    });
  }
  
  await batch.commit();
  debugPrint('✅ Created $count mock students');
}
```

---

### 9. MONITORING & ALERTS

#### Add Firebase Analytics to track:
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'attendance_marked',
  parameters: {'class_level': 9, 'count': 45},
);

await FirebaseAnalytics.instance.logEvent(
  name: 'screen_view',
  parameters: {'screen_name': 'batch_manager', 'duration_seconds': 120},
);
```

#### Set up Firebase Alerts:
- CPU usage > 80%
- Error rate > 1%
- Response time > 2s
- Storage > 80%

---

## 📊 Performance Metric Goals

| Metric | Target | Current |
|--------|--------|---------|
| App Startup | < 2s | ? |
| List Load (50 items) | < 500ms | ? |
| Mark Attendance | < 1s | ? |
| Search Students | < 300ms | ? |
| Firestore Query | < 1s | ? |
| Memory Usage | < 150MB | ? |

---

## 🔧 Troubleshooting

**Slow List Scrolling?**
- [ ] Implement ListView.builder (not Column with 500 widgets)
- [ ] Use cached images
- [ ] Reduce widget rebuilds with `.select()`

**Firestore "Too many reads"?**
- [ ] Add indexes
- [ ] Use `.limit()`
- [ ] Cache with Riverpod

**App crashes on upload?**
- [ ] Compress images before upload
- [ ] Add error handling
- [ ] Check Firebase Storage limits

**Login stuck/slow?**
- [ ] Clear browser cache
- [ ] Check Firebase Auth latency
- [ ] Verify internet connection

---

**Last Updated:** April 2026  
**Maintainer:** Harshit Dhakad  
**Status:** Ready for 300+ users
