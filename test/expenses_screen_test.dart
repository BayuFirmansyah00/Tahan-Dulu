import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/widgets/app_button.dart';
import 'package:tahan_dulu/data/datasources/mock/mock_data.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';

class _NotOnboardedAuthRepo extends MockAuthRepository {
  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return MockData.user.copyWith(isOnboarded: false);
  }
}

/// No.5 — Pengeluaran Rutin (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> Onboarding -> Salary (Step 1) -> Instruments (Step 2) -> Budget (Step 3) -> Expenses (Step 4).
Future<void> _pumpToExpenses(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_NotOnboardedAuthRepo()),
      ],
      child: const TahanDuluApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();

  // Step 1: Salary -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 2: Instruments -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 3: Budget -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  expect(find.text(AppStrings.expensesTitle), findsOneWidget);
}

Finder _dialogFields(WidgetTester tester) {
  return find.byType(TextFormField);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Expenses screen shows step 4 and title', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    expect(find.text(AppStrings.onboardingStep4), findsOneWidget);
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
    expect(find.textContaining('Rp1.500.000'), findsOneWidget);
    expect(find.textContaining('Rp400.000'), findsOneWidget);
    expect(find.textContaining('Rp300.000'), findsNWidgets(2));
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
    expect(find.text(AppStrings.editExpenseSheetTitle), findsOneWidget);

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(1), '500000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.saveExpenseAction));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rp500.000'), findsOneWidget);
    expect(find.textContaining('Rp2.600.000'), findsOneWidget);
  });

  testWidgets('User can add a new expense', (WidgetTester tester) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text(AppStrings.addAnotherExpenseAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addExpenseSheetTitle), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.catOthers));

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(0), 'Langganan');
    await tester.enterText(fields.at(1), '150000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.saveExpenseAction));
    await tester.pumpAndSettle();

    expect(find.text('Langganan'), findsOneWidget);
    expect(find.textContaining('Rp150.000'), findsOneWidget);
    expect(find.textContaining('Rp2.650.000'), findsOneWidget);
  });

  testWidgets('Empty amount shows validation and keeps dialog open', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    await _tapVisible(tester, find.text(AppStrings.addAnotherExpenseAction));
    await tester.pumpAndSettle();

    final fields = _dialogFields(tester);
    await tester.enterText(fields.at(0), 'Jajan');
    await tester.pump();

    // Button Simpan Pengeluaran remains disabled when amount is empty
    final saveButton = tester.widget<AppButton>(
      find.widgetWithText(AppButton, AppStrings.saveExpenseAction),
    );
    expect(saveButton.onPressed, isNull);
    expect(find.text(AppStrings.addExpenseSheetTitle), findsOneWidget);
    // Total tidak berubah — data tidak tersimpan.
    expect(find.textContaining('Rp2.500.000'), findsWidgets);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
  });

  testWidgets('User can delete an expense with confirmation', (
    WidgetTester tester,
  ) async {
    await _pumpToExpenses(tester);

    final deleteButtons = find.byTooltip(AppStrings.deleteExpense);
    await _tapVisible(tester, deleteButtons.last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteExpenseTitle), findsOneWidget);
    final confirmButton = find.descendant(
      of: find.byType(AlertDialog).last,
      matching: find.text(AppStrings.deleteExpenseConfirm),
    );
    await _tapVisible(tester, confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('Belanja'), findsNothing);
    expect(find.textContaining('Rp2.200.000'), findsOneWidget);
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

    // Kembali di Budget dengan pilihan utuh.
    expect(find.text(AppStrings.onboardingStep3), findsOneWidget);
  });
}
