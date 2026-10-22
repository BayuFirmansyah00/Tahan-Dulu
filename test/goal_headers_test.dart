import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_deposit_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_edit_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_history_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_simulate_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goals_list_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_create_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/utils/goal_category_ui.dart';
import 'package:tahan_dulu/features/goals/presentation/widgets/goal_widgets.dart';
import 'dart:io';

import 'package:tahan_dulu/data/providers/app_providers.dart';

Finder _assetImage(String asset) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == asset,
    );

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Repository kosong untuk menguji empty state daftar.
class _EmptyGoalRepository implements GoalRepository {
  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) async => goal;

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async => deposit;

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) async => [];

  @override
  Future<List<FinancialGoal>> getGoals() async => [];

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) async {}

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async => goal;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Tahap 32: pemetaan header dan ikon terpusat', () {
    test('sembilan header ada di disk', () {
      final headers = {
        GoalCategory.emergency: AppAssets.goalHeaderEmergency,
        GoalCategory.savings: AppAssets.goalHeaderSavings,
        GoalCategory.investment: AppAssets.goalHeaderInvestment,
        GoalCategory.house: AppAssets.goalHeaderHouse,
        GoalCategory.vehicle: AppAssets.goalHeaderVehicle,
        GoalCategory.gadget: AppAssets.goalHeaderGadget,
        GoalCategory.holiday: AppAssets.goalHeaderTravel,
        GoalCategory.education: AppAssets.goalHeaderEducation,
        GoalCategory.others: AppAssets.goalHeaderOthers,
      };
      expect(headers.length, GoalCategory.values.length);
      for (final entry in headers.entries) {
        expect(goalHeaderFor(entry.key), entry.value);
        expect(File(entry.value).existsSync(), isTrue,
            reason: entry.value);
      }
    });

    test('sembilan ikon fitur ada di disk', () {
      final icons = [
        AppAssets.goalIconEmergency,
        AppAssets.goalIconSavings,
        AppAssets.goalIconInvestment,
        AppAssets.goalIconHouse,
        AppAssets.goalIconVehicle,
        AppAssets.goalIconGadget,
        AppAssets.goalIconTravel,
        AppAssets.goalIconEducation,
        AppAssets.goalIconOthers,
      ];
      expect(icons.toSet().length, GoalCategory.values.length);
      for (final category in GoalCategory.values) {
        final asset = goalFeatureIconFor(category);
        expect(icons, contains(asset));
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });

    test('ilustrasi empty state tersedia', () {
      expect(File(AppAssets.goalsPiggy).existsSync(), isTrue);
    });
  });

  group('Tahap 32: header dinamis per layar', () {
    testWidgets('GoalHeader merender tiap kategori', (tester) async {
      for (final category in GoalCategory.values) {
        await _pump(tester, GoalHeader(category: category));
        expect(
          _assetImage(goalHeaderFor(category)),
          findsOneWidget,
          reason: '$category',
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('buat target: preview mengikuti kategori', (tester) async {
      await _pump(tester, const GoalCreateScreen());
      expect(_assetImage(AppAssets.goalHeaderHouse), findsNothing);

      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      expect(_assetImage(AppAssets.goalHeaderHouse), findsOneWidget);

      await _tapVisible(tester, find.text(AppStrings.goalCatHoliday));
      expect(_assetImage(AppAssets.goalHeaderTravel), findsOneWidget);
      expect(_assetImage(AppAssets.goalHeaderHouse), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail memakai header kategori target lama', (tester) async {
      await _pump(tester, const GoalDetailScreen(goalId: 'goal-investment'));
      expect(
        _assetImage(AppAssets.goalHeaderInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('deposit memakai ringkasan + ikon kategori', (tester) async {
      await _pump(tester, const GoalDepositScreen(goalId: 'goal-investment'));
      expect(
        _assetImage(AppAssets.goalIconInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('riwayat memakai ringkasan kategori', (tester) async {
      await _pump(tester, const GoalHistoryScreen(goalId: 'goal-investment'));
      expect(
        _assetImage(AppAssets.goalIconInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('simulasi memakai ringkasan kategori', (tester) async {
      await _pump(
        tester,
        const GoalSimulateScreen(goalId: 'goal-investment'),
      );
      expect(
        _assetImage(AppAssets.goalIconInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit memakai header kategori tersimpan', (tester) async {
      await _pump(tester, const GoalEditScreen(goalId: 'goal-investment'));
      expect(
        _assetImage(AppAssets.goalHeaderInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 32: tab daftar dan grup riwayat', () {
    FinancialGoal makeGoal({
      required String id,
      double current = 0,
      DateTime? deadline,
    }) =>
        FinancialGoal(
          id: id,
          name: id,
          targetAmount: 1000000,
          currentAmount: current,
          deadline: deadline,
          category: GoalCategory.savings,
        );

    test('goalsForTab mengklasifikasikan status', () {
      final now = DateTime(2026, 6, 1);
      final items = [
        makeGoal(id: 'aktif', deadline: DateTime(2026, 12, 1)),
        makeGoal(id: 'capai', current: 1000000),
        makeGoal(
          id: 'lewat',
          deadline: DateTime(2026, 1, 1),
        ),
        makeGoal(id: 'tanpa-tenggat'),
      ];
      expect(
        goalsForTab(items, GoalTab.active, now: now).map((e) => e.id),
        ['aktif', 'tanpa-tenggat'],
      );
      expect(
        goalsForTab(items, GoalTab.reached, now: now).map((e) => e.id),
        ['capai'],
      );
      expect(
        goalsForTab(items, GoalTab.overdue, now: now).map((e) => e.id),
        ['lewat'],
      );
    });

    test('groupDepositsByMonth mengelompokkan per bulan', () {
      final deposits = [
        GoalDeposit(
          id: 'a',
          goalId: 'g',
          amount: 100000,
          date: DateTime(2026, 10, 14),
        ),
        GoalDeposit(
          id: 'b',
          goalId: 'g',
          amount: 200000,
          date: DateTime(2026, 10, 1),
        ),
        GoalDeposit(
          id: 'c',
          goalId: 'g',
          amount: 150000,
          date: DateTime(2026, 9, 15),
        ),
      ];
      final grouped = groupDepositsByMonth(deposits);
      expect(grouped.length, 2);
      expect(grouped[0].$1, 'Oktober 2026');
      expect(grouped[0].$2.map((e) => e.id), ['a', 'b']);
      expect(grouped[1].$1, 'September 2026');
    });

    testWidgets('tab menyaring kartu daftar', (tester) async {
      await _pump(tester, const GoalsListScreen());
      // Seed aktif terlihat di tab default.
      expect(find.text('Target Investasi'), findsOneWidget);

      await _tapVisible(
        tester,
        find.text('${AppStrings.goalStatusReached} 0'),
      );
      expect(find.text('Target Investasi'), findsNothing);
      expect(find.text(AppStrings.goalTabEmpty), findsOneWidget);

      await _tapVisible(
        tester,
        find.text('${AppStrings.goalStatusActive} 1'),
      );
      expect(find.text('Target Investasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state ramah dengan CTA pertama', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider
                .overrideWithValue(_EmptyGoalRepository()),
          ],
          child: const MaterialApp(home: GoalsListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(_assetImage(AppAssets.goalsPiggy), findsOneWidget);
      expect(find.text(AppStrings.goalEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.goalEmptySubtitle), findsOneWidget);
      expect(find.text(AppStrings.newGoalAction), findsOneWidget);
      expect(find.text('Target Investasi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 33: ikon aksi dan status', () {
    test('ikon aksi transparan ada di disk', () {
      for (final asset in [
        AppAssets.goalActionWarning,
        AppAssets.goalActionInfo,
        AppAssets.goalActionCalendar,
      ]) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });

    testWidgets('edit memakai grid dan header mengikuti kategori',
        (tester) async {
      await _pump(tester, const GoalEditScreen(goalId: 'goal-investment'));
      expect(find.byType(GridView), findsOneWidget);
      expect(
        _assetImage(AppAssets.goalHeaderInvestment),
        findsOneWidget,
      );

      await _tapVisible(tester, find.text(AppStrings.goalCatVehicle));
      expect(
        _assetImage(AppAssets.goalHeaderVehicle),
        findsOneWidget,
      );
      expect(
        _assetImage(AppAssets.goalHeaderInvestment),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar memakai ikon kalender pada tenggat', (tester) async {
      await _pump(tester, const GoalsListScreen());
      expect(
        _assetImage(AppAssets.goalActionCalendar),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('deposit menampilkan ikon info alokasi', (tester) async {
      await _pump(
        tester,
        const GoalDepositScreen(goalId: 'goal-investment'),
      );
      expect(
        _assetImage(AppAssets.goalActionInfo),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 34: ikon PNG kategori yang benar-benar tampil', () {
    Finder tileFor(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(GoalCategoryTile),
        );

    testWidgets('grid memakai Image.asset paket icons', (tester) async {
      await _pump(tester, const GoalCreateScreen());
      final expected = {
        AppStrings.goalCatEmergency: AppAssets.goalIconEmergency,
        AppStrings.goalCatSavings: AppAssets.goalIconSavings,
        AppStrings.goalCatInvestment: AppAssets.goalIconInvestment,
        AppStrings.goalCatHouse: AppAssets.goalIconHouse,
        AppStrings.goalCatVehicle: AppAssets.goalIconVehicle,
        AppStrings.goalCatGadget: AppAssets.goalIconGadget,
        AppStrings.goalCatHoliday: AppAssets.goalIconTravel,
        AppStrings.goalCatEducation: AppAssets.goalIconEducation,
        AppStrings.goalCatOthers: AppAssets.goalIconOthers,
      };
      for (final entry in expected.entries) {
        expect(
          find.descendant(
            of: tileFor(entry.key),
            matching: _assetImage(entry.value),
          ),
          findsOneWidget,
          reason: entry.key,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rumah menampilkan icon_goal_house.png', (tester) async {
      await _pump(tester, const GoalCreateScreen());
      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      expect(
        find.descendant(
          of: tileFor(AppStrings.goalCatHouse),
          matching: _assetImage(AppAssets.goalIconHouse),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Liburan menampilkan icon_goal_travel.png', (tester) async {
      await _pump(tester, const GoalCreateScreen());
      await _tapVisible(tester, find.text(AppStrings.goalCatHoliday));
      expect(
        find.descendant(
          of: tileFor(AppStrings.goalCatHoliday),
          matching: _assetImage(AppAssets.goalIconTravel),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Investasi menampilkan icon_goal_investment.png', (
      tester,
    ) async {
      await _pump(tester, const GoalCreateScreen());
      expect(
        find.descendant(
          of: tileFor(AppStrings.goalCatInvestment),
          matching: _assetImage(AppAssets.goalIconInvestment),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('kartu daftar memakai ikon kategori PNG', (tester) async {
      await _pump(tester, const GoalsListScreen());
      expect(
        _assetImage(AppAssets.goalIconInvestment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ganti kategori mengubah ikon dan header bersamaan', (
      tester,
    ) async {
      await _pump(tester, const GoalCreateScreen());
      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      expect(_assetImage(AppAssets.goalHeaderHouse), findsOneWidget);
      expect(
        find.descendant(
          of: tileFor(AppStrings.goalCatHouse),
          matching: _assetImage(AppAssets.goalIconHouse),
        ),
        findsOneWidget,
      );

      await _tapVisible(tester, find.text(AppStrings.goalCatHoliday));
      expect(_assetImage(AppAssets.goalHeaderTravel), findsOneWidget);
      expect(_assetImage(AppAssets.goalHeaderHouse), findsNothing);
      expect(
        find.descendant(
          of: tileFor(AppStrings.goalCatHoliday),
          matching: _assetImage(AppAssets.goalIconTravel),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 38: ringkasan dan navigasi prioritas', () {
    testWidgets('ikon prioritas PNG tampil di app bar', (tester) async {
      await _pump(tester, const GoalsListScreen());
      expect(
        _assetImage(AppAssets.priorityNavIcon),
        findsOneWidget,
      );
      expect(
        find.byTooltip(AppStrings.priorityTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ringkasan horizontal satu kartu', (tester) async {
      await _pump(tester, const GoalsListScreen());
      expect(find.text(AppStrings.goalsTotalTarget), findsOneWidget);
      expect(find.text(AppStrings.goalsTotalSaved), findsOneWidget);
      // Persen ringkasan + persen kartu.
      expect(find.text('35%'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 32: responsivitas layar target', () {
    testWidgets('tanpa overflow pada lebar 360', (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final screens = <String, Widget>{
        'create': const GoalCreateScreen(),
        'deposit': const GoalDepositScreen(goalId: 'goal-investment'),
        'history': const GoalHistoryScreen(goalId: 'goal-investment'),
        'simulate': const GoalSimulateScreen(goalId: 'goal-investment'),
        'edit': const GoalEditScreen(goalId: 'goal-investment'),
      };
      for (final entry in screens.entries) {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: entry.value)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });
  });
}
