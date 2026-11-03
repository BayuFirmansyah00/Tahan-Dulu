import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/onboarding_data.dart';
import 'package:tahan_dulu/data/models/recurring_expense.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';

/// Onboarding kosong: agregat harus tetap valid (nol + fallback).
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
    _data = _data!.copyWith(
      monthlyIncome: monthlyIncome,
      salaryDay: salaryDay,
    );
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

  @override
  void clear() {
    _data = null;
  }
}

DateTime _previousMonth(DateTime now) =>
    DateTime(now.year, now.month - 1, 15);

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('dashboard aggregates onboarding data with canonical math', () async {
    final data = await _container().read(dashboardDataProvider.future);

    expect(data.user.name, 'Bayu Firmansyah');
    expect(data.monthlyIncome, 5000000);
    expect(data.expensesTotal, 2500000);
    // Kontribusi goal default: 10jt / monthsUntil(Juni 2027).
    expect(data.goalContribution, greaterThan(0));
    expect(
      data.remainingFlexible,
      5000000 - 2500000 - data.goalContribution,
    );
    expect(data.totalBalance, 6500000);
    expect(data.goals.length, 2);
    expect(data.goals.first.name, 'Investasi');
    expect(data.pendingCount, 1);
    expect(data.hasUnread, isTrue);
  });

  test('safe daily follows deterministic formula', () async {
    final data = await _container().read(dashboardDataProvider.future);

    expect(data.safeDaily, lessThanOrEqualTo(data.remainingFlexible));
    expect(data.safeDaily % 1000, 0);
  });

  test('new transaction updates aggregates reactively', () async {
    final container = _container();
    final before = await container.read(dashboardDataProvider.future);

    await container.read(transactionRepositoryProvider).addTransaction(
          AppTransaction(
            id: 'trx-engine-1',
            title: 'Jajan',
            amount: 100000,
            type: TransactionType.expense,
            date: DateTime.now(),
            category: 'Lainnya',
            accountId: 'inst-cash',
          ),
        );
    container.invalidate(transactionsProvider);
    final after = await container.read(dashboardDataProvider.future);

    expect(
      after.actualMonthExpense,
      before.actualMonthExpense + 100000,
    );
    // Terhubung ke inst-cash: total ikut berkurang, sekali saja.
    expect(after.totalBalance, before.totalBalance - 100000);
    expect(after.remainingFlexible, before.remainingFlexible);
  });

  test('previous-month transaction skips monthly actuals', () async {
    final container = _container();
    final before = await container.read(dashboardDataProvider.future);
    final prev = _previousMonth(DateTime.now());

    await container.read(transactionRepositoryProvider).addTransaction(
          AppTransaction(
            id: 'trx-engine-2',
            title: 'Gaji lalu',
            amount: 500000,
            type: TransactionType.income,
            date: prev,
            category: 'Gaji',
            accountId: 'inst-bca',
          ),
        );
    container.invalidate(transactionsProvider);
    final after = await container.read(dashboardDataProvider.future);

    // Bulan lalu: tidak masuk aktual bulan ini (R6)...
    expect(after.actualMonthIncome, before.actualMonthIncome);
    // ...tetapi tetap memengaruhi saldo akun seumur hidup (R1).
    expect(after.totalBalance, before.totalBalance + 500000);
  });

  test('legacy seed transactions touch no account', () async {
    // Seeds memakai accountId 'acc-*' yang tidak ada di instrumen:
    // total tetap tepat sama dengan jumlah saldo awal (R1, R2).
    final data = await _container().read(dashboardDataProvider.future);

    expect(data.totalBalance, 5000000 + 1000000 + 500000);
  });

  test('empty onboarding still produces valid aggregates', () async {
    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(
          _EmptyOnboardingRepo(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final data = await container.read(dashboardDataProvider.future);

    expect(data.monthlyIncome, 0);
    expect(data.totalBalance, 0);
    expect(data.remainingFlexible, 0);
    expect(data.safeDaily, 0);
    // Fallback mock goals tetap tersedia.
    expect(data.goals.length, 1);
  });

  test('model has no transfer type to miscalculate', () {
    // Didokumentasikan: hanya income/expense, tanpa transfer (gap).
    expect(TransactionType.values, [
      TransactionType.income,
      TransactionType.expense,
    ]);
  });
}
