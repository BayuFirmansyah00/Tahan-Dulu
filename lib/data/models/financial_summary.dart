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
    this.isStale = false,
  });

  final double income;
  final double expense;
  final double saving;
  final double investment;
  final double remaining;
  final double flexibleBudget;
  final double safeSpendingToday;
  final bool isStale;

  FinancialSummary copyWith({
    double? income,
    double? expense,
    double? saving,
    double? investment,
    double? remaining,
    double? flexibleBudget,
    double? safeSpendingToday,
    bool? isStale,
  }) {
    return FinancialSummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      saving: saving ?? this.saving,
      investment: investment ?? this.investment,
      remaining: remaining ?? this.remaining,
      flexibleBudget: flexibleBudget ?? this.flexibleBudget,
      safeSpendingToday: safeSpendingToday ?? this.safeSpendingToday,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [
        income,
        expense,
        saving,
        investment,
        remaining,
        flexibleBudget,
        safeSpendingToday,
        isStale,
      ];
}
