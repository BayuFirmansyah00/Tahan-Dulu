import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// No.3 — Input Gaji Bulanan (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pumpToSalary(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  // Login mock.
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'bayu@email.com');
  await tester.enterText(fields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();
  // Setelah login langsung di No.3 (halaman intro dihapus).
  expect(find.text(AppStrings.salaryTitle), findsOneWidget);
}

void main() {
  testWidgets('Salary screen shows step, title, illustration, questions', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    expect(find.text(AppStrings.onboardingStep), findsOneWidget);
    expect(find.text(AppStrings.salarySubtitle), findsOneWidget);
    expect(find.text(AppStrings.salaryIncomeQuestion), findsOneWidget);
    expect(find.text(AppStrings.salaryDayQuestion), findsOneWidget);
    expect(find.text(AppStrings.salaryHelper), findsOneWidget);
    expect(find.text(AppStrings.continueButton), findsOneWidget);
  });

  testWidgets('Default demo income Rp5.000.000 is shown', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);
    expect(find.text('5.000.000'), findsOneWidget);
  });

  testWidgets('User can change income and rupiah formats correctly', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, '10000000');
    await tester.pump();

    expect(find.text('10.000.000'), findsOneWidget);
  });

  testWidgets('User can select day 1 then continue to No.4', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    await _tapVisible(tester, find.text('1'));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);
  });

  testWidgets('User can select day 28', (WidgetTester tester) async {
    await _pumpToSalary(tester);

    await _tapVisible(tester, find.text('28'));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);
  });

  testWidgets('Lainnya opens dialog and custom day is applied', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    await _tapVisible(tester, find.text(AppStrings.salaryCustomDay));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.salaryCustomDayTitle), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '15');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.save));
    await tester.pumpAndSettle();

    // Chip keempat kini menampilkan tanggal custom.
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Custom day validation rejects out-of-range date', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    await _tapVisible(tester, find.text(AppStrings.salaryCustomDay));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '32');
    await tester.pump();
    await tester.tap(find.text(AppStrings.save));
    await tester.pump();

    expect(find.text(AppStrings.customDayInvalid), findsOneWidget);
    // Dialog tetap terbuka, belum ke No.4.
    expect(find.text(AppStrings.salaryCustomDayTitle), findsOneWidget);
    expect(find.text(AppStrings.instrumentsTitle), findsNothing);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
  });

  testWidgets('Empty income shows error and disables Lanjut', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, '');
    await tester.pump();

    expect(find.text(AppStrings.incomeRequired), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    expect(button.onPressed, isNull);
    expect(find.text(AppStrings.instrumentsTitle), findsNothing);
  });

  testWidgets('Lanjut with edited data goes to No.4 instruments', (
    WidgetTester tester,
  ) async {
    await _pumpToSalary(tester);

    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, '7500000');
    await tester.pump();
    expect(find.text('7.500.000'), findsOneWidget);

    await _tapVisible(tester, find.text('1'));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);
  });
}
