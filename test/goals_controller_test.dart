import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/finance_math.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/features/goals/presentation/providers/goals_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

DateTime _future(int daysFromNow) =>
    DateTime.now().add(Duration(days: daysFromNow));

void _fillDraft(GoalsController notifier) {
  notifier.setCategory(GoalCategory.gadget);
  notifier.setName('Laptop Baru');
  notifier.setTargetAmount(12000000);
  notifier.setTargetDate(_future(300));
}

void main() {
  test('draft starts invalid', () {
    final draft = _container().read(goalsControllerProvider);

    expect(draft.isStepOneValid, isFalse);
  });

  test('draft validates name, amount, past date', () {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);

    expect(
      container.read(goalsControllerProvider).isStepOneValid,
      isTrue,
    );

    notifier.setName('   ');
    expect(
      container.read(goalsControllerProvider).isStepOneValid,
      isFalse,
    );
    notifier.setName('Laptop Baru');

    notifier.setTargetAmount(0);
    expect(
      container.read(goalsControllerProvider).isStepOneValid,
      isFalse,
    );
    notifier.setTargetAmount(12000000);

    notifier.setTargetDate(DateTime(2020, 1, 1));
    expect(
      container.read(goalsControllerProvider).isStepOneValid,
      isFalse,
    );
  });

  test('saveGoal stores draft as new goal', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    notifier.setRecurringAmount(500000);

    final saved = await notifier.saveGoal();
    expect(saved, isNotNull);
    expect(saved!.name, 'Laptop Baru');
    expect(saved.category, GoalCategory.gadget);
    expect(saved.currentAmount, 0);
    expect(saved.recurringAmount, 500000);

    final list = await container.read(goalsListProvider.future);
    expect(list.map((e) => e.id), contains(saved.id));
  });

  test('saveGoal refuses incomplete draft', () async {
    final container = _container();
    expect(
      await container.read(goalsControllerProvider.notifier).saveGoal(),
      isNull,
    );
  });

  test('requiredPerPeriod divides remaining by periods', () {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    final date = DateTime.now().add(const Duration(days: 180));

    final monthly = notifier.requiredPerPeriod(
      remaining: 6000000,
      targetDate: date,
      frequency: DepositFrequency.monthly,
    );
    final weekly = notifier.requiredPerPeriod(
      remaining: 6000000,
      targetDate: date,
      frequency: DepositFrequency.weekly,
    );
    expect(monthly, greaterThan(0));
    expect(weekly, greaterThan(0));
    expect(weekly, lessThan(monthly));
  });

  test('monthsToReachGoal handles edge cases', () {
    expect(
      monthsToReachGoal(
        remaining: 1000000,
        perDeposit: 250000,
        depositsPerMonth: 1,
      ),
      4,
    );
    expect(
      monthsToReachGoal(
        remaining: 1000000,
        perDeposit: 300000,
        depositsPerMonth: 1,
      ),
      4, // Dibulatkan ke atas agar cukup.
    );
    expect(
      monthsToReachGoal(
        remaining: 0,
        perDeposit: 250000,
        depositsPerMonth: 1,
      ),
      0,
    );
    expect(
      monthsToReachGoal(
        remaining: 1000000,
        perDeposit: 0,
        depositsPerMonth: 1,
      ),
      isNull,
    );
    expect(
      monthsToReachGoal(
        remaining: 1000000,
        perDeposit: -5,
        depositsPerMonth: 1,
      ),
      isNull,
    );
  });

  test('addDeposit accumulates and refreshes list', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    final saved = (await notifier.saveGoal())!;

    final deposit = await notifier.addDeposit(
      goalId: saved.id,
      amount: 2000000,
      accountId: 'inst-bca',
    );
    expect(deposit, isNotNull);

    final list = await container.read(goalsListProvider.future);
    expect(
      list.firstWhere((e) => e.id == saved.id).currentAmount,
      2000000,
    );
    final history =
        await container.read(goalDepositsProvider(saved.id).future);
    expect(history.length, 1);
    expect(history.first.amount, 2000000);
  });

  test('addDeposit rejects non-positive amount', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    final saved = (await notifier.saveGoal())!;

    expect(
      await notifier.addDeposit(
        goalId: saved.id,
        amount: 0,
        accountId: null,
      ),
      isNull,
    );
    expect(
      await notifier.addDeposit(
        goalId: saved.id,
        amount: -1000,
        accountId: null,
      ),
      isNull,
    );
  });

  test('saveOrder persists new ranking', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    final second = (await notifier.saveGoal())!;

    final before = await container.read(goalsListProvider.future);
    final reversed = before.map((e) => e.id).toList().reversed.toList();
    expect(await notifier.saveOrder(reversed), isTrue);

    // Re-read: forced refresh karena saveOrder invalidate.
    container.invalidate(goalsListProvider);
    final after = await container.read(goalsListProvider.future);
    expect(after.first.id, reversed.first);
    expect(second.id, isNotNull);
  });

  test('applyPlan stores simulated amount only after confirm path', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    final saved = (await notifier.saveGoal())!;

    // Simulasi murni tidak menyentuh repository.
    final before = await container.read(goalsListProvider.future);
    expect(
      before.firstWhere((e) => e.id == saved.id).recurringAmount,
      0,
    );

    expect(
      await notifier.applyPlan(goalId: saved.id, recurringAmount: 900000),
      isTrue,
    );
    container.invalidate(goalsListProvider);
    final after = await container.read(goalsListProvider.future);
    expect(
      after.firstWhere((e) => e.id == saved.id).recurringAmount,
      900000,
    );
  });

  test('updateGoalFields edits without touching deposits', () async {
    final container = _container();
    final notifier = container.read(goalsControllerProvider.notifier);
    _fillDraft(notifier);
    final saved = (await notifier.saveGoal())!;
    await notifier.addDeposit(
      goalId: saved.id,
      amount: 1000000,
      accountId: null,
    );

    expect(
      await notifier.updateGoalFields(
        id: saved.id,
        name: 'Laptop Gaming',
        category: GoalCategory.gadget,
        targetAmount: 15000000,
        targetDate: _future(400),
        recurringAmount: 800000,
        frequency: DepositFrequency.weekly,
        sourceAccountId: null,
      ),
      isTrue,
    );

    container.invalidate(goalsListProvider);
    final updated = (await container.read(goalsListProvider.future))
        .firstWhere((e) => e.id == saved.id);
    expect(updated.name, 'Laptop Gaming');
    expect(updated.currentAmount, 1000000);
    expect(updated.frequency, DepositFrequency.weekly);
  });

  test('priority labels follow rank', () {
    expect(priorityLabel(0, 3), 'Tinggi');
    expect(priorityLabel(1, 3), 'Sedang');
    expect(priorityLabel(2, 3), 'Rendah');
    expect(priorityLabel(0, 1), 'Tinggi');
  });
}
