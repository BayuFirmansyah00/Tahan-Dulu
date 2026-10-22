import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/onboarding_data.dart';
import 'package:tahan_dulu/data/models/recurring_expense.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';

/// Onboarding kosong untuk empty state akun.
class _EmptyOnboardingRepo implements OnboardingRepository {
  OnboardingData? _data = const OnboardingData(
    monthlyIncome: 0,
    salaryDay: 1,
    financialInstruments: [],
    recurringExpenses: [],
  );

  @override
  OnboardingData? getSalarySetup() => _data;

  @override
  Future<OnboardingData> saveSalarySetup({
    required double monthlyIncome,
    required int salaryDay,
  }) async {
    _data = _data!
        .copyWith(monthlyIncome: monthlyIncome, salaryDay: salaryDay);
    return _data!;
  }

  @override
  OnboardingData? getOnboardingData() => _data;

  @override
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  ) async {
    _data = _data!.copyWith(financialInstruments: instruments);
    return _data!;
  }

  @override
  Future<OnboardingData> saveExpenses(
    List<RecurringExpense> expenses,
  ) async {
    _data = _data!.copyWith(recurringExpenses: expenses);
    return _data!;
  }

  @override
  Future<OnboardingData> saveGoal(FinancialGoal goal) async {
    _data = _data!.copyWith(financialGoal: goal);
    return _data!;
  }

  @override
  Future<FinancialInstrument> addInstrument(
    FinancialInstrument instrument,
  ) async {
    _data = _data!.copyWith(
      financialInstruments: [..._data!.financialInstruments, instrument],
    );
    return instrument;
  }

  @override
  Future<FinancialInstrument> updateInstrument(
    FinancialInstrument instrument,
  ) async {
    _data = _data!.copyWith(
      financialInstruments: [
        for (final e in _data!.financialInstruments)
          if (e.id == instrument.id) instrument else e,
      ],
    );
    return instrument;
  }

  @override
  Future<void> removeInstrument(String id) async {
    _data = _data!.copyWith(
      financialInstruments: [
        for (final e in _data!.financialInstruments) if (e.id != id) e,
      ],
    );
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> onboarding -> plan -> dashboard -> Rekening.
Future<void> _pumpToAccounts(WidgetTester tester) async {
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
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.doneButton),
  );
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.startAppButton));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.totalBalanceTitle));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.accountsTitle), findsOneWidget);
}

void main() {
  testWidgets('Accounts list shows total and three accounts', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);

    expect(find.text(AppStrings.totalBalanceLabel), findsOneWidget);
    expect(find.text('Rp6.500.000'), findsOneWidget);
    expect(find.text('BCA'), findsWidgets);
    expect(find.text('Bank Jago'), findsOneWidget);
    expect(find.text('Rp1.000.000'), findsOneWidget);
    expect(find.text(AppStrings.addAccount), findsOneWidget);
  });

  testWidgets('Empty accounts shows empty state', (
    WidgetTester tester,
  ) async {
    // Langsung ke layar akun: rantai onboarding butuh instrumen.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            _EmptyOnboardingRepo(),
          ),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyAccounts), findsOneWidget);
    expect(find.text(AppStrings.totalBalanceLabel), findsOneWidget);
  });

  testWidgets('Add account flow validates and saves', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);

    await _tapVisible(tester, find.text(AppStrings.addAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addAccountTitle), findsOneWidget);

    // Submit kosong -> error.
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveAccount),
    );
    expect(find.text(AppStrings.accountNameRequired), findsOneWidget);

    // Isi lalu simpan.
    await _tapVisible(tester, find.text(AppStrings.typeEWallet));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'DANA');
    await tester.enterText(fields.at(2), '750000');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveAccount),
    );
    await tester.pumpAndSettle();

    expect(find.text('DANA'), findsOneWidget);
    expect(find.text('Rp750.000'), findsOneWidget);
    expect(find.text('Rp7.250.000'), findsOneWidget);
  });

  testWidgets('Detail shows balance and empty transactions', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);

    await _tapVisible(tester, find.text('BCA').first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.currentBalanceLabel), findsOneWidget);
    expect(find.text('Rp5.000.000'), findsWidgets);
    expect(find.text('BCA'), findsWidgets);
    expect(
      find.text(AppStrings.emptyAccountTransactions),
      findsOneWidget,
    );
    expect(find.text(AppStrings.transferAction), findsOneWidget);
    expect(find.text(AppStrings.editAccountTitle), findsWidgets);
  });

  testWidgets('Transfer button informs upcoming feature', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);
    await _tapVisible(tester, find.text('BCA').first);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text(AppStrings.transferAction));
    await tester.pump();

    expect(find.text(AppStrings.transferComingSoon), findsOneWidget);
  });

  testWidgets('Edit preserves values and saves changes', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);
    await _tapVisible(tester, find.text('BCA').first);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    // Nilai awal dipertahankan (nama + institusi seed BCA).
    expect(find.text('BCA'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BCA Utama');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveChanges),
    );
    await tester.pumpAndSettle();

    expect(find.text('BCA Utama'), findsOneWidget);
  });

  testWidgets('Delete unreferenced account with confirmation', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);
    await _tapVisible(tester, find.text('Bank Jago'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.deleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteAccount));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteAccountTitle), findsOneWidget);
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.deleteAccount),
      ),
    );
    // Majukan waktu eksplisit melewati mock latency setelah dialog
    // (future dialog selesai via microtask; settle saja bisa berpacu).
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Kembali di daftar tanpa Jago; total berkurang 1jt.
    expect(find.text(AppStrings.accountsTitle), findsOneWidget);
    expect(find.text('Bank Jago'), findsNothing);
    expect(find.text('Rp5.500.000'), findsOneWidget);
  });

  testWidgets('See all opens history filtered by account', (
    WidgetTester tester,
  ) async {
    await _pumpToAccounts(tester);
    await _tapVisible(tester, find.text('BCA').first);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text(AppStrings.seeAllAction));
    await tester.pumpAndSettle();

    expect(find.textContaining('Akun:'), findsOneWidget);
  });
}
