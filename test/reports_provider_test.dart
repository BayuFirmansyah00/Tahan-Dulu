import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/reports_providers.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

Future<void> _addTx(
  ProviderContainer container, {
  required String id,
  required double amount,
  required TransactionType type,
  required DateTime date,
  String? category,
}) async {
  await container.read(transactionRepositoryProvider).addTransaction(
        AppTransaction(
          id: id,
          title: 'T',
          amount: amount,
          type: type,
          date: date,
          category: category,
        ),
      );
  container.invalidate(transactionsProvider);
}

void main() {
  test('aggregates october seeds deterministically', () async {
    final report = await _container()
        .read(monthlyReportProvider(DateTime(2026, 10)).future);

    expect(report.income, 5000000);
    expect(report.expense, 850000 + 500000);
    expect(report.net, 5000000 - 1350000);
    expect(report.prevIncome, isNull);
    expect(report.prevExpense, isNull);
  });

  test('month filter excludes other months', () async {
    final container = _container();
    await _addTx(
      container,
      id: 'trx-nov',
      amount: 999000,
      type: TransactionType.expense,
      date: DateTime(2026, 11, 2),
      category: 'Belanja',
    );

    final october = await container
        .read(monthlyReportProvider(DateTime(2026, 10)).future);
    expect(october.expense, 1350000);

    final november = await container
        .read(monthlyReportProvider(DateTime(2026, 11)).future);
    expect(november.expense, 999000);
    expect(november.income, 0);
    // November melihat Oktober sebagai pembanding.
    expect(november.prevExpense, 1350000);
    expect(november.prevIncome, 5000000);
  });

  test('year rollover separates december and january', () async {
    final container = _container();
    await _addTx(
      container,
      id: 'trx-dec',
      amount: 100000,
      type: TransactionType.expense,
      date: DateTime(2026, 12, 31),
      category: 'Lainnya',
    );
    await _addTx(
      container,
      id: 'trx-jan',
      amount: 200000,
      type: TransactionType.expense,
      date: DateTime(2027, 1, 1),
      category: 'Lainnya',
    );

    final dec = await container
        .read(monthlyReportProvider(DateTime(2026, 12)).future);
    final jan = await container
        .read(monthlyReportProvider(DateTime(2027, 1)).future);
    expect(dec.expense, 100000);
    expect(jan.expense, 200000);
    expect(jan.prevExpense, 100000);
  });

  test('categories sum to total with shares', () async {
    final report = await _container()
        .read(monthlyReportProvider(DateTime(2026, 10)).future);

    expect(report.categories.length, 2);
    expect(report.categories.first.label, 'Kebutuhan');
    final sum =
        report.categories.fold<double>(0, (s, c) => s + c.amount);
    expect(sum, report.expense);
    final shareSum =
        report.categories.fold<double>(0, (s, c) => s + c.share);
    expect(shareSum, closeTo(1.0, 0.0001));
  });

  test('empty month yields zeros and empty lists', () async {
    final report = await _container()
        .read(monthlyReportProvider(DateTime(2025, 5)).future);

    expect(report.income, 0);
    expect(report.expense, 0);
    expect(report.net, 0);
    expect(report.categories, isEmpty);
    expect(report.prevIncome, isNull);
    expect(report.lastSix.length, 6);
    expect(
      report.lastSix.every(
          (p) => p.savings == 0 && p.investment == 0),
      isTrue,
    );
  });

  test('savings and investment read deposits by goal category', () async {
    final container = _container();
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 5);
    // Deposit ke goal investasi mock (kategori investment).
    final goals =
        await container.read(goalRepositoryProvider).getGoals();
    final investmentGoal = goals.firstWhere(
      (g) => g.name == 'Target Investasi',
    );
    await container.read(goalRepositoryProvider).addDeposit(
          GoalDeposit(
            id: 'dep-rpt-1',
            goalId: investmentGoal.id,
            amount: 400000,
            date: firstOfMonth,
          ),
        );
    container.invalidate(transactionsProvider);

    final report = await container
        .read(monthlyReportProvider(DateTime(now.year, now.month)).future);
    expect(report.investmentMonth, 400000);
    expect(report.savingsMonth, 0);
    expect(report.investmentSaved, 3500000 + 400000);
  });

  test('new transaction updates report reactively', () async {
    final container = _container();
    final month = DateTime(2026, 10);
    final before =
        await container.read(monthlyReportProvider(month).future);

    await _addTx(
      container,
      id: 'trx-new',
      amount: 250000,
      type: TransactionType.expense,
      date: DateTime(2026, 10, 20),
      category: 'Belanja',
    );
    // Kontrak reaktivitas: titik mutasi meng-invalidate laporan.
    container.invalidate(monthlyReportProvider);

    final after =
        await container.read(monthlyReportProvider(month).future);
    expect(after.expense, before.expense + 250000);
    expect(
      after.categories.firstWhere((c) => c.label == 'Belanja').amount,
      250000,
    );
  });

  test('income-only transactions are not expenses', () async {
    final container = _container();
    await _addTx(
      container,
      id: 'trx-inc',
      amount: 1000000,
      type: TransactionType.income,
      date: DateTime(2026, 10, 21),
      category: 'Bonus',
    );

    final report = await container
        .read(monthlyReportProvider(DateTime(2026, 10)).future);
    expect(report.income, 6000000);
    expect(report.expense, 1350000);
    expect(report.categories.any((c) => c.label == 'Bonus'), isFalse);
  });
}
