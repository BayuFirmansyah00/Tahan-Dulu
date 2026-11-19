import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/dashboard_data.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/financial_plan.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/goal_controller.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/expenses_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/goals_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/plan_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 3 — GoalController Auto-Name & Custom Name Logic', () {
    test('Kategori standar otomatis memakai nama kategori', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(goalControllerProvider.notifier);
      expect(container.read(goalControllerProvider).name, 'Investasi');

      notifier.setCategory(GoalCategory.emergency);
      expect(container.read(goalControllerProvider).name, 'Dana Darurat');

      notifier.setCategory(GoalCategory.house);
      expect(container.read(goalControllerProvider).name, 'Rumah');

      notifier.setCategory(GoalCategory.vehicle);
      expect(container.read(goalControllerProvider).name, 'Kendaraan');
    });

    test('Kategori Lainnya memakai customName dan tersimpan saat berpindah kategori', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(goalControllerProvider.notifier);

      // Pindah ke Lainnya dan ketik nama custom
      notifier.setCategory(GoalCategory.others);
      notifier.setName('Kamera Mirrorless');
      expect(container.read(goalControllerProvider).name, 'Kamera Mirrorless');
      expect(container.read(goalControllerProvider).customName, 'Kamera Mirrorless');
      expect(container.read(goalControllerProvider).isOthers, isTrue);

      // Pindah ke kategori standar: nama jadi nama standar, customName tidak hilang
      notifier.setCategory(GoalCategory.savings);
      expect(container.read(goalControllerProvider).name, 'Tabungan');
      expect(container.read(goalControllerProvider).customName, 'Kamera Mirrorless');
      expect(container.read(goalControllerProvider).isOthers, isFalse);

      // Kembali ke Lainnya: nama otomatis kembali ke customName
      notifier.setCategory(GoalCategory.others);
      expect(container.read(goalControllerProvider).name, 'Kamera Mirrorless');
      expect(container.read(goalControllerProvider).isOthers, isTrue);
    });

    test('Validasi canContinue: standar hanya butuh nominal > 0, Lainnya butuh nama', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(goalControllerProvider.notifier);
      notifier.setCategory(GoalCategory.investment);
      notifier.setTargetDate(DateTime.now().add(const Duration(days: 90)));

      // Nominal 0 -> false
      expect(container.read(goalControllerProvider).canContinue, isFalse);

      // Nominal > 0 pada kategori standar -> true (tanpa perlu input nama manual)
      notifier.setTargetAmount(5000000);
      expect(container.read(goalControllerProvider).canContinue, isTrue);

      // Pindah ke Lainnya dengan customName kosong -> false
      notifier.setCategory(GoalCategory.others);
      notifier.setName('');
      expect(container.read(goalControllerProvider).canContinue, isFalse);

      // Isi customName -> true
      notifier.setName('Beli Drone');
      expect(container.read(goalControllerProvider).canContinue, isTrue);
    });
  });

  group('Fase 3 — Onboarding Screens "Atur Nanti" & UI Rendering', () {
    testWidgets('InstrumentsScreen menampilkan tombol Atur Nanti saat kosong', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InstrumentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tombol Atur Nanti harus ada
      expect(find.text(AppStrings.setupLater), findsOneWidget);
      // Tidak boleh ada error merah
      expect(find.text(AppStrings.noInstrumentError), findsNothing);
    });

    testWidgets('ExpensesScreen menampilkan empty state dan tombol Atur Nanti', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExpensesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state
      expect(find.text(AppStrings.emptyExpensesTitle), findsOneWidget);
      expect(find.text(AppStrings.emptyExpensesSubtitle), findsOneWidget);
      expect(find.text(AppStrings.addExpenseAction), findsOneWidget);
      // Tombol Atur Nanti
      expect(find.text(AppStrings.setupLater), findsOneWidget);
    });

    testWidgets('GoalsScreen menyembunyikan input nama pada kategori standar dan memunculkannya pada Lainnya', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GoalsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default Investasi: field nama tidak muncul
      expect(find.byType(TextField), findsOneWidget); // hanya nominal
      expect(find.text(AppStrings.setupLater), findsOneWidget);

      // Tap chip Lainnya (scroll sampai terlihat jika diperlukan)
      final othersFinder = find.text(AppStrings.goalCatOthers);
      await tester.ensureVisible(othersFinder);
      await tester.pumpAndSettle();
      await tester.tap(othersFinder);
      await tester.pumpAndSettle();

      // Field nama target sekarang muncul
      expect(find.text('Contoh: Membeli Kamera'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // nama & nominal
    });

    testWidgets('PlanScreen merender status "diatur nanti" jika recurring dan goal kosong', (tester) async {
      final emptyPlan = FinancialPlan.fromOnboarding(
        monthlyIncome: 5000000,
        salaryDay: 25,
        kebutuhanPokokPercent: 50,
        pengeluaranBebasPercent: 30,
        investasiTabunganPercent: 20,
        danaDaruratPercent: 0,
        recurringExpensesTotal: 0,
        goalName: '',
        goalMonthlyContribution: 0,
        goalTargetAmount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            financialPlanProvider.overrideWithValue(emptyPlan),
          ],
          child: const MaterialApp(
            home: PlanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pengeluaran rutin (diatur nanti)'), findsOneWidget);
      expect(find.text('Belum diatur (dapat dibuat kapan saja di Dashboard)'), findsOneWidget);
      expect(find.text(AppStrings.startAppButton), findsOneWidget);
    });
  });

  group('Fase 3 — Dashboard & Form Transaksi Tanpa Akun', () {
    testWidgets('DashboardScreen menampilkan kartu "Belum ada akun keuangan" bila accounts kosong', (tester) async {
      final mockData = DashboardData(
        user: const UserModel(id: 'u1', name: 'Budi', email: 'budi@test.com'),
        monthlyIncome: 5000000,
        expensesTotal: 0,
        goalContribution: 0,
        remainingFlexible: 1500000,
        safeDaily: 50000,
        totalBalance: 0,
        actualMonthExpense: 0,
        actualMonthIncome: 0,
        goals: const [],
        pendingCount: 0,
        hasUnread: false,
        accountsCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardDataProvider.overrideWithValue(AsyncData(mockData)),
            transactionsProvider.overrideWithValue(const AsyncData([])),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada akun keuangan'), findsOneWidget);
      expect(find.text('Tambahkan rekening atau e-wallet untuk mulai mencatat saldo'), findsOneWidget);
      expect(find.text('Total Saldo'), findsNothing);
    });

    testWidgets('TransactionFormScreen memblokir simpan dan menampilkan CTA bila belum ada akun', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noAccountTitle), findsOneWidget);
      expect(find.text('Tambah Akun Keuangan'), findsOneWidget);
      expect(find.text('Tambah Akun Terlebih Dahulu'), findsOneWidget);
    });
  });
}
