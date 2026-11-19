import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../goals/presentation/utils/goal_category_ui.dart';

/// State No.7: draf target sebagai source of truth (current dianggap 0).
class GoalState extends Equatable {
  const GoalState({
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.targetDate,
    this.customName = '',
    this.isSaving = false,
  });

  final String name;
  final String customName;
  final GoalCategory category;
  final double targetAmount;
  final DateTime targetDate;
  final bool isSaving;

  bool get isOthers => category == GoalCategory.others;
  bool get isNameValid =>
      isOthers ? customName.trim().isNotEmpty : name.trim().isNotEmpty;
  bool get isAmountValid => targetAmount > 0;
  bool get isDateValid => targetDate.isAfter(DateTime.now());
  bool get canContinue =>
      isNameValid && isAmountValid && isDateValid && !isSaving;

  /// (target - current 0) / jumlah bulan. Contoh: 10jt / 8 ≈ 1,25jt.
  double get monthlyContribution =>
      targetAmount / monthsUntil(targetDate);

  GoalState copyWith({
    String? name,
    String? customName,
    GoalCategory? category,
    double? targetAmount,
    DateTime? targetDate,
    bool? isSaving,
  }) {
    return GoalState(
      name: name ?? this.name,
      customName: customName ?? this.customName,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props =>
      [name, customName, category, targetAmount, targetDate, isSaving];
}

/// Controller No.7: kategori, nama, nominal, tanggal, simpan.
/// Tidak mengubah saldo/instrumen — hanya mencatat target.
class GoalController extends Notifier<GoalState> {
  @override
  GoalState build() {
    final saved =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    final goal = saved?.financialGoal;
    final cat = goal?.category ?? GoalCategory.investment;
    final isOthers = cat == GoalCategory.others;
    final custom = isOthers ? (goal?.name ?? '') : '';
    final effectiveName = isOthers
        ? (goal?.name ?? '')
        : (goal?.name.isNotEmpty == true
            ? goal!.name
            : goalCategoryLabel(cat));

    return GoalState(
      name: effectiveName,
      customName: custom,
      category: cat,
      targetAmount: goal?.targetAmount ?? 0,
      targetDate: goal?.deadline ?? DateTime(2027, 6, 30),
    );
  }

  void setCategory(GoalCategory category) {
    if (category == GoalCategory.others) {
      state = state.copyWith(
        category: category,
        name: state.customName,
      );
    } else {
      state = state.copyWith(
        category: category,
        name: goalCategoryLabel(category),
      );
    }
  }

  void setName(String name) {
    if (state.isOthers) {
      state = state.copyWith(
        customName: name,
        name: name,
      );
    } else {
      state = state.copyWith(
        customName: name,
        name: goalCategoryLabel(state.category),
      );
    }
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
      final existingGoal = ref
          .read(onboardingRepositoryProvider)
          .getOnboardingData()
          ?.financialGoal;
      await ref.read(onboardingRepositoryProvider).saveGoal(
            FinancialGoal(
              id: existingGoal?.id ?? 'goal-onboarding',
              name: state.name.trim(),
              targetAmount: state.targetAmount,
              currentAmount: existingGoal?.currentAmount ?? 0,
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

  /// Pulihkan target keuangan tersimpan dari backend agar tidak hilang setelah restart.
  Future<void> loadExisting() async {
    final repo = ref.read(onboardingRepositoryProvider);
    try {
      final goal = await repo.fetchExistingGoal();
      if (goal != null) {
        final isOthers = goal.category == GoalCategory.others;
        final name = isOthers
            ? goal.name
            : (goal.name.isNotEmpty
                ? goal.name
                : goalCategoryLabel(goal.category));
        state = state.copyWith(
          name: name,
          customName: isOthers ? goal.name : state.customName,
          category: goal.category,
          targetAmount: goal.targetAmount,
          targetDate: goal.deadline ?? state.targetDate,
        );
      }
    } catch (_) {}
  }

  /// Reset state (digunakan saat logout / ganti akun).
  void reset() {
    state = GoalState(
      name: goalCategoryLabel(GoalCategory.investment),
      customName: '',
      category: GoalCategory.investment,
      targetAmount: 0,
      targetDate: DateTime(2027, 6, 30),
    );
  }
}

final goalControllerProvider =
    NotifierProvider<GoalController, GoalState>(GoalController.new);
