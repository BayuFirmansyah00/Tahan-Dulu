import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/recurring_expense.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/expenses_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initial state has canonical defaults and correct total', () {
    final state = _container().read(expensesControllerProvider);

    expect(state.expenses.length, 4);
    expect(state.expenses[0].name, 'Kebutuhan sehari-hari');
    expect(state.expenses[0].monthlyAmount, 1500000);
    expect(state.total, 2500000);
    expect(state.canContinue, isTrue);
  });

  test('add, update, and remove expenses', () {
    final container = _container();
    final notifier = container.read(expensesControllerProvider.notifier);

    notifier.addExpense(
      const RecurringExpense(
        id: 'exp-x',
        name: 'Langganan',
        category: ExpenseCategory.others,
        monthlyAmount: 150000,
      ),
    );
    expect(container.read(expensesControllerProvider).total, 2650000);

    notifier.updateExpense(
      const RecurringExpense(
        id: 'exp-x',
        name: 'Langganan',
        category: ExpenseCategory.others,
        monthlyAmount: 200000,
      ),
    );
    expect(container.read(expensesControllerProvider).total, 2700000);

    notifier.removeExpense('exp-x');
    expect(container.read(expensesControllerProvider).total, 2500000);
  });

  test('save persists without touching No.3 and No.4 data', () async {
    final container = _container();
    final notifier = container.read(expensesControllerProvider.notifier);

    notifier.removeExpense('exp-shopping');
    expect(await notifier.save(), isTrue);

    final saved = container
        .read(onboardingRepositoryProvider)
        .getOnboardingData();
    expect(saved?.recurringExpenses.length, 3);
    expect(saved?.recurringExpenses.map((e) => e.id),
        isNot(contains('exp-shopping')));
    // Data No.3 & No.4 tetap tersimpan.
    expect(saved?.monthlyIncome, 5000000);
    expect(saved?.salaryDay, 25);
    expect(saved?.financialInstruments.length, 3);
    expect(
      saved?.financialInstruments.firstWhere((e) => e.id == 'inst-bca')
          .isSelected,
      isTrue,
    );
  });

  test('save refuses when list is empty', () async {
    final container = _container();
    final notifier = container.read(expensesControllerProvider.notifier);

    for (final id in ['exp-daily', 'exp-transport', 'exp-bills', 'exp-shopping']) {
      notifier.removeExpense(id);
    }
    expect(container.read(expensesControllerProvider).canContinue, isFalse);
    expect(await notifier.save(), isFalse);
  });
}
