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
  });

  final UserModel user;
  final double monthlyIncome;
  final double expensesTotal;
  final double goalContribution;
  final double remainingFlexible;

  /// Nilai utama: Sisa jatah belanja hari ini (bisa negatif jika overspent).
  final double safeDaily;

  /// Nilai pendukung: Batas rata-rata harian terbaru.
  final double safeDailyAverage;

  /// Alias eksplisit untuk [safeDaily].
  final double? todayRemaining;

  /// Jatah awal hari ini.
  final double todayAllowance;

  /// Pengeluaran kebutuhan pokok hari ini.
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
        actualMonthExpense,
        actualMonthIncome,
        goals,
        pendingCount,
        hasUnread,
      ];
}
