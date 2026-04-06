import 'package:hive_flutter/hive_flutter.dart';

const String kTodoBoxName = 'mentor_student_todos';

Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(kTodoBoxName);
}
