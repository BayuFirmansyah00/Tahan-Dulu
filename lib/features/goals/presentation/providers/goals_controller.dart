import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/goal_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/models/goal_deposit.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/reports_providers.dart';

/// Daftar target terurut prioritas (satu-satunya sumber list).
final goalsListProvider = FutureProvider<List<FinancialGoal>>((ref) async {
  final goals = await ref.watch(goalRepositoryProvider).getGoals();
  final sorted = List.of(goals)
    ..sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return a.id.compareTo(b.id);
    });
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
  bool get isDateValid {
    if (targetDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !targetDate!.isBefore(today);
  }
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
      int nextPriority = 0;
      try {
        final existing = await ref.read(goalRepositoryProvider).getGoals();
        if (existing.isNotEmpty) {
          nextPriority = existing
                  .map((e) => e.priority)
                  .reduce((a, b) => a > b ? a : b) +
              1;
        }
      } catch (_) {
        // Jika fetch list gagal, tetap lanjutkan dengan priority 0
        // (backend Laravel akan meng-assign max priority).
        nextPriority = 0;
      }
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
                  priority: nextPriority,
                ),
              );
      _refreshGoals();
      return saved;
    } on ApiException {
      // Error validasi dari backend (422) akan ditangani oleh pemanggil.
      rethrow;
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (targetDate.isBefore(today)) return false;
    _saving = true;
    try {
      FinancialGoal? existing;
      try {
        final goals = await ref.read(goalRepositoryProvider).getGoals();
        existing = goals.where((e) => e.id == id).firstOrNull;
      } catch (_) {
        // Fallback jika fetch list bermasalah
      }
      final goalToUpdate = (existing ??
              FinancialGoal(
                id: id,
                name: name.trim(),
                targetAmount: targetAmount,
                currentAmount: 0,
                deadline: targetDate,
                category: category,
                recurringAmount: recurringAmount,
                frequency: frequency,
                sourceAccountId: sourceAccountId,
              ))
          .copyWith(
        name: name.trim(),
        category: category,
        targetAmount: targetAmount,
        deadline: targetDate,
        recurringAmount: recurringAmount,
        frequency: frequency,
        sourceAccountId: sourceAccountId,
      );
      await ref.read(goalRepositoryProvider).updateGoal(goalToUpdate);
      _refreshGoals();
      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Hapus target keuangan. Riwayat transaksi aktual & saldo akun tidak tersentuh.
  Future<bool> deleteGoal(String id) async {
    if (_saving) return false;
    _saving = true;
    try {
      await ref.read(goalRepositoryProvider).deleteGoal(id);
      _refreshGoals();
      return true;
    } on ApiException {
      rethrow;
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
    String? note,
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
                  note: note,
                  type: 'deposit',
                ),
              );
      _refreshGoals();
      ref.invalidate(goalDepositsProvider(goalId));
      return saved;
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  /// Tarik dana dari target keuangan (F08). Guard ganda bawaan.
  Future<GoalDeposit?> withdrawGoal({
    required String goalId,
    required double amount,
    required String? accountId,
    String? note,
  }) async {
    if (_saving || amount <= 0) return null;
    _saving = true;
    try {
      final saved =
          await ref.read(goalRepositoryProvider).addDeposit(
                GoalDeposit(
                  id: 'wd-${DateTime.now().millisecondsSinceEpoch}',
                  goalId: goalId,
                  amount: amount,
                  date: DateTime.now(),
                  accountId: accountId,
                  note: note,
                  type: 'withdraw',
                ),
              );
      _refreshGoals();
      ref.invalidate(goalDepositsProvider(goalId));
      return saved;
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  /// Koreksi transaksi target (nominal, catatan, instrumen) (F08).
  Future<GoalDeposit?> updateGoalTransaction({
    required GoalDeposit deposit,
  }) async {
    if (_saving || deposit.amount <= 0) return null;
    _saving = true;
    try {
      final saved =
          await ref.read(goalRepositoryProvider).updateDeposit(deposit);
      _refreshGoals();
      ref.invalidate(goalDepositsProvider(deposit.goalId));
      return saved;
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  /// Hapus transaksi target (F08).
  Future<bool> deleteGoalTransaction({
    required String goalId,
    required String depositId,
  }) async {
    if (_saving) return false;
    _saving = true;
    try {
      await ref.read(goalRepositoryProvider).deleteDeposit(depositId);
      _refreshGoals();
      ref.invalidate(goalDepositsProvider(goalId));
      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
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
    String? sourceAccountId,
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
              sourceAccountId: sourceAccountId ?? existing.sourceAccountId,
            ),
          );
      _refreshGoals();
      return true;
    } on ApiException {
      rethrow;
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
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  void _refreshGoals() {
    ref.invalidate(goalsListProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(monthlyReportProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(recentTransactionsProvider);
  }
}

final goalsControllerProvider =
    NotifierProvider<GoalsController, GoalDraft>(GoalsController.new);
