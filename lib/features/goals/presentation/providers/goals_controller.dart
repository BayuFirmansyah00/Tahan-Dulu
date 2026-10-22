import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/goal_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/models/goal_deposit.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/reports_providers.dart';

/// Daftar target terurut prioritas (satu-satunya sumber list).
final goalsListProvider = FutureProvider<List<FinancialGoal>>((ref) async {
  final goals = await ref.watch(goalRepositoryProvider).getGoals();
  final sorted = List.of(goals)
    ..sort((a, b) => a.priority.compareTo(b.priority));
  return sorted;
});

/// Riwayat setoran satu target, terbaru dulu.
final goalDepositsProvider =
    FutureProvider.family<List<GoalDeposit>, String>((ref, goalId) async {
  return ref.watch(goalRepositoryProvider).getDeposits(goalId);
});

/// Label prioritas dari posisi: pertama Tinggi, terakhir Rendah.
String priorityLabel(int index, int total) {
  if (total <= 1 || index == 0) return AppStrings.priorityHigh;
  if (index == total - 1) return AppStrings.priorityLow;
  return AppStrings.priorityMedium;
}

/// Label badge peringkat Prioritas Target (Tahap 37, dari urutan aktual).
/// Tidak memakai progres; posisi >= 3 selalu "Prioritas Lainnya"
/// sehingga berlaku untuk jumlah target berapa pun.
String priorityRankLabel(int index) {
  switch (index) {
    case 0:
      return AppStrings.priorityFirst;
    case 1:
      return AppStrings.prioritySecond;
    case 2:
      return AppStrings.priorityThird;
    default:
      return AppStrings.priorityOthers;
  }
}

/// Draf create → setup (belum disimpan sampai konfirmasi final).
class GoalDraft extends Equatable {
  const GoalDraft({
    this.category,
    this.name = '',
    this.targetAmount = 0,
    this.targetDate,
    this.recurringAmount = 0,
    this.frequency = DepositFrequency.monthly,
    this.sourceAccountId,
  });

  final GoalCategory? category;
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final double recurringAmount;
  final DepositFrequency frequency;
  final String? sourceAccountId;

  bool get isNameValid => name.trim().isNotEmpty;
  bool get isAmountValid => targetAmount > 0;
  bool get isDateValid =>
      targetDate != null && targetDate!.isAfter(DateTime.now());
  bool get isStepOneValid =>
      category != null && isNameValid && isAmountValid && isDateValid;

  GoalDraft copyWith({
    GoalCategory? category,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    double? recurringAmount,
    DepositFrequency? frequency,
    String? sourceAccountId,
  }) {
    return GoalDraft(
      category: category ?? this.category,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      recurringAmount: recurringAmount ?? this.recurringAmount,
      frequency: frequency ?? this.frequency,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
    );
  }

  @override
  List<Object?> get props => [
        category,
        name,
        targetAmount,
        targetDate,
        recurringAmount,
        frequency,
        sourceAccountId,
      ];
}

/// Controller fitur Target: draf, simpan, setoran, prioritas, rencana.
class GoalsController extends Notifier<GoalDraft> {
  bool _saving = false;

  @override
  GoalDraft build() => const GoalDraft();

  void reset() {
    _saving = false;
    state = const GoalDraft();
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

  void setTargetAmountText(String text) {
    setTargetAmount(RupiahInputFormatter.parse(text));
  }

  void setTargetDate(DateTime date) {
    state = state.copyWith(targetDate: date);
  }

  void setRecurringAmount(double amount) {
    state = state.copyWith(recurringAmount: amount);
  }

  void setRecurringAmountText(String text) {
    setRecurringAmount(RupiahInputFormatter.parse(text));
  }

  void setFrequency(DepositFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setSourceAccount(String? accountId) {
    state = state.copyWith(sourceAccountId: accountId);
  }

  /// Setoran per periode yang dibutuhkan (mesin [goal_math]:
  /// minggu kalender nyata, dibulatkan ke atas per Rp1.000 agar
  /// totalnya pasti mencapai target).
  double requiredPerPeriod({
    required double remaining,
    required DateTime targetDate,
    required DepositFrequency frequency,
  }) {
    final periods = periodsUntil(deadline: targetDate, frequency: frequency);
    if (periods == null || periods <= 0 || remaining <= 0) return 0;
    return ceilToStep(remaining / periods);
  }

  /// Simpan target final dari draf. Setengah jalan tidak disimpan.
  Future<FinancialGoal?> saveGoal() async {
    if (_saving || !state.isStepOneValid) return null;
    _saving = true;
    try {
      final existing = await ref.read(goalRepositoryProvider).getGoals();
      final maxPriority = existing.isEmpty
          ? -1
          : existing
              .map((e) => e.priority)
              .reduce((a, b) => a > b ? a : b);
      final saved =
          await ref.read(goalRepositoryProvider).addGoal(
                FinancialGoal(
                  id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
                  name: state.name.trim(),
                  targetAmount: state.targetAmount,
                  currentAmount: 0,
                  deadline: state.targetDate,
                  category: state.category!,
                  recurringAmount: state.recurringAmount,
                  frequency: state.frequency,
                  sourceAccountId: state.sourceAccountId,
                  priority: maxPriority + 1,
                ),
              );
      _refreshGoals();
      return saved;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  /// Ubah field target (edit). Deposito & prioritas tidak tersentuh.
  Future<bool> updateGoalFields({
    required String id,
    required String name,
    required GoalCategory category,
    required double targetAmount,
    required DateTime targetDate,
    required double recurringAmount,
    required DepositFrequency frequency,
    required String? sourceAccountId,
  }) async {
    if (_saving) return false;
    if (name.trim().isEmpty || targetAmount <= 0) return false;
    if (!targetDate.isAfter(DateTime.now())) return false;
    _saving = true;
    try {
      final goals = await ref.read(goalRepositoryProvider).getGoals();
      final existing = goals.firstWhere((e) => e.id == id);
      await ref.read(goalRepositoryProvider).updateGoal(
            existing.copyWith(
              name: name.trim(),
              category: category,
              targetAmount: targetAmount,
              deadline: targetDate,
              recurringAmount: recurringAmount,
              frequency: frequency,
              sourceAccountId: sourceAccountId,
            ),
          );
      _refreshGoals();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Catat setoran (alokasi, bukan pengeluaran). Guard ganda bawaan.
  Future<GoalDeposit?> addDeposit({
    required String goalId,
    required double amount,
    required String? accountId,
  }) async {
    if (_saving || amount <= 0) return null;
    _saving = true;
    try {
      final saved =
          await ref.read(goalRepositoryProvider).addDeposit(
                GoalDeposit(
                  id: 'dep-${DateTime.now().millisecondsSinceEpoch}',
                  goalId: goalId,
                  amount: amount,
                  date: DateTime.now(),
                  accountId: accountId,
                ),
              );
      _refreshGoals();
      ref.invalidate(goalDepositsProvider(goalId));
      return saved;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  /// Simpan rencana simulasi sebagai rencana target (setelah konfirmasi).
  /// [frequency] opsional agar kompatibel dengan pemanggil lama.
  Future<bool> applyPlan({
    required String goalId,
    required double recurringAmount,
    DepositFrequency? frequency,
  }) async {
    if (_saving || recurringAmount <= 0) return false;
    _saving = true;
    try {
      final goals = await ref.read(goalRepositoryProvider).getGoals();
      final existing = goals.firstWhere((e) => e.id == goalId);
      await ref.read(goalRepositoryProvider).updateGoal(
            existing.copyWith(
              recurringAmount: recurringAmount,
              frequency: frequency ?? existing.frequency,
            ),
          );
      _refreshGoals();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Simpan urutan prioritas (daftar id berurutan).
  Future<bool> saveOrder(List<String> orderedIds) async {
    if (_saving) return false;
    _saving = true;
    try {
      await ref.read(goalRepositoryProvider).saveGoalOrder(orderedIds);
      _refreshGoals();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  void _refreshGoals() {
    ref.invalidate(goalsListProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(monthlyReportProvider);
  }
}

final goalsControllerProvider =
    NotifierProvider<GoalsController, GoalDraft>(GoalsController.new);
