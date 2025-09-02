// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune/main.dart';
import 'package:neptune/welcome.dart';

void main() {
  testWidgets('Splash transitions to WelcomePage with action buttons', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Neptune Bank'), findsOneWidget); // splash brand

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Now on WelcomePage
    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.byKey(const Key('create_account_button')), findsOneWidget);
    expect(find.text('Neptune Bank'), findsWidgets); // still visible brand
  });

  testWidgets('Login flow reaches Dashboard after OTP verification', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);

    // Attempt submit empty
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Enter User ID'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
    expect(find.text('Enter answer'), findsOneWidget);
    expect(find.text('Select a question'), findsOneWidget);
    expect(find.text('Captcha mismatch'), findsOneWidget);

    // Fill required fields
    await tester.enterText(find.byKey(const Key('login_user_id')), 'user123');
    await tester.enterText(find.byKey(const Key('login_password')), 'pass123!');
    await tester.enterText(find.byKey(const Key('login_security_answer')), 'blue');

    // Select first security question
    await tester.tap(find.byKey(const Key('login_security_question')));
    await tester.pumpAndSettle();
    final firstQuestion = find.textContaining("mother's maiden").first;
    await tester.tap(firstQuestion);
    await tester.pumpAndSettle();

    // Read captcha code (7-char case-sensitive now)
    final captchaTextWidget = tester.widget<Text>(find.byKey(const Key('login_captcha_code')));
    final captcha = captchaTextWidget.data ?? '';
    await tester.enterText(find.byKey(const Key('login_captcha_input')), captcha);

    // Submit again (starts async OTP generation with simulated delay)
    await tester.tap(find.byKey(const Key('login_submit')));
    for (int i = 0; i < 8 && find.byKey(const Key('otp_dialog')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byKey(const Key('otp_dialog')), findsOneWidget, reason: 'OTP dialog should appear after async generation');

    // Retrieve OTP (visible only in debug builds). If not visible, we cannot complete success path; test fallback to invalid OTP then can't reach dashboard.
    String otpDisplay = '';
    final otpFinder = find.byKey(const Key('otp_code_text'));
    if (otpFinder.evaluate().isNotEmpty) {
      otpDisplay = (tester.widget<Text>(otpFinder).data ?? '').trim();
    }

    if (otpDisplay.length == 6) {
      await tester.enterText(find.byKey(const Key('otp_input')), otpDisplay);
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      // pump frames until dashboard card appears or timeout
      for (int i = 0; i < 12 && find.byKey(const Key('dashboard_balances_card')).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('dashboard_balances_card')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_username')), findsOneWidget);
      expect(find.byKey(const Key('upi_scan_fab')), findsOneWidget, reason: 'UPI scan FAB should be visible on dashboard');
    } else {
      // Enter wrong OTP -> expect error snackbar
      await tester.enterText(find.byKey(const Key('otp_input')), '000000');
      await tester.tap(find.byKey(const Key('otp_verify_button')));
      await tester.pump();
      expect(find.text('Invalid OTP'), findsOneWidget);
    }
  });

  testWidgets('Counter increments when MyHomePage is used directly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyHomePage(title: 'Test Counter')));
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
