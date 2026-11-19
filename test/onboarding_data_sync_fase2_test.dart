import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/onboarding_data.dart';
import 'package:tahan_dulu/data/models/recurring_expense.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/expenses_controller.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/goal_controller.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/instruments_controller.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/salary_controller.dart';

/// Repository khusus pengujian untuk memverifikasi hidrasi dan pencegahan duplikasi data Fase 2.
class MockFase2SyncRepository implements OnboardingRepository {
  OnboardingData? _data;
  int saveSalaryCalls = 0;
  int saveInstrumentsCalls = 0;
  int saveExpensesCalls = 0;
  int saveGoalCalls = 0;

  MockFase2SyncRepository({OnboardingData? initialData}) : _data = initialData;

  OnboardingData _ensureData() {
    return _data ?? const OnboardingData(monthlyIncome: 6500000, salaryDay: 28);
  }

  @override
  OnboardingData? getSalarySetup() => _data;

  @override
  OnboardingData? getOnboardingData() => _data;

  @override
  Future<OnboardingData> saveSalarySetup({
    required double monthlyIncome,
    required int salaryDay,
  }) async {
    saveSalaryCalls++;
    _data = _ensureData().copyWith(
      monthlyIncome: monthlyIncome,
      salaryDay: salaryDay,
    );
    return _data!;
  }

  @override
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  ) async {
    saveInstrumentsCalls++;
    _data = _ensureData().copyWith(financialInstruments: instruments);
    return _data!;
  }

  @override
  Future<OnboardingData> saveExpenses(List<RecurringExpense> expenses) async {
    saveExpensesCalls++;
    _data = _ensureData().copyWith(recurringExpenses: expenses);
    return _data!;
  }

  @override
  Future<OnboardingData> saveGoal(FinancialGoal goal) async {
    saveGoalCalls++;
    _data = _ensureData().copyWith(financialGoal: goal);
    return _data!;
  }

  @override
  Future<FinancialInstrument> addInstrument(
    FinancialInstrument instrument,
  ) async {
    final list = List<FinancialInstrument>.from(
      _data?.financialInstruments ?? [],
    );
    list.add(instrument);
    _data = _ensureData().copyWith(financialInstruments: list);
    return instrument;
  }

  @override
  Future<FinancialInstrument> updateInstrument(
    FinancialInstrument instrument,
  ) async {
    final list = (_data?.financialInstruments ?? []).map((e) {
      return e.id == instrument.id ? instrument : e;
    }).toList();
    _data = _ensureData().copyWith(financialInstruments: list);
    return instrument;
  }

  @override
  Future<void> removeInstrument(String id) async {
    final list = (_data?.financialInstruments ?? [])
        .where((e) => e.id != id)
        .toList();
    _data = _ensureData().copyWith(financialInstruments: list);
  }

  @override
  Future<({double income, int salaryDay})> fetchExistingSalary() async {
    return (
      income: _data?.monthlyIncome ?? 6500000,
      salaryDay: _data?.salaryDay ?? 28,
    );
  }

  @override
  Future<List<FinancialInstrument>> fetchExistingInstruments() async {
    return _data?.financialInstruments ??
        const [
          FinancialInstrument(
            id: '101',
            name: 'BCA Prioritas',
            type: InstrumentType.bank,
            initialBalance: 12000000,
            isSelected: true,
          ),
        ];
  }

  @override
  Future<List<RecurringExpense>> fetchExistingExpenses() async {
    return _data?.recurringExpenses ??
        const [
          RecurringExpense(
            id: '201',
            name: 'Sewa Apartemen',
            category: ExpenseCategory.needs,
            monthlyAmount: 2500000,
          ),
        ];
  }

  @override
  Future<FinancialGoal?> fetchExistingGoal() async {
    return _data?.financialGoal ??
        FinancialGoal(
          id: '301',
          name: 'Dana Darurat 6 Bulan',
          targetAmount: 30000000,
          currentAmount: 0,
          deadline: DateTime.now().add(const Duration(days: 365)),
          category: GoalCategory.emergency,
        );
  }

  @override
  Future<OnboardingData?> hydrateAll() async {
    final salary = await fetchExistingSalary();
    final instruments = await fetchExistingInstruments();
    final expenses = await fetchExistingExpenses();
    final goal = await fetchExistingGoal();

    _data = OnboardingData(
      monthlyIncome: salary.income,
      salaryDay: salary.salaryDay,
      financialInstruments: instruments,
      recurringExpenses: expenses,
      financialGoal: goal,
    );
    return _data;
  }

  @override
  void clear() {
    _data = null;
  }
}

void main() {
  group('Fase 2 - Onboarding Data Sync & Hydration Tests', () {
    test(
      '1. Repository hydrateAll successfully restores all onboarding state',
      () async {
        final repo = MockFase2SyncRepository();
        expect(repo.getOnboardingData(), isNull);

        final hydrated = await repo.hydrateAll();
        expect(hydrated, isNotNull);
        expect(hydrated!.monthlyIncome, 6500000);
        expect(hydrated.salaryDay, 28);
        expect(hydrated.financialInstruments.length, 1);
        expect(hydrated.financialInstruments.first.id, '101');
        expect(hydrated.recurringExpenses.length, 1);
        expect(hydrated.recurringExpenses.first.id, '201');
        expect(hydrated.financialGoal?.id, '301');
        expect(hydrated.financialGoal?.targetAmount, 30000000);
      },
    );

    test(
      '2. SalaryController loads existing data without duplicate HTTP requests',
      () async {
        final repo = MockFase2SyncRepository();
        final container = ProviderContainer(
          overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final salaryNotifier = container.read(
          salaryControllerProvider.notifier,
        );
        await salaryNotifier.loadExisting();

        final state = container.read(salaryControllerProvider);
        expect(state.monthlyIncome, 6500000);
        expect(state.salaryDay, 28);
        expect(state.canContinue, isTrue);

        // Save call should execute exactly 1 repository save call without duplicate PUT
        final success = await salaryNotifier.save();
        expect(success, isTrue);
        expect(repo.saveSalaryCalls, 1);
      },
    );

    test(
      '3. ExpensesController loads existing expenses and retains correct sum',
      () async {
        final repo = MockFase2SyncRepository();
        final container = ProviderContainer(
          overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final expensesNotifier = container.read(
          expensesControllerProvider.notifier,
        );
        await expensesNotifier.loadExisting();

        final state = container.read(expensesControllerProvider);
        expect(state.expenses.length, 1);
        expect(state.expenses.first.id, '201');
        expect(state.total, 2500000);
        expect(state.canContinue, isTrue);

        final success = await expensesNotifier.save();
        expect(success, isTrue);
        expect(repo.saveExpensesCalls, 1);
      },
    );

    test(
      '4. GoalController loads existing goal and preserves backend id',
      () async {
        final repo = MockFase2SyncRepository();
        final container = ProviderContainer(
          overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final goalNotifier = container.read(goalControllerProvider.notifier);
        await goalNotifier.loadExisting();

        final state = container.read(goalControllerProvider);
        expect(state.name, 'Dana Darurat 6 Bulan');
        expect(state.targetAmount, 30000000);
        expect(state.canContinue, isTrue);

        final success = await goalNotifier.save();
        expect(success, isTrue);
        expect(repo.saveGoalCalls, 1);
      },
    );

    test(
      '5. InstrumentsController loads existing instruments with selection status',
      () async {
        final repo = MockFase2SyncRepository();
        final container = ProviderContainer(
          overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final instrumentsNotifier = container.read(
          instrumentsControllerProvider.notifier,
        );
        await instrumentsNotifier.loadExisting();

        final state = container.read(instrumentsControllerProvider);
        expect(state.instruments.length, 1);
        expect(state.instruments.first.id, '101');
        expect(state.instruments.first.name, 'BCA Prioritas');
        expect(state.selected.length, 1);
        expect(state.canContinue, isTrue);

        final success = await instrumentsNotifier.save();
        expect(success, isTrue);
        expect(repo.saveInstrumentsCalls, 1);
      },
    );

    test(
      '6. PlanScreen / FinancialPlan computes consistent metrics from hydrated data',
      () async {
        final repo = MockFase2SyncRepository();
        await repo.hydrateAll();

        final container = ProviderContainer(
          overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        // Hydrate all controllers
        await container.read(salaryControllerProvider.notifier).loadExisting();
        await container
            .read(instrumentsControllerProvider.notifier)
            .loadExisting();
        await container
            .read(expensesControllerProvider.notifier)
            .loadExisting();
        await container.read(goalControllerProvider.notifier).loadExisting();

        final plan = container.read(financialPlanProvider);
        expect(plan.monthlyIncome, 6500000);
        expect(plan.recurringExpensesTotal, 2500000); // from RecurringExpense
        expect(plan.goalName, 'Dana Darurat 6 Bulan');
        expect(plan.goalTargetAmount, 30000000);

        // Daily limit consistency test: (Needs + Wants) / days
        final dailyLimit = plan.dailySpendingLimit;
        expect(dailyLimit, greaterThan(0));
      },
    );
  });
}
