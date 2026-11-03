import 'package:equatable/equatable.dart';

class ApiBudgetAllocation extends Equatable {
  const ApiBudgetAllocation({
    required this.id,
    required this.category,
    required this.percentage,
    required this.amount,
    this.spent = 0,
    this.remaining = 0,
  });

  final int id;
  final String category;
  final double percentage;
  final int amount;
  final int spent;
  final int remaining;

  String get categoryLabel {
    switch (category) {
      case 'kebutuhan_pokok':
        return 'Kebutuhan Pokok';
      case 'pengeluaran_bebas':
        return 'Pengeluaran Bebas';
      case 'investasi_tabungan':
        return 'Investasi dan Tabungan';
      case 'dana_darurat':
        return 'Dana Darurat';
      default:
        return category;
    }
  }

  factory ApiBudgetAllocation.fromJson(Map<String, dynamic> json) {
    return ApiBudgetAllocation(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      category: json['category'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      amount: json['amount'] is int ? json['amount'] as int : int.tryParse('${json['amount']}') ?? 0,
      spent: json['spent'] is int ? json['spent'] as int : int.tryParse('${json['spent']}') ?? 0,
      remaining: json['remaining'] is int ? json['remaining'] as int : int.tryParse('${json['remaining']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'percentage': percentage,
        'amount': amount,
        'spent': spent,
        'remaining': remaining,
      };

  @override
  List<Object?> get props => [id, category, percentage, amount, spent, remaining];
}

class ApiMonthlyBudget extends Equatable {
  const ApiMonthlyBudget({
    required this.id,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.daysRemaining,
    required this.monthlyIncome,
    required this.totalAllocationPercentage,
    required this.isActive,
    required this.safeDailySpending,
    required this.isDeficit,
    required this.allocations,
    this.todayRemaining,
    this.todayAllowance,
    this.todaySpent,
    this.isTodayOverspent = false,
  });

  final int id;
  final int userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int daysRemaining;
  final int monthlyIncome;
  final double totalAllocationPercentage;
  final bool isActive;
  final int safeDailySpending;
  final bool isDeficit;
  final List<ApiBudgetAllocation> allocations;

  /// Model Gabungan Uang Aman Hari Ini:
  /// Nilai utama: Sisa jatah belanja khusus hari ini (bisa negatif jika overspent).
  final int? todayRemaining;

  /// Jatah awal hari ini (sebelum ada pengeluaran hari ini).
  final int? todayAllowance;

  /// Total pengeluaran kebutuhan pokok yang terjadi hari ini.
  final int? todaySpent;

  /// Menandakan apakah pengeluaran hari ini telah melebihi jatah hari ini.
  final bool isTodayOverspent;

  /// Getter dengan fallback aman ke [safeDailySpending] bila belum ada field baru
  int get effectiveTodayRemaining => todayRemaining ?? safeDailySpending;
  int get effectiveTodayAllowance => todayAllowance ?? safeDailySpending;
  int get effectiveTodaySpent => todaySpent ?? 0;

  ApiBudgetAllocation? get kebutuhanPokok =>
      allocations.where((a) => a.category == 'kebutuhan_pokok').firstOrNull;

  ApiBudgetAllocation? get pengeluaranBebas =>
      allocations.where((a) => a.category == 'pengeluaran_bebas').firstOrNull;

  ApiBudgetAllocation? get investasiTabungan =>
      allocations.where((a) => a.category == 'investasi_tabungan').firstOrNull;

  ApiBudgetAllocation? get danaDarurat =>
      allocations.where((a) => a.category == 'dana_darurat').firstOrNull;

  factory ApiMonthlyBudget.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'];
    final list = <ApiBudgetAllocation>[];
    if (rawAllocations is List) {
      for (final item in rawAllocations) {
        if (item is Map<String, dynamic>) {
          list.add(ApiBudgetAllocation.fromJson(item));
        }
      }
    }

    final safeDaily = (json['safe_daily_spending'] as num?)?.toInt() ?? 0;
    final todayRem = (json['today_remaining'] as num?)?.toInt() ?? safeDaily;
    final todayAllow = (json['today_allowance'] as num?)?.toInt() ?? safeDaily;
    final todaySpent = (json['today_spent'] as num?)?.toInt() ?? 0;
    final isOverspent = json['is_today_overspent'] == true || (todayRem < 0);

    return ApiMonthlyBudget(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}') ?? 0,
      periodStart: DateTime.tryParse('${json['period_start']}') ?? DateTime.now(),
      periodEnd: DateTime.tryParse('${json['period_end']}') ?? DateTime.now(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 1,
      monthlyIncome: (json['monthly_income'] as num?)?.toInt() ?? 0,
      totalAllocationPercentage: (json['total_allocation_percentage'] as num?)?.toDouble() ?? 100.0,
      isActive: json['is_active'] == true,
      safeDailySpending: safeDaily,
      isDeficit: json['is_deficit'] == true,
      allocations: list,
      todayRemaining: todayRem,
      todayAllowance: todayAllow,
      todaySpent: todaySpent,
      isTodayOverspent: isOverspent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        periodStart,
        periodEnd,
        daysRemaining,
        monthlyIncome,
        totalAllocationPercentage,
        isActive,
        safeDailySpending,
        isDeficit,
        allocations,
        todayRemaining,
        todayAllowance,
        todaySpent,
        isTodayOverspent,
      ];
}
