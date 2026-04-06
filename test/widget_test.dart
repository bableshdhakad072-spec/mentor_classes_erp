import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentor_classes/app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('Login screen shows MENTOR CLASSES branding', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MentorClassesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('MENTOR CLASSES'), findsOneWidget);
    expect(find.textContaining('Vidisha'), findsOneWidget);
  });
}
