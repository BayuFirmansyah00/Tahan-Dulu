import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/onboarding_data.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';

/// Repo kosong untuk empty state (tanpa data palsu).
class _EmptyTransactionRepo implements TransactionRepository {
  final List<AppTransaction> items = [];

  @override
  Future<List<AppTransaction>> getRecentTransactions() async => List.of(items);

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    items.add(transaction);
    return transaction;
  }

  @override
  Future<AppTransaction> getTransactionById(String id) async =>
      items.firstWhere((t) => t.id == id);

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    int? instrumentId,
    int? perPage,
  }) async => List.of(items);

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async {
    final idx = items.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) items[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    items.removeWhere((t) => t.id == id);
  }
}

/// Onboarding tanpa instrumen untuk state akun-tidak-tersedia.
class _NoAccountOnboardingRepo implements OnboardingRepository {
  OnboardingData? _data = const OnboardingData(
    monthlyIncome: 5000000,
    salaryDay: 25,
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
    _data = _data!.copyWith(monthlyIncome: monthlyIncome, salaryDay: salaryDay);
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
  Future<OnboardingData> saveExpenses(expenses) async => _data!;

  @override
  Future<OnboardingData> saveGoal(goal) async => _data!;

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
        for (final e in _data!.financialInstruments)
          if (e.id != id) e,
      ],
    );
  }

  @override
  void clear() {
    _data = null;
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Judul AppBar (membedakan dari tombol berlabel sama di body).
Finder _appBarTitle(WidgetTester tester, String text) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(text));
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  // Login mock lalu selesaikan onboarding sampai dashboard.
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();
  // Langsung ke Dashboard; tutup popup onboarding bila muncul.
  if (find.text(AppStrings.onboardingPopupLater).evaluate().isNotEmpty) {
    await _tapVisible(tester, find.text(AppStrings.onboardingPopupLater));
    await tester.pumpAndSettle();
  }
  expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
}

Future<void> _tapNavTransactions(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.descendant(
      of: find.byType(DashboardBottomNav),
      matching: find.text(AppStrings.navTransactions),
    ),
  );
  await tester.pumpAndSettle();
  // Judul AppBar + label nav bawah memakai teks yang sama.
  expect(find.text(AppStrings.transactionsTitle), findsWidgets);
}

Future<void> _fillValidForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.ensureVisible(fields.at(0));
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(0), '41000');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.catFood));
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('BCA — Bank').last);
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(1), 'Ayam geprek');
  await tester.pump();
}

void main() {
  testWidgets('History renders seeds newest first', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);

    expect(find.text('Gaji Bulanan'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Top Up Investasi'), findsOneWidget);
    // Grup tanggal menurun: 5, 3, 1 Oktober.
    final top5 = tester.getTopLeft(find.text('5 Oktober 2026')).dy;
    final top3 = tester.getTopLeft(find.text('3 Oktober 2026')).dy;
    final top1 = tester.getTopLeft(find.text('1 Oktober 2026')).dy;
    expect(top5 < top3 && top3 < top1, isTrue);
  });

  testWidgets('Filters show only matching type', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);

    await _tapVisible(tester, find.text(AppStrings.filterIncome).first);
    expect(find.text('Gaji Bulanan'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsNothing);

    await _tapVisible(tester, find.text(AppStrings.filterExpense).first);
    expect(find.text('Gaji Bulanan'), findsNothing);
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Top Up Investasi'), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.filterAll).first);
    expect(find.text('Gaji Bulanan'), findsOneWidget);
  });

  testWidgets('Empty history shows empty state with add action', (
    WidgetTester tester,
  ) async {
    final repo = _EmptyTransactionRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
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
    await _tapVisible(tester, find.text(AppStrings.navTransactions));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyTransactions), findsOneWidget);
    await _tapVisible(tester, find.text(AppStrings.addTransaction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reviewAction), findsOneWidget);
  });

  testWidgets('Empty history shows local check illustration', (
    WidgetTester tester,
  ) async {
    final repo = _EmptyTransactionRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
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
    await _tapVisible(tester, find.text(AppStrings.navTransactions));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyTransactions), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                AppAssets.transactionEmptyCheck,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add button opens manual form', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);

    await _tapVisible(tester, find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.addTransaction), findsWidgets);
    expect(find.text(AppStrings.typeExpense), findsOneWidget);
    expect(find.text(AppStrings.amountLabel), findsOneWidget);
  });

  testWidgets('Empty submit shows validation errors', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);
    await _tapVisible(tester, find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
    );

    expect(find.text(AppStrings.amountRequired), findsOneWidget);
    expect(find.text(AppStrings.categoryRequired), findsOneWidget);
    expect(_appBarTitle(tester, AppStrings.reviewTitle), findsNothing);
  });

  testWidgets('No valid account shows guidance and blocks review', (
    WidgetTester tester,
  ) async {
    // Form standalone: tanpa rantai onboarding (instrumen kosong).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            _NoAccountOnboardingRepo(),
          ),
        ],
        child: const MaterialApp(home: TransactionFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noAccountTitle), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '50000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.catFood));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
    );

    expect(_appBarTitle(tester, AppStrings.reviewTitle), findsNothing);
  });

  testWidgets('Full flow: fill, review, edit preserves, save, history', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);
    await _tapVisible(tester, find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await _fillValidForm(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
    );
    await tester.pumpAndSettle();

    // Review menampilkan ringkasan (pengeluaran bertanda minus).
    expect(_appBarTitle(tester, AppStrings.reviewTitle), findsOneWidget);
    expect(find.text('-Rp41.000'), findsOneWidget);
    expect(find.text('Makanan'), findsWidgets);

    // Edit kembali tanpa kehilangan input.
    await _tapVisible(tester, find.text(AppStrings.editAction));
    await tester.pumpAndSettle();
    expect(find.text('41.000'), findsOneWidget);

    // Kembali ke review lalu simpan.
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveTransaction),
    );
    await tester.pumpAndSettle();

    // Sukses lalu lihat riwayat yang terperbarui.
    expect(find.text(AppStrings.successTitle), findsOneWidget);
    await _tapVisible(tester, find.text(AppStrings.seeTransactions));
    await tester.pumpAndSettle();
    expect(find.text('Makanan'), findsWidgets);
    expect(find.text('-Rp41.000'), findsOneWidget);
  });

  testWidgets('Bottom nav Catat opens record method and navigates to form', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);

    await _tapVisible(tester, find.text(AppStrings.navRecord));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Metode Catat'), findsOneWidget);
    await _tapVisible(tester, find.text('Input Manual'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reviewAction), findsOneWidget);
  });

  testWidgets('Back from form returns to history', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _tapNavTransactions(tester);
    await _tapVisible(tester, find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Judul AppBar + label nav bawah memakai teks yang sama.
    expect(find.text(AppStrings.transactionsTitle), findsWidgets);
  });
}
