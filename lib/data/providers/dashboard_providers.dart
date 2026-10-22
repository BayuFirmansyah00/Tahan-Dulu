import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/finance_math.dart';
import '../models/dashboard_data.dart';
import '../models/financial_goal.dart';
import '../models/purchase_consideration.dart';
import '../models/transaction_model.dart';
import 'app_providers.dart';
import 'onboarding_providers.dart';

/// Agregat dashboard dari repository existing + kalkulasi murni.
/// Nanti diganti Budget Engine tanpa mengubah UI.
///
/// Sumber per aturan bisnis (lihat finance_math.dart R1–R6):
/// - saldo per akun: initial + aktual akun itu (R1, R2)
/// - ringkasan: transaksi aktual bulan berjalan (R6)
/// - sisa & aman harian: definisi rencana, tidak berubah (R4, R5)
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
  final income = onboarding?.monthlyIncome ?? 0;
  // Satu jalur baca akun (lihat AccountRepository): juga menjadi sinyal
  // refresh saat akun berubah, selain perubahan transaksi.
  final accounts = await ref.watch(accountsProvider.future);
  final expenses = onboarding?.recurringExpenses ?? const [];
  final goal = onboarding?.financialGoal;

  bool inCurrentMonth(DateTime date) =>
      date.year == now.year && date.month == now.month;

  double actualMonthIncome = 0;
  double actualMonthExpense = 0;
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
    if (inCurrentMonth(t.date)) {
      if (t.type == TransactionType.income) {
        actualMonthIncome += t.amount;
      } else {
        actualMonthExpense += t.amount;
      }
    }
  }

  // R2: jumlahkan saldo per akun (initial tidak dihitung ganda).
  // Sumber: daftar akun kanonis (sama dengan fitur Akun).
  final totalBalance = totalBalanceOf(
    accounts.map(
      (e) => accountBalanceOf(
        initial: e.balance,
        income: incomeByAccount[e.id] ?? 0,
        expense: expenseByAccount[e.id] ?? 0,
      ),
    ),
  );

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

  // Onboarding dulu, fallback mock bila kosong. Maksimal 2.
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
    safeDaily: safeDailySpending(remaining: remaining),
    totalBalance: totalBalance,
    actualMonthExpense: actualMonthExpense,
    actualMonthIncome: actualMonthIncome,
    goals: goals,
    pendingCount: pending,
    hasUnread: notifications.any((n) => !n.isRead),
  );
});
