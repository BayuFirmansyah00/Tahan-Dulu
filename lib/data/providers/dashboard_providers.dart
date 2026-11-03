import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/finance_math.dart';
import '../datasources/remote/api_config.dart';
import '../models/dashboard_data.dart';
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

   final expensesTotal =
      totalExpensesOf(expenses.map((e) => e.monthlyAmount));
  final goalContribution = goal == null || goal.deadline == null
      ? 0.0
      : (goal.targetAmount - goal.currentAmount) /
          monthsUntil(goal.deadline!);
  final remaining = remainingFlexible(
    income: income,
    expenses: expensesTotal,
    goalContribution: goalContribution,
  );

  // Model Gabungan Uang Aman Hari Ini:
  // 1. Sisa jatah hari ini (nilai utama dashboard)
  // 2. Batas rata-rata harian terbaru (informasi pendukung)
  double safeDaily;
  double safeDailyAverage = 0;
  double todayAllowance = 0;
  double todaySpent = 0;
  bool isTodayOverspent = false;

  bool inCurrentDay(DateTime date) =>
      date.year == now.year && date.month == now.month && date.day == now.day;

  bool isPokokCategory(String category) {
    final cat = category.toLowerCase().trim();
    return const [
      'food', 'makanan', 'makanan & minuman',
      'transport', 'transportasi',
      'bills', 'tagihan', 'utilitas',
      'education', 'pendidikan',
      'kebutuhan_pokok', 'kebutuhan pokok',
    ].contains(cat);
  }

  if (ApiConfig.useRemoteApi) {
    try {
      final budget = await ref.watch(currentBudgetProvider.future);
      if (budget != null) {
        safeDaily = budget.effectiveTodayRemaining.toDouble();
        safeDailyAverage = budget.safeDailySpending.toDouble();
        todayAllowance = budget.effectiveTodayAllowance.toDouble();
        todaySpent = budget.effectiveTodaySpent.toDouble();
        isTodayOverspent = budget.isTodayOverspent || safeDaily < 0;
      } else {
        safeDailyAverage = safeDailySpending(remaining: remaining);
        final todayPokokSpent = transactions
            .where((t) => inCurrentDay(t.date) && t.type == TransactionType.expense && (t.category == null || isPokokCategory(t.category!)))
            .fold(0.0, (sum, t) => sum + t.amount);
        todayAllowance = safeDailyAverage;
        todaySpent = todayPokokSpent;
        safeDaily = todayAllowance - todaySpent;
        isTodayOverspent = safeDaily < 0;
      }
    } catch (_) {
      safeDailyAverage = safeDailySpending(remaining: remaining);
      final todayPokokSpent = transactions
          .where((t) => inCurrentDay(t.date) && t.type == TransactionType.expense && (t.category == null || isPokokCategory(t.category!)))
          .fold(0.0, (sum, t) => sum + t.amount);
      todayAllowance = safeDailyAverage;
      todaySpent = todayPokokSpent;
      safeDaily = todayAllowance - todaySpent;
      isTodayOverspent = safeDaily < 0;
    }
  } else {
    // Mode Mock: hitung jatah awal dan kurangi pengeluaran kebutuhan pokok hari ini
    safeDailyAverage = safeDailySpending(remaining: remaining);
    final todayPokokSpent = transactions
        .where((t) => inCurrentDay(t.date) && t.type == TransactionType.expense && (t.category == null || isPokokCategory(t.category!)))
        .fold(0.0, (sum, t) => sum + t.amount);
    todayAllowance = safeDailyAverage;
    todaySpent = todayPokokSpent;
    safeDaily = todayAllowance - todaySpent;
    isTodayOverspent = safeDaily < 0;
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
    remainingFlexible: remaining,
    safeDaily: safeDaily,
    safeDailyAverage: safeDailyAverage,
    todayRemaining: safeDaily,
    todayAllowance: todayAllowance,
    todaySpent: todaySpent,
    isTodayOverspent: isTodayOverspent,
    totalBalance: totalBalance,
    actualMonthExpense: actualMonthExpense,
    actualMonthIncome: actualMonthIncome,
    goals: goals,
    pendingCount: pending,
    hasUnread: notifications.any((n) => !n.isRead),
  );
});

