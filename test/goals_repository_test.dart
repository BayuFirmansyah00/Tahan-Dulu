import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';

MockGoalRepository _repo() => MockGoalRepository();

FinancialGoal _goal(String id, {double target = 10000000}) {
  return FinancialGoal(
    id: id,
    name: 'Goal $id',
    targetAmount: target,
    currentAmount: 0,
    deadline: DateTime(2027, 6, 30),
    category: GoalCategory.savings,
  );
}

void main() {
  test('starts with canonical seed goal', () async {
    final goals = await _repo().getGoals();

    expect(goals.length, 1);
    expect(goals.first.name, 'Target Investasi');
  });

  test('addGoal appends without touching others', () async {
    final repo = _repo();
    await repo.addGoal(_goal('g-1'));

    final goals = await repo.getGoals();
    expect(goals.length, 2);
    expect(goals.last.id, 'g-1');
    expect(goals.last.currentAmount, 0);
  });

  test('addDeposit accumulates currentAmount and history desc', () async {
    final repo = _repo();
    await repo.addGoal(_goal('g-1'));
    await repo.addDeposit(
      GoalDeposit(
        id: 'd-1',
        goalId: 'g-1',
        amount: 300000,
        date: DateTime(2026, 9, 1),
        accountId: 'inst-bca',
      ),
    );
    await repo.addDeposit(
      GoalDeposit(
        id: 'd-2',
        goalId: 'g-1',
        amount: 200000,
        date: DateTime(2026, 10, 5),
        accountId: 'inst-bca',
      ),
    );

    final goals = await repo.getGoals();
    final goal = goals.firstWhere((e) => e.id == 'g-1');
    expect(goal.currentAmount, 500000);
    expect(goal.progress, 0.05);

    final history = await repo.getDeposits('g-1');
    expect(history.length, 2);
    expect(history.first.id, 'd-2');
    expect(history.last.id, 'd-1');
  });

  test('deposits are isolated per goal', () async {
    final repo = _repo();
    await repo.addGoal(_goal('g-1'));
    await repo.addGoal(_goal('g-2'));
    await repo.addDeposit(
      GoalDeposit(
        id: 'd-1',
        goalId: 'g-1',
        amount: 100000,
        date: DateTime.now(),
      ),
    );

    expect((await repo.getDeposits('g-2')), isEmpty);
    final goals = await repo.getGoals();
    expect(
      goals.firstWhere((e) => e.id == 'g-2').currentAmount,
      0,
    );
  });

  test('updateGoal replaces fields, deposits untouched', () async {
    final repo = _repo();
    await repo.addGoal(_goal('g-1'));
    await repo.addDeposit(
      GoalDeposit(
        id: 'd-1',
        goalId: 'g-1',
        amount: 100000,
        date: DateTime.now(),
      ),
    );

    final updated = (await repo.getGoals())
        .firstWhere((e) => e.id == 'g-1')
        .copyWith(name: 'Renamed', targetAmount: 20000000);
    await repo.updateGoal(updated);

    final goals = await repo.getGoals();
    final goal = goals.firstWhere((e) => e.id == 'g-1');
    expect(goal.name, 'Renamed');
    expect(goal.currentAmount, 100000);
    expect((await repo.getDeposits('g-1')).length, 1);
  });

  test('saveGoalOrder persists priority', () async {
    final repo = _repo();
    await repo.addGoal(_goal('g-1'));
    await repo.addGoal(_goal('g-2'));

    // Balik urutan: g-2 dulu.
    final ids = (await repo.getGoals()).map((e) => e.id).toList().reversed.toList();
    await repo.saveGoalOrder(ids);

    final goals = await repo.getGoals();
    final byId = {for (final e in goals) e.id: e};
    expect(byId[ids.first]!.priority, 0);
    expect(byId[ids.last]!.priority, greaterThan(0));

    final sorted = List.of(goals)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    expect(sorted.first.id, ids.first);
  });

  test('unknown goal update throws', () async {
    expect(
      () => _repo().updateGoal(_goal('missing')),
      throwsStateError,
    );
  });
}
