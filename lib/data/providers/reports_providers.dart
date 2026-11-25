import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/remote/api_config.dart';
import '../models/api_financial_report.dart';
import '../../data/models/financial_goal.dart';
import '../../data/models/goal_deposit.dart';
import '../../data/models/monthly_report.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_providers.dart';

/// Mode periode laporan: 'monthly' atau 'quarter'.
class ReportPeriodModeNotifier extends Notifier<String> {
  @override
  String build() => 'monthly';

  void setMode(String mode) => state = mode;
}

final reportPeriodModeProvider =
    NotifierProvider<ReportPeriodModeNotifier, String>(
  ReportPeriodModeNotifier.new,
);

/// Provider data laporan keuangan langsung dari backend Laravel `GET /api/reports/financial`.
final apiFinancialReportProvider =
    FutureProvider.family<ApiFinancialReport, DateTime>((ref, month) async {
  final repo = ref.watch(reportRepositoryProvider);
  final mode = ref.watch(reportPeriodModeProvider);
  if (mode == 'quarter') {
    return await repo.getFinancialReport(period: 'quarter');
  }

  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final isLastMonth = month.year == (now.month == 1 ? now.year - 1 : now.year) &&
      month.month == (now.month == 1 ? 12 : now.month - 1);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;

  final startDate =
      '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
  final endDate =
      '${month.year}-${month.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

  final period = isCurrentMonth
      ? 'this_month'
      : (isLastMonth ? 'last_month' : 'custom');

  return await repo.getFinancialReport(
    period: period,
    startDate: (isCurrentMonth || isLastMonth) ? null : startDate,
    endDate: (isCurrentMonth || isLastMonth) ? null : endDate,
  );
});

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

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void setThisMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }

  void setLastMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month - 1);
  }

  void setQuarter() {
    final now = DateTime.now();
    final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    state = DateTime(now.year, quarterStartMonth);
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

/// Agregat laporan satu bulan.
///
/// Jika [ApiConfig.useRemoteApi] aktif, data diambil langsung dari endpoint
/// Laravel `GET /api/reports/financial` dan dikonversi ke [MonthlyReport].
/// Kegagalan jaringan atau server pada mode remote TIDAK disamarkan dengan
/// kalkulasi parsial 15 transaksi lokal demi menjaga integritas data keuangan.
final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, DateTime>((ref, month) async {
  if (ApiConfig.useRemoteApi) {
    final apiReport =
        await ref.watch(apiFinancialReportProvider(month).future);
    return apiReport.toMonthlyReport(month);
  }

  final transactions =
      await ref.watch(transactionRepositoryProvider).getRecentTransactions();
  final goalRepo = ref.watch(goalRepositoryProvider);
  final goals = await goalRepo.getGoals();

  bool isTransferCategory(String? category) {
    final cat = category?.toLowerCase().trim();
    return cat == 'transfer' ||
        cat == 'transfer reversal' ||
        cat == 'internal_transfer';
  }

  double income = 0;
  double expense = 0;
  final byCategory = <String, double>{};
  for (final t in transactions) {
    if (!_inMonth(t.date, month)) continue;
    if (isTransferCategory(t.category)) continue;

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
    if (isTransferCategory(t.category)) continue;

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
