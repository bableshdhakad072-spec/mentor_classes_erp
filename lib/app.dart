import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/auth_home_screen.dart';

class MentorClassesApp extends StatelessWidget {
  const MentorClassesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MENTOR CLASSES ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthHomeScreen(),
    );
  }
}
