import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/goals/presentation/providers/goals_controller.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_priority_screen.dart';

/// Repository lima target untuk menguji pengurutan.
class _FiveGoalRepository implements GoalRepository {
  final List<FinancialGoal> _goals = [
    const FinancialGoal(
      id: 'g1',
      name: 'Target Investasi',
      targetAmount: 10000000,
      currentAmount: 3500000,
      category: GoalCategory.investment,
      priority: 0,
    ),
    const FinancialGoal(
      id: 'g2',
      name: 'Mobil Baru',
      targetAmount: 200000000,
      currentAmount: 0,
      category: GoalCategory.vehicle,
      priority: 1,
    ),
    const FinancialGoal(
      id: 'g3',
      name: 'Rumah Impian',
      targetAmount: 500000000,
      currentAmount: 60000000,
      category: GoalCategory.house,
      priority: 2,
    ),
    const FinancialGoal(
      id: 'g4',
      name: 'Liburan Bali',
      targetAmount: 15000000,
      currentAmount: 3000000,
      category: GoalCategory.holiday,
      priority: 3,
    ),
    const FinancialGoal(
      id: 'g5',
      name: 'Kuliah Anak',
      targetAmount: 100000000,
      currentAmount: 0,
      category: GoalCategory.education,
      priority: 4,
    ),
  ];

  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    _goals.add(goal);
    return goal;
  }

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async => deposit;

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) async => [];

  @override
  Future<List<FinancialGoal>> getGoals() async => List.of(_goals);

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) async {
    final byId = {for (final e in _goals) e.id: e};
    final ordered = [
      for (final id in orderedIds)
        if (byId.containsKey(id)) byId[id]!,
      for (final e in _goals)
        if (!orderedIds.contains(e.id)) e,
    ];
    _goals
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++)
          ordered[i].copyWith(priority: i),
      ]);
  }

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async => goal;

  @override
  Future<FinancialGoal> getGoalById(String id) async =>
      _goals.firstWhere((g) => g.id == id);

  @override
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
  }

  @override
  Future<GoalDeposit> updateDeposit(GoalDeposit deposit) async => deposit;

  @override
  Future<void> deleteDeposit(String id) async {}
}

Finder _assetImage(String asset) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == asset,
    );

Future<void> _pumpPriority(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(_FiveGoalRepository()),
      ],
      child: const MaterialApp(home: GoalPriorityScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _moveButtons(String tooltip) => find.byWidgetPredicate(
      (w) => w is IconButton && w.tooltip == tooltip,
    );

List<bool> _upEnabled(WidgetTester tester) => tester
    .widgetList<IconButton>(_moveButtons(AppStrings.priorityMoveUp))
    .map((b) => b.onPressed != null)
    .toList();

List<bool> _downEnabled(WidgetTester tester) => tester
    .widgetList<IconButton>(_moveButtons(AppStrings.priorityMoveDown))
    .map((b) => b.onPressed != null)
    .toList();

Future<void> _tapMove(
  WidgetTester tester,
  String tooltip,
  int cardIndex,
) async {
  final buttons = _moveButtons(tooltip);
  expect(buttons, findsNWidgets(5));
  await tester.ensureVisible(buttons.at(cardIndex));
  await tester.pumpAndSettle();
  await tester.tap(buttons.at(cardIndex));
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 37: label peringkat dari urutan', () {
    test('utama, kedua, ketiga, lainnya', () {
      expect(priorityRankLabel(0), AppStrings.priorityFirst);
      expect(priorityRankLabel(1), AppStrings.prioritySecond);
      expect(priorityRankLabel(2), AppStrings.priorityThird);
      expect(priorityRankLabel(3), AppStrings.priorityOthers);
      expect(priorityRankLabel(4), AppStrings.priorityOthers);
      expect(priorityRankLabel(10), AppStrings.priorityOthers);
    });
  });

  group('Tahap 37: kartu peringkat memakai aset lokal', () {
    testWidgets('medali 1-5 dan badge sesuai urutan', (tester) async {
      await _pumpPriority(tester);
      // rank_1 dipakai kartu pertama; header memakai checklist.
      expect(_assetImage(AppAssets.rankMedal1), findsOneWidget);
      expect(
        _assetImage(AppAssets.priorityChecklistHeader),
        findsOneWidget,
      );
      for (final asset in [
        AppAssets.rankMedal2,
        AppAssets.rankMedal3,
        AppAssets.rankBadge4,
        AppAssets.rankBadge5,
      ]) {
        expect(_assetImage(asset), findsOneWidget, reason: asset);
      }
      expect(find.text(AppStrings.priorityFirst), findsOneWidget);
      expect(find.text(AppStrings.prioritySecond), findsOneWidget);
      expect(find.text(AppStrings.priorityThird), findsOneWidget);
      expect(find.text(AppStrings.priorityOthers), findsNWidgets(2));
      expect(find.text(AppStrings.priorityInfoTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol naik/turun PNG dengan state benar', (tester) async {
      await _pumpPriority(tester);
      expect(_upEnabled(tester), [false, true, true, true, true]);
      expect(_downEnabled(tester), [true, true, true, true, false]);
      expect(
        find.byTooltip(AppStrings.priorityMoveUp),
        findsNWidgets(5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('naik memindahkan medali dan badge', (tester) async {
      await _pumpPriority(tester);
      await _tapMove(tester, AppStrings.priorityMoveUp, 1);

      // Mobil Baru kini peringkat pertama.
      expect(_upEnabled(tester), [false, true, true, true, true]);
      expect(find.text(AppStrings.priorityFirst), findsOneWidget);
      // Badge Kedua pindah ke Target Investasi (sekarang kedua).
      expect(find.text(AppStrings.prioritySecond), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('turun di tengah menggeser urutan', (tester) async {
      await _pumpPriority(tester);
      await _tapMove(tester, AppStrings.priorityMoveDown, 0);

      // Kartu pertama kini Mobil Baru (tidak bisa naik),
      // Target Investasi turun ke posisi kedua (bisa naik).
      expect(_upEnabled(tester), [false, true, true, true, true]);
      final mobilDy =
          tester.getTopLeft(find.text('Mobil Baru')).dy;
      final investasiDy =
          tester.getTopLeft(find.text('Target Investasi')).dy;
      expect(mobilDy, lessThan(investasiDy));
      expect(find.text(AppStrings.priorityFirst), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 37: responsivitas prioritas', () {
    testWidgets('tanpa overflow pada lebar 360', (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpPriority(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
