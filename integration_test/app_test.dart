import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quickfire_student/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Test', () {
    testWidgets('Verify successful login with live credentials', (tester) async {
      // 1. Start the app
      app.main();
      await tester.pumpAndSettle();

      // 2. Verify Login Screen is displayed
      expect(find.text('Quickfire'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // 3. Enter credentials
      final regField = find.byType(TextField).first;
      final passField = find.byType(TextField).last;

      await tester.enterText(regField, 'KIU/2019/2001');
      await tester.enterText(passField, 'uems@2026');
      await tester.pumpAndSettle();

      // 4. Tap the Login button
      final loginButtonLabel = find.text('Login to Dashboard');
      expect(loginButtonLabel, findsOneWidget);
      
      await tester.tap(loginButtonLabel);
      
      // 5. Wait for login to complete and navigate
      // Use a timeout since network calls are involved
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 6. Verify we are on the Home Screen
      // The Home screen has a "Welcome back," text (line 382 of home_screen.dart)
      expect(find.textContaining('Welcome back'), findsOneWidget);
      // It also shows the Dashboard title in the AppBar (if it's the default view)
    });
  });
}
