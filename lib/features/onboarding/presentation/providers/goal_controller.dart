import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../data/datasources/mock/mock_data.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/providers/onboarding_providers.dart';

/// State No.7: draf target sebagai source of truth (current dianggap 0).
class GoalState extends Equatable {
  const GoalState({
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.targetDate,
    this.isSaving = false,
  });

  final String name;
  final GoalCategory category;
  final double targetAmount;
  final DateTime targetDate;
  final bool isSaving;

  bool get isNameValid => name.trim().isNotEmpty;
  bool get isAmountValid => targetAmount > 0;
  bool get isDateValid => targetDate.isAfter(DateTime.now());
  bool get canContinue =>
      isNameValid && isAmountValid && isDateValid && !isSaving;

  /// (target - current 0) / jumlah bulan. Contoh: 10jt / 8 ≈ 1,25jt.
  double get monthlyContribution =>
      targetAmount / monthsUntil(targetDate);

  GoalState copyWith({
    String? name,
    GoalCategory? category,
    double? targetAmount,
    DateTime? targetDate,
    bool? isSaving,
  }) {
    return GoalState(
      name: name ?? this.name,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props =>
      [name, category, targetAmount, targetDate, isSaving];
}

/// Controller No.7: kategori, nama, nominal, tanggal, simpan.
/// Tidak mengubah saldo/instrumen — hanya mencatat target.
class GoalController extends Notifier<GoalState> {
  @override
  GoalState build() {
    final saved =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    final goal = saved?.financialGoal ?? MockData.defaultGoal;
    return GoalState(
      name: goal.name,
      category: goal.category,
      targetAmount: goal.targetAmount,
      targetDate: goal.deadline ?? DateTime(2027, 6, 30),
    );
  }

  void setCategory(GoalCategory category) {
    state = state.copyWith(category: category);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setTargetAmount(double amount) {
    state = state.copyWith(targetAmount: amount);
  }

  void setTargetDate(DateTime date) {
    state = state.copyWith(targetDate: date);
  }

  /// Simpan target. Berhasil -> true (UI ke Dashboard No.8).
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(onboardingRepositoryProvider).saveGoal(
            FinancialGoal(
              id: 'goal-onboarding',
              name: state.name.trim(),
              targetAmount: state.targetAmount,
              currentAmount: 0,
              deadline: state.targetDate,
              category: state.category,
            ),
          );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final goalControllerProvider =
    NotifierProvider<GoalController, GoalState>(GoalController.new);
