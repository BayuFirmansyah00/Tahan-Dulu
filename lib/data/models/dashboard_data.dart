import 'package:equatable/equatable.dart';

import 'financial_goal.dart';
import 'user_model.dart';

/// Agregat read-only untuk Home Dashboard (dihitung, bukan disimpan).
class DashboardData extends Equatable {
  const DashboardData({
    required this.user,
    required this.monthlyIncome,
    required this.expensesTotal,
    required this.goalContribution,
    required this.remainingFlexible,
    required this.safeDaily,
    required this.totalBalance,
    required this.actualMonthExpense,
    required this.actualMonthIncome,
    required this.goals,
    required this.pendingCount,
    required this.hasUnread,
    this.safeDailyAverage = 0,
    this.todayRemaining,
    this.todayAllowance = 0,
    this.todaySpent = 0,
    this.isTodayOverspent = false,
    this.hasActiveBudget = true,
    this.spendableAllocation = 0,
    this.isDeficit = false,
    this.accountsCount = 0,
    this.spendableBalance = 0,
    this.cashLegacyBalance = 0,
    this.hasCashLegacy = false,
    this.isBridgeMode = false,
    this.daysRemaining = 1,
    this.periodEnd,
    this.periodBudgetCeiling,
    this.spendableAccountsCount = 0,
  });

  final UserModel user;
  final double monthlyIncome;
  final double expensesTotal;
  final double goalContribution;
  final double remainingFlexible;

  /// Nilai utama: Sisa jatah belanja hari ini (bisa negatif jika overspent/defisit).
  final double safeDaily;

  /// Nilai pendukung: Batas rata-rata harian terbaru.
  final double safeDailyAverage;

  /// Alias eksplisit untuk [safeDaily].
  final double? todayRemaining;

  /// Jatah awal hari ini.
  final double todayAllowance;

  /// Pengeluaran belanja (Pokok + Bebas) hari ini.
  final double todaySpent;

  /// Status kelebihan jatah belanja hari ini.
  final bool isTodayOverspent;

  final double totalBalance;

  /// Aktual bulan berjalan (transaksi nyata, bukan rencana).
  /// Terpisah dari [expensesTotal] (rutin) sesuai R3.
  final double actualMonthExpense;
  final double actualMonthIncome;

  /// Maksimal 2 goal: onboarding dulu, lalu fallback mock.
  final List<FinancialGoal> goals;

  /// Barang TahanDulu menunggu keputusan.
  final int pendingCount;
  final bool hasUnread;

  /// Penanda apakah dashboard memiliki active budget resmi dari backend.
  /// Bila false, dashboard berada dalam mode estimasi / simulasi.
  final bool hasActiveBudget;

  /// Alokasi total yang dapat dibelanjakan (Kebutuhan Pokok + Pengeluaran Bebas).
  final double spendableAllocation;

  /// Status defisit keseluruhan anggaran atau jatah hari ini.
  final bool isDeficit;

  /// Jumlah akun keuangan tersimpan (rekening bank, e-wallet, uang tunai).
  final int accountsCount;

  /// Saldo pada akun aktif yang dapat digunakan untuk transaksi baru (Bank, Digital Bank, E-Wallet).
  final double spendableBalance;

  /// Saldo pada akun Uang Tunai (Cash legacy).
  final double cashLegacyBalance;

  /// Status apakah pengguna memiliki akun Uang Tunai (Cash legacy).
  final bool hasCashLegacy;

  /// Status apakah anggaran berada dalam Periode Transisi (Bridge Mode).
  final bool isBridgeMode;

  /// Sisa hari periode budget aktif.
  final int daysRemaining;

  /// Tanggal akhir siklus budget.
  final DateTime? periodEnd;

  /// Plafon anggaran transisi (jika Bridge Mode aktif).
  final double? periodBudgetCeiling;

  /// Jumlah akun keuangan yang siap untuk transaksi baru.
  final int spendableAccountsCount;

  /// Penanda apakah pengguna sudah memiliki akun keuangan tercatat.
  bool get hasAccounts => accountsCount > 0;

  /// Penanda apakah pengguna memiliki akun siap pakai (Bank / E-Wallet).
  bool get hasSpendableAccounts => spendableAccountsCount > 0;

  @override
  List<Object?> get props => [
        user,
        monthlyIncome,
        expensesTotal,
        goalContribution,
        remainingFlexible,
        safeDaily,
        safeDailyAverage,
        todayRemaining,
        todayAllowance,
        todaySpent,
        isTodayOverspent,
        totalBalance,
        spendableBalance,
        cashLegacyBalance,
        hasCashLegacy,
        isBridgeMode,
        daysRemaining,
        periodEnd,
        periodBudgetCeiling,
        spendableAccountsCount,
        actualMonthExpense,
        actualMonthIncome,
        goals,
        pendingCount,
        hasUnread,
        hasActiveBudget,
        spendableAllocation,
        isDeficit,
        accountsCount,
      ];
}
