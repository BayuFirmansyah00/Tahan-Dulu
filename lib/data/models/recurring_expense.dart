import 'package:equatable/equatable.dart';

/// Kategori pengeluaran rutin onboarding No.5.
enum ExpenseCategory { needs, transport, bills, shopping, others }

/// Pengeluaran rutin bulanan (data awal onboarding, bukan transaksi).
class RecurringExpense extends Equatable {
  const RecurringExpense({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyAmount,
  });

  final String id;
  final String name;
  final ExpenseCategory category;

  /// Nominal bulanan (numeric). Contoh: 1500000.
  final double monthlyAmount;

  RecurringExpense copyWith({
    String? id,
    String? name,
    ExpenseCategory? category,
    double? monthlyAmount,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
    );
  }

  @override
  List<Object?> get props => [id, name, category, monthlyAmount];
}
