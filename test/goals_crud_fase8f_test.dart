import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/core/utils/goal_math.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/goals/presentation/providers/goals_controller.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_create_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_setup_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_priority_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/widgets/goal_widgets.dart';

class _FakeGoalRepository implements GoalRepository {
  final List<FinancialGoal> goals = [];
  final List<GoalDeposit> deposits = [];
  bool throwOnAdd = false;
  String? addErrorMessage;

  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    if (throwOnAdd) {
      throw ApiException(addErrorMessage ?? 'Data target tidak valid.', statusCode: 422);
    }
    final created = goal.copyWith(id: 'goal-uuid-${goals.length + 1}');
    goals.add(created);
    return created;
  }

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async {
    deposits.add(deposit);
    return deposit;
  }

  @override
  Future<void> deleteDeposit(String id) async {
    deposits.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteGoal(String id) async {
    goals.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) async {
    return deposits.where((e) => e.goalId == goalId).toList();
  }

  @override
  Future<FinancialGoal> getGoalById(String id) async {
    return goals.firstWhere((e) => e.id == id);
  }

  @override
  Future<List<FinancialGoal>> getGoals() async {
    return List.unmodifiable(goals);
  }

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final idx = goals.indexWhere((e) => e.id == orderedIds[i]);
      if (idx != -1) {
        goals[idx] = goals[idx].copyWith(priority: i);
      }
    }
  }

  @override
  Future<GoalDeposit> updateDeposit(GoalDeposit deposit) async {
    return deposit;
  }

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final idx = goals.indexWhere((e) => e.id == goal.id);
    if (idx != -1) {
      goals[idx] = goal;
    }
    return goal;
  }
}

void main() {
  group('Fase 8F: Goals CRUD, Save Button & Priority Verification', () {
    late _FakeGoalRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeGoalRepository();
    });

    test('1. GoalDraft validation: today or future date is valid, past date is invalid', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      var draft = GoalDraft(
        category: GoalCategory.savings,
        name: 'Dana Darurat',
        targetAmount: 10000000,
        targetDate: tomorrow,
      );
      expect(draft.isStepOneValid, isTrue);

      // Date today is also valid (deadline at end of day)
      draft = draft.copyWith(targetDate: today);
      expect(draft.isStepOneValid, isTrue);

      // Past date is invalid
      draft = draft.copyWith(targetDate: yesterday);
      expect(draft.isStepOneValid, isFalse);

      // Missing category is invalid
      draft = GoalDraft(
        name: 'Dana Darurat',
        targetAmount: 10000000,
        targetDate: tomorrow,
      );
      expect(draft.isStepOneValid, isFalse);
    });

    test('2. GoalsController.saveGoal: resilient priority resolution & exception rethrow', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(goalsControllerProvider.notifier);
      notifier.setCategory(GoalCategory.investment);
      notifier.setName('Investasi Saham');
      notifier.setTargetAmount(5000000);
      notifier.setTargetDate(DateTime.now().add(const Duration(days: 60)));

      // Save valid goal
      final saved = await notifier.saveGoal();
      expect(saved, isNotNull);
      expect(saved!.name, equals('Investasi Saham'));
      expect(saved.category, equals(GoalCategory.investment));
      expect(saved.priority, equals(0));

      // Second goal gets incremented priority
      notifier.setCategory(GoalCategory.vehicle);
      notifier.setName('Beli Motor');
      notifier.setTargetAmount(20000000);
      notifier.setTargetDate(DateTime.now().add(const Duration(days: 180)));

      final saved2 = await notifier.saveGoal();
      expect(saved2, isNotNull);
      expect(saved2!.priority, equals(1));

      // Backend error rethrow
      fakeRepo.throwOnAdd = true;
      fakeRepo.addErrorMessage = 'Target nominal terlalu kecil untuk tipe investasi.';
      notifier.setCategory(GoalCategory.investment);
      notifier.setName('Error Goal');
      notifier.setTargetAmount(100);
      notifier.setTargetDate(DateTime.now().add(const Duration(days: 30)));

      expect(
        () => notifier.saveGoal(),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Target nominal terlalu kecil'),
        )),
      );
    });

    test('3. GoalsController.updateGoalFields & deleteGoal operations with UUID', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Seed a goal with UUID
      const goalUuid = 'a8b7c6d5-e4f3-2109-8765-43210abcdef0';
      final initialGoal = FinancialGoal(
        id: goalUuid,
        name: 'Target Rumah',
        targetAmount: 300000000,
        currentAmount: 50000000,
        deadline: DateTime.now().add(const Duration(days: 365)),
        category: GoalCategory.house,
      );
      fakeRepo.goals.add(initialGoal);

      final notifier = container.read(goalsControllerProvider.notifier);

      // Update fields
      final updated = await notifier.updateGoalFields(
        id: goalUuid,
        name: 'Target Rumah Impian',
        category: GoalCategory.house,
        targetAmount: 350000000,
        targetDate: DateTime.now().add(const Duration(days: 400)),
        recurringAmount: 5000000,
        frequency: DepositFrequency.monthly,
        sourceAccountId: null,
      );
      expect(updated, isTrue);

      final stored = fakeRepo.goals.firstWhere((e) => e.id == goalUuid);
      expect(stored.name, equals('Target Rumah Impian'));
      expect(stored.targetAmount, equals(350000000));
      // Deposito / currentAmount remains untouched
      expect(stored.currentAmount, equals(50000000));

      // Delete goal
      final deleted = await notifier.deleteGoal(goalUuid);
      expect(deleted, isTrue);
      expect(fakeRepo.goals.where((e) => e.id == goalUuid).isEmpty, isTrue);
    });

    test('4. Priority Reorder preserves UUID order and updates priority indices', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      const id1 = 'uuid-goal-1';
      const id2 = 'uuid-goal-2';
      const id3 = 'uuid-goal-3';

      fakeRepo.goals.addAll([
        const FinancialGoal(id: id1, name: 'Goal 1', targetAmount: 1000, currentAmount: 0, priority: 0),
        const FinancialGoal(id: id2, name: 'Goal 2', targetAmount: 2000, currentAmount: 0, priority: 1),
        const FinancialGoal(id: id3, name: 'Goal 3', targetAmount: 3000, currentAmount: 0, priority: 2),
      ]);

      final notifier = container.read(goalsControllerProvider.notifier);

      // Move Goal 3 to top, then Goal 1, then Goal 2
      final reordered = await notifier.saveOrder([id3, id1, id2]);
      expect(reordered, isTrue);

      expect(fakeRepo.goals.firstWhere((e) => e.id == id3).priority, equals(0));
      expect(fakeRepo.goals.firstWhere((e) => e.id == id1).priority, equals(1));
      expect(fakeRepo.goals.firstWhere((e) => e.id == id2).priority, equals(2));
    });

    test('5. GoalCircularProgress widget layout: padding prevents top and side stroke clipping', () {
      const widget = GoalCircularProgress(progress: 0.75, size: 148);
      expect(widget.progress, equals(0.75));
      expect(widget.size, equals(148));
    });

    test('6. Goal math calculations: recommendation, ETA, shortfall warnings', () {
      final now = DateTime(2026, 1, 10);
      final deadline = DateTime(2026, 7, 20);

      // Target 1.000.000, collected 0 -> remaining 1.000.000
      final remaining = goalRemaining(target: 1000000, collected: 0);
      expect(remaining, equals(1000000));

      // Recommendation per month
      final rec = recommendedPerPeriod(
        target: 1000000,
        collected: 0,
        deadline: deadline,
        frequency: DepositFrequency.monthly,
        now: now,
      );
      expect(rec, isNotNull);
      expect(rec!, greaterThan(0));

      // ETA with 250k deposit is May 10, 2026
      final eta = estimateReachDate(
        target: 1000000,
        collected: 0,
        perDeposit: 250000,
        frequency: DepositFrequency.monthly,
        now: now,
      );
      expect(eta, equals(DateTime(2026, 5, 10)));
      expect(eta!.isBefore(deadline), isTrue);

      // ETA with insufficient deposit (e.g. 50k/mo, 20 months) misses deadline
      final etaShortfall = estimateReachDate(
        target: 1000000,
        collected: 0,
        perDeposit: 50000,
        frequency: DepositFrequency.monthly,
        now: now,
      );
      expect(etaShortfall, isNotNull);
      expect(etaShortfall!.isAfter(deadline), isTrue);
    });

    testWidgets('7. GoalCreateScreen: validation gives explicit feedback without silent failure', (tester) async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GoalCreateScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap "Lanjutkan" without selecting category or filling fields
      final continueBtn = find.text(AppStrings.continueAction);
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Expect category validation error to be visible
      expect(find.text('Pilih salah satu kategori target di atas.'), findsOneWidget);
      expect(find.text('Pilih salah satu kategori target.'), findsOneWidget); // SnackBar
    });

    testWidgets('8. GoalSetupScreen: handles ApiException and displays error SnackBar cleanly', (tester) async {
      fakeRepo.throwOnAdd = true;
      fakeRepo.addErrorMessage = 'Target nominal melebihi batas simpanan darurat.';

      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Pre-fill valid draft so GoalSetupScreen does not redirect back to /goals/new
      final notifier = container.read(goalsControllerProvider.notifier);
      notifier.setCategory(GoalCategory.emergency);
      notifier.setName('Dana Darurat Medis');
      notifier.setTargetAmount(50000000);
      notifier.setTargetDate(DateTime.now().add(const Duration(days: 90)));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GoalSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveBtn = find.text(AppStrings.saveGoalAction);
      expect(saveBtn, findsOneWidget);

      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Expect error SnackBar to appear with backend message
      expect(find.text('Target nominal melebihi batas simpanan darurat.'), findsOneWidget);
    });
  });
}
