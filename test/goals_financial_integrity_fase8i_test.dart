import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/goals/presentation/providers/goals_controller.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';

class _MockGoalRepository implements GoalRepository {
  final List<FinancialGoal> goals = [];
  final List<GoalDeposit> deposits = [];
  bool throwOnDelete = false;
  String? deleteErrorMessage;
  int? deleteStatusCode;

  @override
  Future<List<FinancialGoal>> getGoals() async => List.unmodifiable(goals);

  @override
  Future<FinancialGoal> getGoalById(String id) async {
    final match = goals.where((g) => g.id == id).firstOrNull;
    if (match == null) throw StateError('Goal not found');
    return match;
  }

  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    goals.add(goal);
    return goal;
  }

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final idx = goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) goals[idx] = goal;
    return goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    if (throwOnDelete) {
      throw ApiException(
        deleteErrorMessage ?? 'Target masih memiliki dana terkumpul. Kosongkan alokasi dana terlebih dahulu sebelum menghapus target.',
        statusCode: deleteStatusCode ?? 422,
      );
    }
    goals.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) async {
    return deposits.where((d) => d.goalId == goalId).toList();
  }

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async {
    deposits.add(deposit);
    final idx = goals.indexWhere((g) => g.id == deposit.goalId);
    if (idx != -1) {
      goals[idx] = goals[idx].copyWith(
        currentAmount: goals[idx].currentAmount + deposit.amount,
      );
    }
    return deposit;
  }

  @override
  Future<GoalDeposit> updateDeposit(GoalDeposit deposit) async => deposit;

  @override
  Future<void> deleteDeposit(String id) async {
    deposits.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) async {}
}

void main() {
  group('Fase 8I: Goals Financial Integrity & Delete Validation Tests', () {
    late _MockGoalRepository repo;

    setUp(() {
      repo = _MockGoalRepository();
    });

    test('1. GoalsController: Delete goal with current_amount = 0 succeeds and removes goal from list', () async {
      final zeroGoal = FinancialGoal(
        id: 'goal-uuid-001',
        name: 'Target Kosong',
        category: GoalCategory.savings,
        targetAmount: 5000000,
        currentAmount: 0,
        priority: 0,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );
      repo.goals.add(zeroGoal);

      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Verify initial state
      final initialGoals = await container.read(goalsListProvider.future);
      expect(initialGoals.length, equals(1));
      expect(initialGoals.first.id, equals('goal-uuid-001'));

      // Perform delete
      final notifier = container.read(goalsControllerProvider.notifier);
      final success = await notifier.deleteGoal('goal-uuid-001');

      expect(success, isTrue);
      expect(repo.goals.isEmpty, isTrue);
    });

    test('2. GoalsController: Delete goal with current_amount > 0 throws ApiException(422) and retains goal in list', () async {
      final fundedGoal = FinancialGoal(
        id: 'goal-uuid-funded',
        name: 'Target Ada Saldo',
        category: GoalCategory.savings,
        targetAmount: 5000000,
        currentAmount: 1500000,
        priority: 0,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );
      repo.goals.add(fundedGoal);
      repo.throwOnDelete = true;
      repo.deleteStatusCode = 422;
      repo.deleteErrorMessage = 'Target masih memiliki dana terkumpul sebesar Rp1.500.000. Kosongkan alokasi dana terlebih dahulu sebelum menghapus target.';

      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(goalsControllerProvider.notifier);

      expect(
        () => notifier.deleteGoal('goal-uuid-funded'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message', contains('Target masih memiliki dana terkumpul'))),
      );

      // Goal MUST remain intact in repository
      expect(repo.goals.length, equals(1));
      expect(repo.goals.first.id, equals('goal-uuid-funded'));
      expect(repo.goals.first.currentAmount, equals(1500000));
    });

    testWidgets('3. Widget Test: GoalDetailScreen displays HTTP 422 error SnackBar and preserves target on failed delete', (tester) async {
      final fundedGoal = FinancialGoal(
        id: 'goal-uuid-funded-widget',
        name: 'Tabungan Motor',
        category: GoalCategory.vehicle,
        targetAmount: 25000000,
        currentAmount: 5000000,
        priority: 0,
        deadline: DateTime.now().add(const Duration(days: 120)),
      );
      repo.goals.add(fundedGoal);
      repo.throwOnDelete = true;
      repo.deleteStatusCode = 422;
      const expectedErrorMsg = 'Target masih memiliki dana terkumpul sebesar Rp5.000.000. Kosongkan alokasi dana terlebih dahulu sebelum menghapus target.';
      repo.deleteErrorMessage = expectedErrorMsg;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GoalDetailScreen(goalId: 'goal-uuid-funded-widget'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure screen loaded
      expect(find.text(AppStrings.goalDetailTitle), findsOneWidget);

      // Tap delete icon in AppBar
      final deleteIcon = find.byTooltip('Hapus Target');
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Hapus target ini?'), findsOneWidget);
      final confirmDeleteBtn = find.widgetWithText(TextButton, 'Hapus');
      expect(confirmDeleteBtn, findsOneWidget);

      // Tap confirm Hapus
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // SnackBar with 422 validation message should be visible
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(expectedErrorMsg), findsOneWidget);

      // Goal still exists in repository
      expect(repo.goals.where((g) => g.id == 'goal-uuid-funded-widget').length, equals(1));
    });

    testWidgets('4. Widget Test: GoalDetailScreen successfully deletes goal with current_amount = 0', (tester) async {
      final emptyGoal = FinancialGoal(
        id: 'goal-uuid-empty-widget',
        name: 'Target Siap Dihapus',
        category: GoalCategory.emergency,
        targetAmount: 10000000,
        currentAmount: 0,
        priority: 0,
        deadline: DateTime.now().add(const Duration(days: 60)),
      );
      repo.goals.add(emptyGoal);
      repo.throwOnDelete = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GoalDetailScreen(goalId: 'goal-uuid-empty-widget'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon
      final deleteIcon = find.byTooltip('Hapus Target');
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirm
      final confirmDeleteBtn = find.widgetWithText(TextButton, 'Hapus');
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Success SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Target berhasil dihapus.'), findsOneWidget);

      // Goal removed from repository
      expect(repo.goals.where((g) => g.id == 'goal-uuid-empty-widget'), isEmpty);
    });
  });
}
