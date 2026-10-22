import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/providers/reports_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';
import 'package:tahan_dulu/features/reports/export/report_export_data.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';

/// Skenario end-to-end Tahap 19 dengan data terkontrol pada container
/// segar (seed kanonis + mutasi eksplisit). Semua assertion memakai
/// DELTA sebelum/sesudah agar kebal terhadap seed warisan.
ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

Future<AppTransaction> _addTx(
  ProviderContainer c, {
  required double amount,
  required TransactionType type,
  required DateTime date,
  String accountId = 'inst-bca',
  double fee = 0,
  String category = 'Lainnya',
}) async {
  final tx = AppTransaction(
    id: 't19-${DateTime.now().microsecondsSinceEpoch}',
    title: 'Skenario 19',
    amount: amount,
    type: type,
    date: date,
    category: category,
    accountId: accountId,
    fee: fee,
  );
  await c.read(transactionRepositoryProvider).addTransaction(tx);
  c.invalidate(transactionsProvider);
  return tx;
}

void main() {
  group('Tahap 19: alur finansial ujung-ke-ujung', () {
    test('pemasukan/pengeluaran mengubah saldo per akun dan total (R1,R2)',
        () async {
      final c = _container();
      final now = DateTime.now();
      final beforeTotal =
          await c.read(accountsTotalProvider.future);
      expect(beforeTotal, 6500000);

      await _addTx(c,
          amount: 1000000, type: TransactionType.income, date: now);
      await _addTx(c,
          amount: 200000,
          type: TransactionType.expense,
          date: now,
          accountId: 'inst-jago');

      final overviews =
          await c.refresh(accountsOverviewProvider.future);
      final bca = overviews.firstWhere((e) => e.account.id == 'inst-bca');
      final jago =
          overviews.firstWhere((e) => e.account.id == 'inst-jago');
      expect(bca.currentBalance, 5000000 + 1000000);
      expect(jago.currentBalance, 1000000 - 200000);
      final total = await c.read(accountsTotalProvider.future);
      expect(total, beforeTotal + 1000000 - 200000);
      expect(
        total,
        overviews.fold<double>(0, (s, e) => s + e.currentBalance),
      );
    });

    test('fee dihitung sekali di saldo, dashboard, dan laporan', () async {
      final c = _container();
      final now = DateTime.now();
      final dashBefore = await c.read(dashboardDataProvider.future);
      final month = DateTime(now.year, now.month);
      final repBefore =
          await c.read(monthlyReportProvider(month).future);

      // Pengeluaran 100rb + fee 2,5rb: efek bersih 102.500 tepat sekali.
      await _addTx(c,
          amount: 102500,
          type: TransactionType.expense,
          date: now,
          fee: 2500,
          category: 'Makanan');

      final overviews =
          await c.refresh(accountsOverviewProvider.future);
      final bca = overviews.firstWhere((e) => e.account.id == 'inst-bca');
      expect(bca.currentBalance, 5000000 - 102500);

      final dashAfter =
          await c.refresh(dashboardDataProvider.future);
      expect(dashAfter.actualMonthExpense,
          dashBefore.actualMonthExpense + 102500);
      expect(dashAfter.totalBalance,
          dashBefore.totalBalance - 102500);

      final repAfter =
          await c.refresh(monthlyReportProvider(month).future);
      expect(repAfter.expense, repBefore.expense + 102500);
      expect(
        repAfter.categories.fold<double>(0, (s, e) => s + e.amount),
        repBefore.categories.fold<double>(0, (s, e) => s + e.amount) +
            102500,
      );
    });

    test('dashboard konsisten dengan laporan periode sama', () async {
      final c = _container();
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      await _addTx(c,
          amount: 50000, type: TransactionType.income, date: now);
      final dash = await c.refresh(dashboardDataProvider.future);
      final rep =
          await c.refresh(monthlyReportProvider(month).future);
      expect(dash.actualMonthIncome, rep.income);
      expect(dash.actualMonthExpense, rep.expense);
    });

    test('filter periode mengecualikan bulan lain', () async {
      final c = _container();
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final prev = DateTime(now.year, now.month - 1, 15);
      final dashBefore = await c.read(dashboardDataProvider.future);
      await _addTx(c,
          amount: 999000, type: TransactionType.expense, date: prev);
      final dashAfter =
          await c.refresh(dashboardDataProvider.future);
      expect(dashAfter.actualMonthExpense, dashBefore.actualMonthExpense);
      final rep =
          await c.refresh(monthlyReportProvider(month).future);
      final prevRep =
          await c.read(monthlyReportProvider(DateTime(prev.year, prev.month)).future);
      expect(prevRep.expense, greaterThanOrEqualTo(999000));
      expect(rep.categories.any((e) => e.amount == 999000), isFalse);
    });

    test('setoran target bukan pengeluaran dan tak ubah saldo', () async {
      final c = _container();
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final totalBefore =
          await c.read(accountsTotalProvider.future);
      final repBefore =
          await c.read(monthlyReportProvider(month).future);
      await c.read(goalRepositoryProvider).addDeposit(
            GoalDeposit(
              id: 'dep-19',
              goalId: 'goal-investment',
              amount: 100000,
              date: now,
            ),
          );
      final repAfter =
          await c.refresh(monthlyReportProvider(month).future);
      expect(repAfter.expense, repBefore.expense);
      expect(repAfter.investmentMonth, repBefore.investmentMonth + 100000);
      final totalAfter =
          await c.refresh(accountsTotalProvider.future);
      expect(totalAfter, totalBefore);
    });

    test('hapus akun bertransaksi ditolak; tanpa referensi konsisten',
        () async {
      final c = _container();
      final controller = c.read(accountsControllerProvider);
      await _addTx(c,
          amount: 10000,
          type: TransactionType.expense,
          date: DateTime.now(),
          accountId: 'inst-jago');
      expect(await controller.deleteAccount('inst-jago'), isFalse);
      final beforeCount = (await c
              .read(transactionRepositoryProvider)
              .getRecentTransactions())
          .length;
      expect(await controller.deleteAccount('inst-cash'), isTrue);
      final accounts =
          await c.read(accountRepositoryProvider).getAccounts();
      expect(accounts.map((e) => e.id),
          ['inst-bca', 'inst-jago']);
      final total = await c.refresh(accountsTotalProvider.future);
      expect(total, 6000000 - 10000);
      // Transaksi tetap ada (riwayat utuh, jumlah tak berubah).
      final txs = await c
          .read(transactionRepositoryProvider)
          .getRecentTransactions();
      expect(txs.length, beforeCount);
    });

    test('batas: nominal nol dan fee negatif ditolak', () async {
      final c = _container();
      final notifier = c.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.expense);
      notifier.setAmount(0);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('inst-bca');
      notifier.setDate(DateTime.now());
      expect(await notifier.save(), isFalse);
      notifier.setAmount(50000);
      notifier.setFee(-100);
      expect(c.read(transactionFormProvider).fee, 0);
    });

    test('bulan kosong dan PDF konsisten dengan laporan', () async {
      final c = _container();
      final empty = await c.read(
        monthlyReportProvider(DateTime(2020, 1)).future,
      );
      expect(empty.income, 0);
      expect(empty.expense, 0);
      expect(empty.categories, isEmpty);

      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      await _addTx(c,
          amount: 75000, type: TransactionType.expense, date: now);
      final rep =
          await c.refresh(monthlyReportProvider(month).future);
      final goals = await c.read(goalRepositoryProvider).getGoals();
      final payload = buildReportExportData(
        report: rep,
        goals: goals,
        now: now,
      );
      expect(payload.income, rep.income);
      expect(payload.expense, rep.expense);
      expect(payload.net, rep.net);
      expect(
        payload.categories.fold<double>(0, (s, e) => s + e.amount),
        rep.expense,
      );
      expect(payload.filename, endsWith('.pdf'));
      expect(payload.qrPayload, contains(payload.reportId));
    });
  });
}
