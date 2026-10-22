import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/recurring_expense.dart';
import '../../../../data/providers/onboarding_providers.dart';

/// State No.5: daftar pengeluaran rutin sebagai source of truth.
class ExpensesState extends Equatable {
  const ExpensesState({required this.expenses, this.isSaving = false});

  final List<RecurringExpense> expenses;
  final bool isSaving;

  double get total =>
      expenses.fold(0, (sum, e) => sum + e.monthlyAmount);

  bool get canContinue => expenses.isNotEmpty && !isSaving;

  ExpensesState copyWith({
    List<RecurringExpense>? expenses,
    bool? isSaving,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [expenses, isSaving];
}

/// Controller No.5: tambah, ubah, hapus, simpan.
/// Data No.3 & No.4 tidak disentuh — repository hanya menulis expenses.
class ExpensesController extends Notifier<ExpensesState> {
  @override
  ExpensesState build() {
    final saved =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    return ExpensesState(
      expenses: List.of(saved?.recurringExpenses ?? const []),
    );
  }

  void addExpense(RecurringExpense expense) {
    state = state.copyWith(expenses: [...state.expenses, expense]);
  }

  void updateExpense(RecurringExpense expense) {
    state = state.copyWith(
      expenses: [
        for (final e in state.expenses)
          if (e.id == expense.id) expense else e,
      ],
    );
  }

  void removeExpense(String id) {
    state = state.copyWith(
      expenses: [for (final e in state.expenses) if (e.id != id) e],
    );
  }

  /// Simpan expenses. Berhasil -> true (UI ke No.7).
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .saveExpenses(state.expenses);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final expensesControllerProvider =
    NotifierProvider<ExpensesController, ExpensesState>(
  ExpensesController.new,
);
