import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/finance_math.dart';
import '../datasources/remote/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/financial_account.dart';
import '../models/financial_goal.dart';
import '../models/purchase_consideration.dart';
import '../models/transaction_model.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import 'app_providers.dart';
import 'onboarding_providers.dart';

/// Agregat dashboard dari repository existing + kalkulasi murni.
/// Nanti diganti Budget Engine tanpa mengubah UI.
///
/// Sumber per aturan bisnis (lihat finance_math.dart R1–R6):
/// - saldo per akun: initial + aktual akun itu (R1, R2) — HANYA untuk mock mode.
///   Mode remote: backend sudah menghitung saldo aktual per akun, Flutter
///   cukup menjumlahkan `account.balance` tanpa menambahkan transaksi lagi
///   agar tidak terjadi double-counting.
/// - ringkasan: transaksi aktual bulan berjalan (R6)
/// - sisa & aman harian: definisi rencana, tidak berubah (R4, R5)
/// - income: dari `user.monthlyIncome` (backend, lewat AuthController),
///   fallback ke onboarding in-memory jika kosong.
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final user = await ref.watch(dashboardRepositoryProvider).getUser();
  final onboarding =
      ref.watch(onboardingRepositoryProvider).getOnboardingData();
  final repoGoals = await ref.watch(goalRepositoryProvider).getGoals();
  final considerations =
      await ref.watch(purchaseDecisionRepositoryProvider).getConsiderations();
  final notifications =
      await ref.watch(notificationRepositoryProvider).getNotifications();
  // Reaktif terhadap transaksi baru tanpa restart aplikasi.
  final transactions = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();

  // Prioritas sumber monthly income:
  // 1. user.monthlyIncome dari sesi auth (backend-persisted via PUT /user)
  // 2. onboarding in-memory (SalaryController, mock / sebelum simpan)
  // 3. 0 sebagai default aman.
  final authUser = ref.watch(authControllerProvider).user;
  final rawIncome = authUser?.monthlyIncome ?? onboarding?.monthlyIncome ?? 0;
  final income = rawIncome.toDouble();

  // Satu jalur baca akun (lihat AccountRepository): juga menjadi sinyal
  // refresh saat akun berubah, selain perubahan transaksi.
  final accounts = await ref.watch(accountsProvider.future);
  final expenses = onboarding?.recurringExpenses ?? const [];
  final goal = onboarding?.financialGoal;

  bool inCurrentMonth(DateTime date) =>
      date.year == now.year && date.month == now.month;

  bool isTransferCategory(String? category) {
    final cat = category?.toLowerCase().trim();
    return cat == 'transfer' ||
        cat == 'transfer reversal' ||
        cat == 'internal_transfer';
  }

  double actualMonthIncome = 0;
  double actualMonthExpense = 0;
  // Dipakai HANYA untuk mock mode (R1/R2 tidak double-count di remote mode).
  final Map<String, double> incomeByAccount = {};
  final Map<String, double> expenseByAccount = {};
  for (final t in transactions) {
    if (t.accountId != null) {
      if (t.type == TransactionType.income) {
        incomeByAccount[t.accountId!] =
            (incomeByAccount[t.accountId!] ?? 0) + t.amount;
      } else {
        expenseByAccount[t.accountId!] =
            (expenseByAccount[t.accountId!] ?? 0) + t.amount;
      }
    }
    // Transfer internal tidak boleh dihitung sebagai pemasukan/pengeluaran eksternal
    if (!isTransferCategory(t.category) && inCurrentMonth(t.date)) {
      if (t.type == TransactionType.income) {
        actualMonthIncome += t.amount;
      } else {
        actualMonthExpense += t.amount;
      }
    }
  }

  // F06C: Pada mode remote, ambil arus kas bulanan otoritatif dari backend
  // agar tidak terpotong oleh limit 15 transaksi lokal.
  if (ApiConfig.useRemoteApi) {
    try {
      final summary = await ref.watch(summaryProvider.future);
      actualMonthIncome = summary.income;
      actualMonthExpense = summary.expense;
    } catch (_) {
      // Pertahankan kalkulasi jika summaryProvider gagal dimuat
    }
  }

  // R2: jumlahkan saldo per akun.
  // Remote mode: backend sudah menghitung saldo → ambil langsung account.balance
  // agar tidak terjadi double-counting (transaksi sudah teraplikasi di backend).
  // Mock mode: tambahkan transaksi lokal ke initial balance.
  final double totalBalance;
  if (ApiConfig.useRemoteApi) {
    // Backend adalah sumber kebenaran: `balance` sudah termasuk semua transaksi.
    totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);
  } else {
    totalBalance = totalBalanceOf(
      accounts.map(
        (e) => accountBalanceOf(
          initial: e.balance,
          income: incomeByAccount[e.id] ?? 0,
          expense: expenseByAccount[e.id] ?? 0,
        ),
      ),
    );
  }

  // Pembedaan Saldo Siap Transaksi (hanya Bank, Bank Digital, E-Wallet) vs Uang Tunai (Cash legacy)
  final spendableAccounts =
      accounts.where((a) => a.type != AccountType.legacyCash).toList();
  final cashAccounts =
      accounts.where((a) => a.type == AccountType.legacyCash).toList();
  final double spendableBalance =
      spendableAccounts.fold(0.0, (sum, a) => sum + a.balance);
  final double cashLegacyBalance =
      cashAccounts.fold(0.0, (sum, a) => sum + a.balance);
  final bool hasCashLegacy = cashLegacyBalance > 0 || cashAccounts.isNotEmpty;
  final int spendableAccountsCount = spendableAccounts.length;

  double calculateExpensesTotal() {
    if (ApiConfig.useRemoteApi) {
      try {
        final apiExpenses = ref.watch(recurringExpensesProvider).asData?.value;
        if (apiExpenses != null && apiExpenses.isNotEmpty) {
          return apiExpenses
              .where((e) => e.type.toLowerCase() == 'expense' && e.isActive)
              .fold<double>(0.0, (sum, e) => sum + e.amount);
        }
      } catch (_) {}
    }
    return totalExpensesOf(expenses.map((e) => e.monthlyAmount));
  }

  final expensesTotal = calculateExpensesTotal();

  final effectiveGoal = (goal?.deadline != null)
      ? goal
      : (repoGoals.isNotEmpty ? repoGoals.first : goal);
  final goalContribution = effectiveGoal == null || effectiveGoal.deadline == null
      ? 0.0
      : (effectiveGoal.targetAmount - effectiveGoal.currentAmount) /
          monthsUntil(effectiveGoal.deadline!);
  final remaining = remainingFlexible(
    income: income,
    expenses: expensesTotal,
    goalContribution: goalContribution,
  );

  // Model Batas Belanja Harian:
  // Kategori belanja mencakup Kebutuhan Pokok + Pengeluaran Bebas.
  // Investasi, tabungan, dana darurat, dan transfer internal BUKAN pengeluaran belanja harian.
  double safeDaily;
  double safeDailyAverage = 0;
  double todayAllowance = 0;
  double todaySpent = 0;
  bool isTodayOverspent = false;
  bool isDeficit = false;
  bool hasActiveBudget = false;
  bool isBridgeMode = false;
  int daysRemaining = 1;
  DateTime? periodEnd;
  double? periodBudgetCeiling;
  double spendableAllocation = 0;
  double effectiveRemainingFlexible = remaining;

  bool inCurrentDay(DateTime date) =>
      date.year == now.year && date.month == now.month && date.day == now.day;

  bool isSpendableCategory(String? category) {
    if (category == null) return true;
    final cat = category.toLowerCase().trim();
    if (isTransferCategory(cat)) return false;
    if (const [
      'investasi',
      'investment',
      'investasi_tabungan',
      'investasi & tabungan',
      'tabungan',
      'dana_darurat',
      'dana darurat',
      'darurat',
    ].contains(cat)) {
      return false;
    }
    return true;
  }

  if (ApiConfig.useRemoteApi) {
    try {
      final budget = await ref.watch(currentBudgetProvider.future);
      if (budget != null) {
        hasActiveBudget = true;
        safeDaily = budget.effectiveTodayRemaining.toDouble();
        safeDailyAverage = budget.safeDailySpending.toDouble();
        todayAllowance = budget.effectiveTodayAllowance.toDouble();
        todaySpent = budget.effectiveTodaySpent.toDouble();
        isTodayOverspent = budget.isTodayOverspent || safeDaily < 0;
        isDeficit = budget.isDeficit || safeDaily < 0;
        final pokAmount = (budget.kebutuhanPokok?.amount ?? 0).toDouble();
        final bebAmount = (budget.pengeluaranBebas?.amount ?? 0).toDouble();
        spendableAllocation = pokAmount + bebAmount;
        final pokRem = (budget.kebutuhanPokok?.remaining ?? 0).toDouble();
        final bebRem = (budget.pengeluaranBebas?.remaining ?? 0).toDouble();
        effectiveRemainingFlexible = pokRem + bebRem;
        isBridgeMode = budget.isTransition;
        daysRemaining = budget.daysRemaining;
        periodEnd = budget.periodEnd;
        if (isBridgeMode) {
          periodBudgetCeiling = budget.monthlyIncome.toDouble();
        }
      } else {
        hasActiveBudget = false;
        final salaryDay = authUser?.salaryDay ?? onboarding?.salaryDay ?? 25;
        final daysRem = budgetPeriodDaysRemaining(salaryDay, now: now);
        daysRemaining = daysRem;
        periodEnd = budgetPeriodEnd(salaryDay, now: now);
        spendableAllocation = income * 0.55;
        final todaySpendableSpent = transactions
            .where((t) =>
                inCurrentDay(t.date) &&
                t.type == TransactionType.expense &&
                isSpendableCategory(t.category))
            .fold(0.0, (sum, t) => sum + t.amount);
        final baseline = dailySpendingBaseline(
          spendableAllocation: spendableAllocation,
          spentBeforeToday: 0,
          daysRemaining: daysRem,
        );
        todayAllowance = baseline.toDouble();
        todaySpent = todaySpendableSpent;
        safeDaily = dailySpendingRemaining(
          baselineToday: todayAllowance,
          spentToday: todaySpent,
        );
        safeDailyAverage = baseline.toDouble();
        isTodayOverspent = safeDaily < 0;
        isDeficit = safeDaily < 0;
        effectiveRemainingFlexible =
            spendableAllocation - todaySpendableSpent;
      }
    } catch (_) {
      hasActiveBudget = false;
      final salaryDay = authUser?.salaryDay ?? onboarding?.salaryDay ?? 25;
      final daysRem = budgetPeriodDaysRemaining(salaryDay, now: now);
      daysRemaining = daysRem;
      periodEnd = budgetPeriodEnd(salaryDay, now: now);
      spendableAllocation = income * 0.55;
      final todaySpendableSpent = transactions
          .where((t) =>
              inCurrentDay(t.date) &&
              t.type == TransactionType.expense &&
              isSpendableCategory(t.category))
          .fold(0.0, (sum, t) => sum + t.amount);
      final baseline = dailySpendingBaseline(
        spendableAllocation: spendableAllocation,
        spentBeforeToday: 0,
        daysRemaining: daysRem,
      );
      todayAllowance = baseline.toDouble();
      todaySpent = todaySpendableSpent;
      safeDaily = dailySpendingRemaining(
        baselineToday: todayAllowance,
        spentToday: todaySpent,
      );
      safeDailyAverage = baseline.toDouble();
      isTodayOverspent = safeDaily < 0;
      isDeficit = safeDaily < 0;
      effectiveRemainingFlexible = spendableAllocation - todaySpendableSpent;
    }
  } else {
    hasActiveBudget = false;
    // Mode Mock: hitung jatah awal dan kurangi pengeluaran belanja hari ini
    safeDailyAverage = safeDailySpending(remaining: remaining);
    final todayPokokSpent = transactions
        .where((t) =>
            inCurrentDay(t.date) &&
            t.type == TransactionType.expense &&
            isSpendableCategory(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
    todayAllowance = safeDailyAverage;
    todaySpent = todayPokokSpent;
    safeDaily = todayAllowance - todaySpent;
    isTodayOverspent = safeDaily < 0;
    isDeficit = safeDaily < 0;
    spendableAllocation = remaining;
    effectiveRemainingFlexible = remaining;
  }

  // Maksimal 2 goals dari backend.
  final List<FinancialGoal> goals = [
    ?goal,
    ...repoGoals.where((g) => g.id != goal?.id),
  ].take(2).toList();

  // Menunggu = status considering saja (label kartu: "menunggu").
  final pending = considerations
      .where((e) => e.status == ConsiderationStatus.considering)
      .length;

  return DashboardData(
    user: user,
    monthlyIncome: income,
    expensesTotal: expensesTotal,
    goalContribution: goalContribution,
    remainingFlexible: effectiveRemainingFlexible,
    safeDaily: safeDaily,
    safeDailyAverage: safeDailyAverage,
    todayRemaining: safeDaily,
    todayAllowance: todayAllowance,
    todaySpent: todaySpent,
    isTodayOverspent: isTodayOverspent,
    hasActiveBudget: hasActiveBudget,
    spendableAllocation: spendableAllocation,
    isDeficit: isDeficit,
    totalBalance: totalBalance,
    spendableBalance: spendableBalance,
    cashLegacyBalance: cashLegacyBalance,
    hasCashLegacy: hasCashLegacy,
    isBridgeMode: isBridgeMode,
    daysRemaining: daysRemaining,
    periodEnd: periodEnd,
    periodBudgetCeiling: periodBudgetCeiling,
    spendableAccountsCount: spendableAccountsCount,
    actualMonthExpense: actualMonthExpense,
    actualMonthIncome: actualMonthIncome,
    goals: goals,
    pendingCount: pending,
    hasUnread: notifications.any((n) => !n.isRead),
    accountsCount: accounts.length,
  );
});

