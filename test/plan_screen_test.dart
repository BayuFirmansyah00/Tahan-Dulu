import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Layar ringkasan rencana (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> salary -> instruments -> expenses -> goals -> Selesai.
Future<void> _pumpToPlan(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();

  for (var i = 0; i < 3; i++) {
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();
  }
  expect(find.text(AppStrings.goalsTitle), findsOneWidget);

  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.doneButton),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.planTitle), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Plan shows income and canonical allocation', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text(AppStrings.planSubtitle), findsOneWidget);
    expect(find.text(AppStrings.monthlyIncomeLabel), findsOneWidget);
    expect(find.text('Rp5.000.000'), findsWidgets);
    expect(find.text('Rp2.500.000'), findsOneWidget);
    expect(find.text('Rp800.000'), findsOneWidget);
    expect(find.text('Rp500.000'), findsWidgets);
    expect(find.text('Rp1.200.000'), findsOneWidget);
  });

  testWidgets('Safe per day card matches design', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text(AppStrings.safeToday), findsOneWidget);
    expect(find.text('Rp40.000'), findsOneWidget);
    expect(find.text(AppStrings.safeTodayDesc), findsOneWidget);
  });

  testWidgets('Goal card shows monthly investment target', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text('Target Investasi'), findsOneWidget);
    expect(find.text('Rp500.000 ${AppStrings.perMonth}'), findsOneWidget);
    expect(find.text(AppStrings.planAdjustable), findsOneWidget);
  });

  testWidgets('Start button goes to dashboard', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    await _tapVisible(tester, find.text(AppStrings.startAppButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    expect(find.text('Bayu'), findsOneWidget);
  });
}
