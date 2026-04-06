import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../shell/main_shell_screen.dart';

/// Routes to login or the role-aware [MainShellScreen].
class AuthHomeScreen extends ConsumerWidget {
  const AuthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const LoginScreen();
    }
    return const MainShellScreen();
  }
}
