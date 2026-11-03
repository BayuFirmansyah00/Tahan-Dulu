import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Alur auth tahap 1 memakai MockAuthRepository (tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _enterVisible(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> _pumpToLogin(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  expect(find.text(AppStrings.loginHeadline), findsOneWidget);
}

Future<void> _fillLoginForm(WidgetTester tester) async {
  // Login memiliki 2 TextFormField: email lalu password.
  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(2));
  await _enterVisible(tester, fields.at(0), 'bayu@email.com');
  await _enterVisible(tester, fields.at(1), 'rahasia123');
  await tester.pump();
}

void main() {
  testWidgets('Login shows headline, google button, and daftar link', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);

    expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    expect(find.text(AppStrings.continueWithGoogle), findsOneWidget);
    expect(find.text(AppStrings.loginWithEmail), findsOneWidget);
    expect(find.text(AppStrings.noAccount), findsOneWidget);
  });

  testWidgets('Login empty submit shows validation errors', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);

    await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
    await tester.pump();

    expect(find.text(AppStrings.emailRequired), findsOneWidget);
    expect(find.text(AppStrings.passwordRequired), findsOneWidget);
    // Tetap di Login, tidak ke input gaji.
    expect(find.text(AppStrings.salaryTitle), findsNothing);
  });

  testWidgets('Login success navigates to Dashboard', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);
    await _fillLoginForm(tester);

    await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
  });

  testWidgets('Google sign-in success navigates to Dashboard', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);

    await _tapVisible(tester, find.text(AppStrings.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
  });

  testWidgets('Daftar link opens register screen', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);

    await _tapVisible(tester, find.text(AppStrings.registerLink));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.registerTitle), findsWidgets);
    expect(find.text(AppStrings.fullName), findsOneWidget);
    expect(find.text(AppStrings.confirmPassword), findsOneWidget);
  });

  testWidgets('Register password mismatch shows error', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);
    await _tapVisible(tester, find.text(AppStrings.registerLink));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await _enterVisible(tester, fields.at(0), 'Bayu Firmansyah');
    await _enterVisible(tester, fields.at(1), 'bayu@email.com');
    await _enterVisible(tester, fields.at(2), 'rahasia123');
    await _enterVisible(tester, fields.at(3), 'beda123');
    await tester.pump();

    await _tapVisible(tester, find.widgetWithText(ElevatedButton, AppStrings.registerButton));
    await tester.pump();

    expect(find.text(AppStrings.confirmMismatch), findsOneWidget);
    expect(find.text(AppStrings.salaryTitle), findsNothing);
  });

  testWidgets('Register success navigates to Onboarding Salary', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);
    await _tapVisible(tester, find.text(AppStrings.registerLink));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await _enterVisible(tester, fields.at(0), 'Bayu Firmansyah');
    await _enterVisible(tester, fields.at(1), 'bayu@email.com');
    await _enterVisible(tester, fields.at(2), 'rahasia123');
    await _enterVisible(tester, fields.at(3), 'rahasia123');
    await tester.pump();

    await _tapVisible(tester, find.widgetWithText(ElevatedButton, AppStrings.registerButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.salaryTitle), findsOneWidget);
  });

  testWidgets('Register Masuk link returns to login', (
    WidgetTester tester,
  ) async {
    await _pumpToLogin(tester);
    await _tapVisible(tester, find.text(AppStrings.registerLink));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.registerSubtitle), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.loginLink));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.loginHeadline), findsOneWidget);
  });
}
