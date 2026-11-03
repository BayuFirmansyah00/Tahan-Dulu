import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/api_recurring_transaction.dart';
import '../../../../data/providers/app_providers.dart';

/// Controller fitur Transaksi Berulang (Pemasukan & Pengeluaran Rutin)
/// via RecurringRepository (Laravel API /api/recurring-incomes &
/// /api/recurring-expenses).
class RecurringController {
  RecurringController(this._ref);

  final Ref _ref;

  Future<void> _refreshIncomes() async {
    _ref.invalidate(recurringIncomesProvider);
  }

  Future<void> _refreshExpenses() async {
    _ref.invalidate(recurringExpensesProvider);
  }

  Future<List<ApiRecurringTransaction>> loadIncomes() async {
    return _ref.read(recurringRepositoryProvider).getRecurringIncomes();
  }

  Future<List<ApiRecurringTransaction>> loadExpenses() async {
    return _ref.read(recurringRepositoryProvider).getRecurringExpenses();
  }

  Future<bool> addRecurringIncome({
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    required int instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    try {
      await _ref.read(recurringRepositoryProvider).addRecurringIncome(
            title: title,
            category: category,
            amount: amount,
            frequency: frequency,
            nextDueDate: nextDueDate,
            instrumentId: instrumentId,
            isActive: isActive,
            makeAutomatic: makeAutomatic,
          );
      await _refreshIncomes();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addRecurringExpense({
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    int? instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    try {
      await _ref.read(recurringRepositoryProvider).addRecurringExpense(
            title: title,
            category: category,
            amount: amount,
            frequency: frequency,
            nextDueDate: nextDueDate,
            instrumentId: instrumentId,
            isActive: isActive,
            makeAutomatic: makeAutomatic,
          );
      await _refreshExpenses();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeRecurringIncome(String id) async {
    try {
      await _ref.read(recurringRepositoryProvider).removeRecurringIncome(id);
      await _refreshIncomes();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeRecurringExpense(String id) async {
    try {
      await _ref.read(recurringRepositoryProvider).removeRecurringExpense(id);
      await _refreshExpenses();
      return true;
    } catch (_) {
      return false;
    }
  }

  String formatAmount(int value) => CurrencyFormatter.formatCompact(value.toDouble());
}

final recurringControllerProvider =
    Provider<RecurringController>((ref) => RecurringController(ref));

final recurringIncomesProvider = FutureProvider<List<ApiRecurringTransaction>>((ref) async {
  return ref.read(recurringRepositoryProvider).getRecurringIncomes();
});

final recurringExpensesProvider = FutureProvider<List<ApiRecurringTransaction>>((ref) async {
  return ref.read(recurringRepositoryProvider).getRecurringExpenses();
});
