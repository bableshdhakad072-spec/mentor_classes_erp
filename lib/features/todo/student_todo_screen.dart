import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/hive/hive_setup.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_service.dart';

class TodoItem {
  TodoItem({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  static TodoItem fromJson(Map<String, dynamic> j) => TodoItem(
        id: j['id'] as String,
        title: j['title'] as String,
        done: j['done'] == true,
      );
}

/// Local Hive task list per signed-in student.
class StudentTodoScreen extends ConsumerStatefulWidget {
  const StudentTodoScreen({super.key});

  @override
  ConsumerState<StudentTodoScreen> createState() => _StudentTodoScreenState();
}

class _StudentTodoScreenState extends ConsumerState<StudentTodoScreen> {
  final _input = TextEditingController();

  List<TodoItem> _load(Box<String> box, String userId) {
    final raw = box.get(userId);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(String userId, List<TodoItem> items) async {
    final box = Hive.box<String>(kTodoBoxName);
    await box.put(userId, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return Center(child: Text('Sign in to use tasks.', style: GoogleFonts.poppins()));
    }

    final box = Hive.box<String>(kTodoBoxName);
    final items = _load(box, user.id);

    void refreshLocal() => setState(() {});

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    labelText: 'New homework task',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.deepBlue),
                      onPressed: () async {
                        final t = _input.text.trim();
                        if (t.isEmpty) return;
                        final next = [...items, TodoItem(id: DateTime.now().microsecondsSinceEpoch.toString(), title: t)];
                        await _persist(user.id, next);
                        _input.clear();
                        refreshLocal();
                      },
                    ),
                  ),
                  onSubmitted: (t) async {
                    if (t.trim().isEmpty) return;
                    final next = [...items, TodoItem(id: DateTime.now().microsecondsSinceEpoch.toString(), title: t.trim())];
                    await _persist(user.id, next);
                    _input.clear();
                    refreshLocal();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No tasks yet. Add homework or revision items.',
                    style: GoogleFonts.poppins(color: Colors.grey.shade700),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final it = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: it.done,
                          onChanged: (v) async {
                            final next = [...items];
                            next[i] = TodoItem(id: it.id, title: it.title, done: v ?? false);
                            await _persist(user.id, next);
                            refreshLocal();
                          },
                        ),
                        title: Text(
                          it.title,
                          style: GoogleFonts.poppins(
                            decoration: it.done ? TextDecoration.lineThrough : null,
                            color: it.done ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            final next = [...items]..removeAt(i);
                            await _persist(user.id, next);
                            refreshLocal();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
