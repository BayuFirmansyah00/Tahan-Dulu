import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// No.5 — Pengeluaran Rutin (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> salary -> Lanjut -> instruments -> Lanjut -> expenses.
Future<void> _pumpToExpenses(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.salaryTitle), findsOneWidget);

  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);

  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.expensesTitle), findsOneWidget);
}

Finder _dialogFields(WidgetTester tester) {
  return find.descendant(
    of: find.byType(AlertDialog).first,
    matching: find.byType(TextFormField),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Expenses screen shows step 3 and title', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    expect(find.text(AppStrings.onboardingStep3), findsOneWidget);
    expect(find.text(AppStrings.expensesSubtitle), findsOneWidget);
  });

  testWidgets('Default expenses are shown in rupiah format', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    expect(find.text('Kebutuhan sehari-hari'), findsOneWidget);
    expect(find.text('Transportasi'), findsWidgets);
    expect(find.text('Tagihan'), findsWidgets);
    expect(find.text('Belanja'), findsWidgets);
    expect(find.text('Rp1.500.000'), findsOneWidget);
    expect(find.text('Rp400.000'), findsOneWidget);
    expect(find.text('Rp300.000'), findsNWidgets(2));
  });

  testWidgets('Total is calculated correctly', (WidgetTester tester) async {
    await _pumpToExpenses(tester);

    expect(find.text(AppStrings.expenseTotal), findsOneWidget);
    expect(find.text('Rp2.500.000 ${AppStrings.perMonth}'), findsOneWidget);
    expect(find.text(AppStrings.expenseSummaryInfo), findsOneWidget);
  });

  testWidgets('User can edit an expense amount', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text('Transportasi').first);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.editExpenseTitle), findsOneWidget);

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(1), '500000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Rp500.000'), findsOneWidget);
    expect(find.text('Rp2.600.000 ${AppStrings.perMonth}'), findsOneWidget);
  });

  testWidgets('User can add a new expense', (WidgetTester tester) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text(AppStrings.addExpense));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addExpenseTitle), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.catOthers));

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(0), 'Langganan');
    await tester.enterText(fields.at(1), '150000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Langganan'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text('Rp2.650.000 ${AppStrings.perMonth}'), findsOneWidget);
  });

  testWidgets('Empty amount shows validation and keeps dialog open', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text(AppStrings.addExpense));
    await tester.pumpAndSettle();

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(0), 'Jajan');
    await tester.pump();
    await tester.tap(find.text(AppStrings.save));
    await tester.pump();

    expect(find.text(AppStrings.expenseAmountRequired), findsOneWidget);
    expect(find.text(AppStrings.addExpenseTitle), findsOneWidget);
    // Total tidak berubah — data tidak tersimpan.
    expect(find.text('Rp2.500.000 ${AppStrings.perMonth}'), findsWidgets);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
  });

  testWidgets('User can delete an expense with confirmation', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text('Belanja').first);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.deleteExpense));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteExpenseTitle), findsOneWidget);
    final confirmButton = find.descendant(
      of: find.byType(AlertDialog).last,
      matching: find.text(AppStrings.deleteExpenseConfirm),
    );
    await _tapVisible(tester, confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('Belanja'), findsNothing);
    expect(find.text('Rp2.200.000 ${AppStrings.perMonth}'), findsOneWidget);
  });

  testWidgets('Lanjut saves expenses and goes to No.7', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.goalsTitle), findsWidgets);
  });

  testWidgets('Back returns to instruments without losing data', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Kembali di No.4 dengan pilihan utuh (BCA terpilih).
    expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);
    expect(find.text('BCA'), findsOneWidget);
  });
}
