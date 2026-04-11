import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/erp_providers.dart';
import '../auth/auth_service.dart';

class AdvancedScheduleScreen extends ConsumerStatefulWidget {
  const AdvancedScheduleScreen({super.key});

  @override
  ConsumerState<AdvancedScheduleScreen> createState() => _AdvancedScheduleScreenState();
}

class _AdvancedScheduleScreenState extends ConsumerState<AdvancedScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Management', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Class Schedule'),
            Tab(text: 'Test Schedule'),
            Tab(text: 'Holidays'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClassScheduleTab(),
          TestScheduleTab(),
          HolidayTab(),
        ],
      ),
    );
  }
}

class ClassScheduleTab extends ConsumerStatefulWidget {
  const ClassScheduleTab({super.key});

  @override
  ConsumerState<ClassScheduleTab> createState() => _ClassScheduleTabState();
}

class _ClassScheduleTabState extends ConsumerState<ClassScheduleTab> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  int _selectedClass = 9;

  Future<void> _addClass() async {
    if (_subjectController.text.isEmpty || _timeController.text.isEmpty) return;

    final repo = ref.read(erpRepositoryProvider);
    final scaffoldContext = context;
    
    await repo.addClassSchedule(
      classLevel: _selectedClass,
      subject: _subjectController.text,
      time: _timeController.text,
      teacher: _teacherController.text,
      room: _roomController.text,
    );

    _subjectController.clear();
    _timeController.clear();
    _teacherController.clear();
    _roomController.clear();

    if (scaffoldContext.mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Class added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Class', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedClass,
            decoration: const InputDecoration(labelText: 'Class'),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Class ${i + 1}'))),
            onChanged: (value) => setState(() => _selectedClass = value!),
          ),
          TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject')),
          TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'Time')),
          TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Teacher')),
          TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Room')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _addClass, child: const Text('Add Class')),
          const SizedBox(height: 32),
          Expanded(child: _ClassList(selectedClass: _selectedClass)),
        ],
      ),
    );
  }
}

class _ClassList extends ConsumerWidget {
  final int selectedClass;

  const _ClassList({required this.selectedClass});

  Future<void> _editSchedule(BuildContext context, WidgetRef ref, DocumentSnapshot doc, Map<String, dynamic> data) async {
    final subjectController = TextEditingController(text: data['subject'] ?? '');
    final timeController = TextEditingController(text: data['time'] ?? '');
    final teacherController = TextEditingController(text: data['teacher'] ?? '');
    final roomController = TextEditingController(text: data['room'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time')),
            TextField(controller: teacherController, decoration: const InputDecoration(labelText: 'Teacher')),
            TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Room')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      await doc.reference.update({
        'subject': subjectController.text,
        'time': timeController.text,
        'teacher': teacherController.text,
        'room': roomController.text,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule updated')));
      }
    }
  }

  Future<void> _deleteSchedule(BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isStaff = user?.isStaff ?? false;
    final repo = ref.watch(erpRepositoryProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: repo.getClassSchedules(selectedClass),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['subject'] ?? ''),
                subtitle: Text('${data['time']} - ${data['teacher']} (${data['room']})'),
                trailing: isStaff ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editSchedule(context, ref, docs[index], data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteSchedule(context, docs[index]),
                    ),
                  ],
                ) : null,
              ),
            );
          },
        );
      },
    );
  }
}

class TestScheduleTab extends ConsumerStatefulWidget {
  const TestScheduleTab({super.key});

  @override
  ConsumerState<TestScheduleTab> createState() => _TestScheduleTabState();
}

class _TestScheduleTabState extends ConsumerState<TestScheduleTab> {
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _syllabusController = TextEditingController();
  final TextEditingController _maxMarksController = TextEditingController();
  int _selectedClass = 9;

  Future<void> _scheduleTest() async {
    if (_testNameController.text.isEmpty || _dateController.text.isEmpty) return;

    final repo = ref.read(erpRepositoryProvider);
    final scaffoldContext = context;
    
    await repo.scheduleTest(
      classLevel: _selectedClass,
      testName: _testNameController.text,
      date: _dateController.text,
      time: _timeController.text,
      syllabus: _syllabusController.text,
      maxMarks: double.tryParse(_maxMarksController.text) ?? 100,
    );

    // Send notification
    // TODO: Implement notification sending

    _testNameController.clear();
    _dateController.clear();
    _timeController.clear();
    _syllabusController.clear();
    _maxMarksController.clear();

    if (scaffoldContext.mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Test scheduled successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule New Test', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedClass,
            decoration: const InputDecoration(labelText: 'Class'),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Class ${i + 1}'))),
            onChanged: (value) => setState(() => _selectedClass = value!),
          ),
          TextField(controller: _testNameController, decoration: const InputDecoration(labelText: 'Test Name')),
          TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'Time')),
          TextField(controller: _syllabusController, decoration: const InputDecoration(labelText: 'Syllabus')),
          TextField(controller: _maxMarksController, decoration: const InputDecoration(labelText: 'Max Marks')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _scheduleTest, child: const Text('Schedule Test')),
          const SizedBox(height: 32),
          Expanded(child: _TestList(selectedClass: _selectedClass)),
        ],
      ),
    );
  }
}

class HolidayTab extends ConsumerStatefulWidget {
  const HolidayTab({super.key});

  @override
  ConsumerState<HolidayTab> createState() => _HolidayTabState();
}

class _HolidayTabState extends ConsumerState<HolidayTab> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _selectedClass = 9;

  Future<void> _addHoliday() async {
    if (_dateController.text.isEmpty || _messageController.text.isEmpty) return;

    final repo = ref.read(erpRepositoryProvider);
    final scaffoldContext = context;
    
    await repo.addHoliday(
      classLevel: _selectedClass,
      date: _dateController.text,
      message: _messageController.text,
    );

    _dateController.clear();
    _messageController.clear();

    if (scaffoldContext.mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Holiday added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Declare Holiday', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedClass,
            decoration: const InputDecoration(labelText: 'Class'),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Class ${i + 1}'))),
            onChanged: (value) => setState(() => _selectedClass = value!),
          ),
          TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          TextField(controller: _messageController, decoration: const InputDecoration(labelText: 'Holiday Message')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _addHoliday, child: const Text('Declare Holiday')),
          const SizedBox(height: 32),
          Expanded(child: _HolidayList(selectedClass: _selectedClass)),
        ],
      ),
    );
  }
}

class _HolidayList extends ConsumerWidget {
  final int selectedClass;

  const _HolidayList({required this.selectedClass});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(erpRepositoryProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: repo.getHolidays(selectedClass),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['message'] ?? ''),
                subtitle: Text(data['date'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}

class _TestList extends ConsumerWidget {
  final int selectedClass;

  const _TestList({required this.selectedClass});

  Future<void> _editTestSchedule(BuildContext context, WidgetRef ref, DocumentSnapshot doc, Map<String, dynamic> data) async {
    final testNameController = TextEditingController(text: data['testName'] ?? '');
    final dateController = TextEditingController(text: data['date'] ?? '');
    final timeController = TextEditingController(text: data['time'] ?? '');
    final syllabusController = TextEditingController(text: data['syllabus'] ?? '');
    final maxMarksController = TextEditingController(text: (data['maxMarks'] ?? 100).toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Test Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: testNameController, decoration: const InputDecoration(labelText: 'Test Name')),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time')),
              TextField(controller: syllabusController, decoration: const InputDecoration(labelText: 'Syllabus')),
              TextField(controller: maxMarksController, decoration: const InputDecoration(labelText: 'Max Marks')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      await doc.reference.update({
        'testName': testNameController.text,
        'date': dateController.text,
        'time': timeController.text,
        'syllabus': syllabusController.text,
        'maxMarks': double.tryParse(maxMarksController.text) ?? 100,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test schedule updated')));
      }
    }
  }

  Future<void> _deleteTestSchedule(BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Schedule'),
        content: const Text('Are you sure you want to delete this test schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test schedule deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isStaff = user?.isStaff ?? false;
    final repo = ref.watch(erpRepositoryProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: repo.getTestSchedules(selectedClass),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['testName'] ?? ''),
                subtitle: Text('${data['date']} at ${data['time']}'),
                trailing: isStaff ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editTestSchedule(context, ref, docs[index], data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteTestSchedule(context, docs[index]),
                    ),
                  ],
                ) : null,
              ),
            );
          },
        );
      },
    );
  }
}