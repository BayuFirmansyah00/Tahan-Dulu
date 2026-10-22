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
  });

  final UserModel user;
  final double monthlyIncome;
  final double expensesTotal;
  final double goalContribution;
  final double remainingFlexible;
  final double safeDaily;
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
        totalBalance,
        actualMonthExpense,
        actualMonthIncome,
        goals,
        pendingCount,
        hasUnread,
      ];
}
