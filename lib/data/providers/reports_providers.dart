import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/financial_goal.dart';
import '../../data/models/goal_deposit.dart';
import '../../data/models/monthly_report.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_providers.dart';

/// Bulan aktif laporan (hari pertama bulan). Navigasi +/- sebulan
/// menangani pergantian tahun via normalisasi DateTime.
class ReportPeriodController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() {
    state = DateTime(state.year, state.month - 1);
  }

  void next() {
    state = DateTime(state.year, state.month + 1);
  }
}

final reportMonthProvider =
    NotifierProvider<ReportPeriodController, DateTime>(
  ReportPeriodController.new,
);

bool _inMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

DateTime _shift(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta);

double _monthSum(
  List<GoalDeposit> deposits,
  DateTime month,
) =>
    deposits
        .where((d) => _inMonth(d.date, month))
        .fold<double>(0, (sum, d) => sum + d.amount);

/// Agregat laporan satu bulan dari sumber yang sama dengan fitur lain.
///
/// Kontrak reaktivitas (terdokumentasi eksplisit): provider ini membaca
/// repository secara langsung agar satu bulan selalu dihitung dari
/// snapshot konsisten. Titik mutasi (simpan transaksi, goal, setoran)
/// WAJIB me-invalidate [monthlyReportProvider] setelah berhasil —
/// lihat pemanggilannya di controller terkait. Tanpa itu, bulan yang
/// sedang dibuka tidak diperbarui.
final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, DateTime>((ref, month) async {
  final transactions =
      await ref.watch(transactionRepositoryProvider).getRecentTransactions();
  final goalRepo = ref.watch(goalRepositoryProvider);
  final goals = await goalRepo.getGoals();

  double income = 0;
  double expense = 0;
  final byCategory = <String, double>{};
  for (final t in transactions) {
    if (!_inMonth(t.date, month)) continue;
    if (t.type == TransactionType.income) {
      income += t.amount;
    } else {
      expense += t.amount;
      final key = (t.category == null || t.category!.isEmpty)
          ? 'Lainnya'
          : t.category!;
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
  }

  final prev = _shift(month, -1);
  double prevIncome = 0;
  double prevExpense = 0;
  for (final t in transactions) {
    if (!_inMonth(t.date, prev)) continue;
    if (t.type == TransactionType.income) {
      prevIncome += t.amount;
    } else {
      prevExpense += t.amount;
    }
  }
  final hasPrev = prevIncome > 0 || prevExpense > 0;

  final depositsByGoal = <String, List<GoalDeposit>>{};
  for (final g in goals) {
    depositsByGoal[g.id] = await goalRepo.getDeposits(g.id);
  }

  bool isSavings(FinancialGoal g) =>
      g.category == GoalCategory.savings;
  bool isInvestment(FinancialGoal g) =>
      g.category == GoalCategory.investment;

  final savingsGoals = goals.where(isSavings).toList();
  final investmentGoals = goals.where(isInvestment).toList();

  double targetOf(List<FinancialGoal> list) =>
      list.fold<double>(0, (sum, g) => sum + g.targetAmount);
  double savedOf(List<FinancialGoal> list) =>
      list.fold<double>(0, (sum, g) => sum + g.currentAmount);
  double depositedIn(List<FinancialGoal> list, DateTime m) {
    var total = 0.0;
    for (final g in list) {
      total += _monthSum(depositsByGoal[g.id] ?? const [], m);
    }
    return total;
  }

  final categories = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return MonthlyReport(
    month: month,
    income: income,
    expense: expense,
    prevIncome: hasPrev ? prevIncome : null,
    prevExpense: hasPrev ? prevExpense : null,
    categories: [
      for (final e in categories)
        CategoryTotal(
          label: e.key,
          amount: e.value,
          share: expense > 0 ? e.value / expense : 0.0,
        ),
    ],
    savingsMonth: depositedIn(savingsGoals, month),
    investmentMonth: depositedIn(investmentGoals, month),
    savingsTarget: targetOf(savingsGoals),
    savingsSaved: savedOf(savingsGoals),
    investmentTarget: targetOf(investmentGoals),
    investmentSaved: savedOf(investmentGoals),
    lastSix: [
      for (var i = 5; i >= 0; i--)
        MonthPoint(
          month: _shift(month, -i),
          savings: depositedIn(savingsGoals, _shift(month, -i)),
          investment: depositedIn(investmentGoals, _shift(month, -i)),
        ),
    ],
  );
});
