import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/utils/currency_formatter.dart';
import 'package:tahan_dulu/core/utils/finance_math.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/providers/reports_providers.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> onboarding -> dashboard (pola test transaksi existing).
Future<void> _pumpApp(WidgetTester tester) async {
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
}

Future<void> _openForm(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.descendant(
      of: find.byType(DashboardBottomNav),
      matching: find.text(AppStrings.navTransactions),
    ),
  );
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byIcon(Icons.add).first);
  await tester.pumpAndSettle();
}

/// Isi form valid + biaya; kembalikan draf untuk assertion lanjutan.
Future<void> _fillWithFee(
  WidgetTester tester, {
  required String amount,
  required String fee,
  bool income = false,
}) async {
  if (income) {
    await _tapVisible(tester, find.text(AppStrings.typeIncome));
  }
  final fields = find.byType(TextFormField);
  await tester.ensureVisible(fields.at(0));
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(0), amount);
  await tester.pump();
  await _tapVisible(
    tester,
    find.text(income ? AppStrings.catSalary : AppStrings.catFood),
  );
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('BCA — Bank').last);
  await tester.pumpAndSettle();
  final feeField = find.byType(TextFormField).at(2);
  await tester.ensureVisible(feeField);
  await tester.pumpAndSettle();
  await tester.enterText(feeField, fee);
  await tester.pump();
}

void main() {
  group('Tahap 17: aturan biaya (R7)', () {
    test('pengeluaran: keluar = nominal + biaya', () {
      expect(expenseOutflow(amount: 100000, fee: 2500), 102500);
      expect(
        netTransactionAmount(isExpense: true, amount: 100000, fee: 2500),
        102500,
      );
    });

    test('pemasukan: bersih = nominal - biaya', () {
      expect(incomeInflow(amount: 100000, fee: 2500), 97500);
      expect(
        netTransactionAmount(isExpense: false, amount: 100000, fee: 2500),
        97500,
      );
    });

    test('fee Rp0 identik dengan sebelum Tahap 17', () {
      expect(expenseOutflow(amount: 100000, fee: 0), 100000);
      expect(incomeInflow(amount: 100000, fee: 0), 100000);
    });

    test('model default fee 0 untuk data lama', () {
      final tx = AppTransaction(
        id: 'x',
        title: 'T',
        amount: 50000,
        type: TransactionType.expense,
        date: DateTime(2026, 1, 1),
      );
      expect(tx.fee, 0);
    });

    test('draf menolak bersih non-positif', () {
      const draft = TransactionDraft(
        type: TransactionType.income,
        amount: 100000,
        fee: 100000,
      );
      expect(draft.isNetValid, isFalse);
      const ok = TransactionDraft(
        type: TransactionType.income,
        amount: 100000,
        fee: 2500,
      );
      expect(ok.isNetValid, isTrue);
      expect(ok.netAmount, 97500);
    });

    test('setter menolak negatif dan membatasi digit', () {
      final container = _container();
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setFee(-500);
      expect(container.read(transactionFormProvider).fee, 0);
      notifier.setFeeText('');
      expect(container.read(transactionFormProvider).fee, 0);
      notifier.setFee(1e20);
      expect(
        container.read(transactionFormProvider).fee,
        TransactionFormController.maxFee,
      );
    });
  });

  group('Tahap 17: simpan dan agregat', () {
    // ignore: no_leading_underscores_for_local_identifiers
    Future<bool> _saveExpense(
      ProviderContainer container, {
      double amount = 100000,
      double fee = 0,
    }) {
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.expense);
      notifier.setAmount(amount);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('inst-bca');
      notifier.setDate(DateTime.now());
      notifier.setFee(fee);
      return notifier.save();
    }

    test('tanpa biaya tersimpan seperti sebelumnya', () async {
      final container = _container();
      expect(await _saveExpense(container), isTrue);
      final items =
          await container.read(transactionRepositoryProvider).getRecentTransactions();
      final saved = items.last;
      expect(saved.amount, 100000);
      expect(saved.fee, 0);
    });

    test('pengeluaran berbiaya menyimpan nilai bersih sekali', () async {
      final container = _container();
      expect(await _saveExpense(container, fee: 2500), isTrue);
      final items =
          await container.read(transactionRepositoryProvider).getRecentTransactions();
      final saved = items.last;
      expect(saved.amount, 102500);
      expect(saved.fee, 2500);
      // Tanpa transaksi biaya kedua.
      expect(
        items.where((e) => e.title.contains('Biaya')).length,
        0,
      );
    });

    test('pemasukan berbiaya menyimpan bersih; fee >= nominal ditolak',
        () async {
      final container = _container();
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.income);
      notifier.setAmount(100000);
      notifier.setCategory(TransactionCategory.salary);
      notifier.setAccount('inst-bca');
      notifier.setDate(DateTime.now());
      notifier.setFee(2500);
      expect(await notifier.save(), isTrue);
      final items =
          await container.read(transactionRepositoryProvider).getRecentTransactions();
      expect(items.last.amount, 97500);

      notifier.setFee(100000);
      expect(await notifier.save(), isFalse);
    });

    test('saldo akun konsisten tanpa double-count', () async {
      final container = _container();
      await _saveExpense(container, fee: 2500);
      final overviews =
          await container.refresh(accountsOverviewProvider.future);
      final bca = overviews.firstWhere((e) => e.account.id == 'inst-bca');
      expect(bca.currentBalance, 5000000 - 102500);
      final total = await container.read(accountsTotalProvider.future);
      expect(
        total,
        overviews.fold<double>(0, (s, e) => s + e.currentBalance),
      );
    });

    test('dashboard bereaksi dengan nilai bersih', () async {
      final container = _container();
      final before =
          await container.read(dashboardDataProvider.future);
      await _saveExpense(container, fee: 2500);
      final after =
          await container.refresh(dashboardDataProvider.future);
      expect(
        after.actualMonthExpense,
        before.actualMonthExpense + 102500,
      );
      expect(after.totalBalance, before.totalBalance - 102500);
    });

    test('laporan memakai nilai bersih per kategori', () async {
      final container = _container();
      await _saveExpense(container, fee: 2500);
      final now = DateTime.now();
      final report = await container.refresh(
        monthlyReportProvider(DateTime(now.year, now.month)).future,
      );
      final food = report.categories
          .firstWhere((e) => e.label == 'Makanan');
      // Kategori hanya menampung transaksi baru (seed memakai label lain).
      expect(food.amount, greaterThanOrEqualTo(102500));
      expect(report.expense, greaterThanOrEqualTo(102500));
    });

    test('double-submit tetap diproteksi', () async {
      final container = _container();
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.expense);
      notifier.setAmount(50000);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('inst-bca');
      notifier.setDate(DateTime.now());
      notifier.setFee(1000);
      final results = await Future.wait([notifier.save(), notifier.save()]);
      expect(results.where((e) => e).length, 1);
      final items =
          await container.read(transactionRepositoryProvider).getRecentTransactions();
      expect(items.where((e) => e.amount == 51000).length, 1);
    });
  });

  group('Tahap 17: alur UI form-review-simpan-riwayat', () {
    testWidgets('form menampilkan total live', (tester) async {
      await _pumpApp(tester);
      await _openForm(tester);

      expect(find.text(AppStrings.feeLabel), findsOneWidget);
      expect(find.text(AppStrings.feeTotalOut), findsOneWidget);
      await _fillWithFee(tester, amount: '100000', fee: '2500');
      expect(
        find.text('-${CurrencyFormatter.formatCompact(102500)}'),
        findsWidgets,
      );
    });

    testWidgets('alur lengkap dengan biaya', (tester) async {
      await _pumpApp(tester);
      await _openForm(tester);
      await _fillWithFee(tester, amount: '100000', fee: '2500');

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
      );
      await tester.pumpAndSettle();
      // Review: nominal, biaya, total.
      expect(find.text(AppStrings.reviewFee), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.formatCompact(100000)),
        findsWidgets,
      );
      expect(
        find.text(CurrencyFormatter.formatCompact(2500)),
        findsWidgets,
      );
      expect(
        find.text('-${CurrencyFormatter.formatCompact(102500)}'),
        findsWidgets,
      );

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.saveTransaction),
      );
      await tester.pumpAndSettle();
      // Sukses memakai hasil yang sama + baris biaya.
      expect(find.text(AppStrings.successTitle), findsOneWidget);
      expect(find.text(AppStrings.reviewFee), findsOneWidget);
      expect(
        find.text('-${CurrencyFormatter.formatCompact(102500)}'),
        findsWidgets,
      );

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.seeTransactions),
      );
      await tester.pumpAndSettle();
      // Riwayat menampilkan nilai bersih.
      expect(
        find.text('-${CurrencyFormatter.formatCompact(102500)}'),
        findsWidgets,
      );
    });

    testWidgets('biaya nol tidak meramaikan review', (tester) async {
      await _pumpApp(tester);
      await _openForm(tester);
      await _fillWithFee(tester, amount: '50000', fee: '');

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reviewFee), findsNothing);
      expect(
        find.text(CurrencyFormatter.formatCompact(50000)),
        findsWidgets,
      );
    });

    testWidgets('biaya melebihi pemasukan diblokir di form', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _openForm(tester);
      await _fillWithFee(
        tester,
        amount: '100000',
        fee: '100000',
        income: true,
      );

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.feeExceedsIncome), findsOneWidget);
      // Tetap di form (tidak pindah ke review).
      expect(find.text(AppStrings.addTransaction), findsWidgets);
    });
  });
}
