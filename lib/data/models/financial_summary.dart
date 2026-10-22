import 'package:equatable/equatable.dart';

/// Ringkasan keuangan untuk Dashboard.
class FinancialSummary extends Equatable {
  const FinancialSummary({
    required this.income,
    required this.expense,
    required this.saving,
    required this.investment,
    required this.remaining,
    required this.flexibleBudget,
    required this.safeSpendingToday,
  });

  final double income;
  final double expense;
  final double saving;
  final double investment;
  final double remaining;
  final double flexibleBudget;
  final double safeSpendingToday;

  @override
  List<Object?> get props => [
        income,
        expense,
        saving,
        investment,
        remaining,
        flexibleBudget,
        safeSpendingToday,
      ];
}
