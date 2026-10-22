import 'package:equatable/equatable.dart';

import 'financial_goal.dart';
import 'financial_instrument.dart';
import 'recurring_expense.dart';

/// Data onboarding No.3–No.7 (dipakai Dashboard No.8).
class OnboardingData extends Equatable {
  const OnboardingData({
    required this.monthlyIncome,
    required this.salaryDay,
    this.financialInstruments = const [],
    this.recurringExpenses = const [],
    this.financialGoal,
  });

  /// Nominal utama (numeric). Contoh: 5000000.
  final double monthlyIncome;

  /// Tanggal gajian 1–31. Contoh: 25.
  final int salaryDay;

  /// Instrumen No.4 beserta pilihannya.
  final List<FinancialInstrument> financialInstruments;

  /// Pengeluaran rutin No.5.
  final List<RecurringExpense> recurringExpenses;

  /// Target keuangan No.7.
  final FinancialGoal? financialGoal;

  OnboardingData copyWith({
    double? monthlyIncome,
    int? salaryDay,
    List<FinancialInstrument>? financialInstruments,
    List<RecurringExpense>? recurringExpenses,
    FinancialGoal? financialGoal,
  }) {
    return OnboardingData(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      salaryDay: salaryDay ?? this.salaryDay,
      financialInstruments: financialInstruments ?? this.financialInstruments,
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      financialGoal: financialGoal ?? this.financialGoal,
    );
  }

  @override
  List<Object?> get props => [
        monthlyIncome,
        salaryDay,
        financialInstruments,
        recurringExpenses,
        financialGoal,
      ];
}
