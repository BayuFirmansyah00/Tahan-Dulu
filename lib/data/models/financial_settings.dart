import 'package:equatable/equatable.dart';

/// Model informasi transisi / simulasi perubahan tanggal gajian & penghasilan.
class FinancialTransitionInfo extends Equatable {
  const FinancialTransitionInfo({
    required this.currentMonthlyIncome,
    required this.currentSalaryDay,
    required this.proposedMonthlyIncome,
    required this.proposedSalaryDay,
    required this.effectiveDate,
    required this.effectiveDateFormatted,
    required this.hasTransition,
    this.transitionStart,
    this.transitionEnd,
    required this.transitionDays,
    this.suggestedTransitionBudget = 0,
    this.suggestedTransitionBudgetFormatted,
    required this.nextFullPeriodStart,
    required this.nextFullPeriodStartFormatted,
    required this.nextFullPeriodEnd,
    required this.nextFullPeriodEndFormatted,
    required this.note,
  });

  factory FinancialTransitionInfo.fromJson(Map<String, dynamic> json) {
    return FinancialTransitionInfo(
      currentMonthlyIncome: (json['current_monthly_income'] as num?)?.toInt() ?? 0,
      currentSalaryDay: (json['current_salary_day'] as num?)?.toInt() ?? 25,
      proposedMonthlyIncome: (json['proposed_monthly_income'] as num?)?.toInt() ?? 0,
      proposedSalaryDay: (json['proposed_salary_day'] as num?)?.toInt() ?? 25,
      effectiveDate: json['effective_date']?.toString() ?? '',
      effectiveDateFormatted: json['effective_date_formatted']?.toString() ?? '',
      hasTransition: json['has_transition'] == true,
      transitionStart: json['transition_start']?.toString(),
      transitionEnd: json['transition_end']?.toString(),
      transitionDays: (json['transition_days'] as num?)?.toInt() ?? 0,
      suggestedTransitionBudget: (json['suggested_transition_budget'] as num?)?.toInt() ?? 0,
      suggestedTransitionBudgetFormatted: json['suggested_transition_budget_formatted']?.toString(),
      nextFullPeriodStart: json['next_full_period_start']?.toString() ?? '',
      nextFullPeriodStartFormatted: json['next_full_period_start_formatted']?.toString() ?? '',
      nextFullPeriodEnd: json['next_full_period_end']?.toString() ?? '',
      nextFullPeriodEndFormatted: json['next_full_period_end_formatted']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  final int currentMonthlyIncome;
  final int currentSalaryDay;
  final int proposedMonthlyIncome;
  final int proposedSalaryDay;
  final String effectiveDate;
  final String effectiveDateFormatted;
  final bool hasTransition;
  final String? transitionStart;
  final String? transitionEnd;
  final int transitionDays;
  final int suggestedTransitionBudget;
  final String? suggestedTransitionBudgetFormatted;
  final String nextFullPeriodStart;
  final String nextFullPeriodStartFormatted;
  final String nextFullPeriodEnd;
  final String nextFullPeriodEndFormatted;
  final String note;

  Map<String, dynamic> toJson() => {
    'current_monthly_income': currentMonthlyIncome,
    'current_salary_day': currentSalaryDay,
    'proposed_monthly_income': proposedMonthlyIncome,
    'proposed_salary_day': proposedSalaryDay,
    'effective_date': effectiveDate,
    'effective_date_formatted': effectiveDateFormatted,
    'has_transition': hasTransition,
    'transition_start': transitionStart,
    'transition_end': transitionEnd,
    'transition_days': transitionDays,
    'suggested_transition_budget': suggestedTransitionBudget,
    'suggested_transition_budget_formatted': suggestedTransitionBudgetFormatted,
    'next_full_period_start': nextFullPeriodStart,
    'next_full_period_start_formatted': nextFullPeriodStartFormatted,
    'next_full_period_end': nextFullPeriodEnd,
    'next_full_period_end_formatted': nextFullPeriodEndFormatted,
    'note': note,
  };

  @override
  List<Object?> get props => [
    currentMonthlyIncome,
    currentSalaryDay,
    proposedMonthlyIncome,
    proposedSalaryDay,
    effectiveDate,
    effectiveDateFormatted,
    hasTransition,
    transitionStart,
    transitionEnd,
    transitionDays,
    suggestedTransitionBudget,
    suggestedTransitionBudgetFormatted,
    nextFullPeriodStart,
    nextFullPeriodStartFormatted,
    nextFullPeriodEnd,
    nextFullPeriodEndFormatted,
    note,
  ];
}

/// Model periode aktif anggaran saat ini.
class ActivePeriodInfo extends Equatable {
  const ActivePeriodInfo({
    required this.id,
    this.periodStart,
    this.periodEnd,
    required this.daysRemaining,
    required this.monthlyIncome,
    this.monthlyIncomeFormatted,
    required this.isActive,
    this.isTransition = false,
    required this.spendableAllocation,
    required this.safeDailySpending,
    this.allocations,
  });

  factory ActivePeriodInfo.fromJson(Map<String, dynamic> json) {
    return ActivePeriodInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      periodStart: json['period_start']?.toString(),
      periodEnd: json['period_end']?.toString(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      monthlyIncome: (json['monthly_income'] as num?)?.toInt() ?? 0,
      monthlyIncomeFormatted: json['monthly_income_formatted']?.toString(),
      isActive: json['is_active'] == true,
      isTransition: json['is_transition'] == true,
      spendableAllocation: (json['spendable_allocation'] as num?)?.toInt() ?? 0,
      safeDailySpending: (json['safe_daily_spending'] as num?)?.toInt() ?? 0,
      allocations: (json['allocations'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  final int id;
  final String? periodStart;
  final String? periodEnd;
  final int daysRemaining;
  final int monthlyIncome;
  final String? monthlyIncomeFormatted;
  final bool isActive;
  final bool isTransition;
  final int spendableAllocation;
  final int safeDailySpending;
  final List<Map<String, dynamic>>? allocations;

  Map<String, dynamic> toJson() => {
    'id': id,
    'period_start': periodStart,
    'period_end': periodEnd,
    'days_remaining': daysRemaining,
    'monthly_income': monthlyIncome,
    'monthly_income_formatted': monthlyIncomeFormatted,
    'is_active': isActive,
    'is_transition': isTransition,
    'spendable_allocation': spendableAllocation,
    'safe_daily_spending': safeDailySpending,
    'allocations': allocations,
  };

  @override
  List<Object?> get props => [
    id,
    periodStart,
    periodEnd,
    daysRemaining,
    monthlyIncome,
    monthlyIncomeFormatted,
    isActive,
    isTransition,
    spendableAllocation,
    safeDailySpending,
    allocations,
  ];
}

/// Model perubahan rencana keuangan yang sedang menunggu tanggal efektif (pending).
class PendingFinancialChange extends Equatable {
  const PendingFinancialChange({
    required this.hasPending,
    this.pendingMonthlyIncome,
    this.pendingMonthlyIncomeFormatted,
    this.pendingSalaryDay,
    required this.effectiveDate,
    this.effectiveDateFormatted,
    this.transitionBudget,
    this.transitionBudgetFormatted,
    this.transitionConfirmed = false,
    this.transitionInfo,
  });

  factory PendingFinancialChange.fromJson(Map<String, dynamic> json) {
    return PendingFinancialChange(
      hasPending: json['has_pending'] == true,
      pendingMonthlyIncome: (json['pending_monthly_income'] as num?)?.toInt(),
      pendingMonthlyIncomeFormatted: json['pending_monthly_income_formatted']?.toString(),
      pendingSalaryDay: (json['pending_salary_day'] as num?)?.toInt(),
      effectiveDate: json['effective_date']?.toString() ?? '',
      effectiveDateFormatted: json['effective_date_formatted']?.toString(),
      transitionBudget: (json['transition_budget'] as num?)?.toInt(),
      transitionBudgetFormatted: json['transition_budget_formatted']?.toString(),
      transitionConfirmed: json['transition_confirmed'] == true,
      transitionInfo: json['transition_info'] != null && json['transition_info'] is Map<String, dynamic>
          ? FinancialTransitionInfo.fromJson(json['transition_info'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool hasPending;
  final int? pendingMonthlyIncome;
  final String? pendingMonthlyIncomeFormatted;
  final int? pendingSalaryDay;
  final String effectiveDate;
  final String? effectiveDateFormatted;
  final int? transitionBudget;
  final String? transitionBudgetFormatted;
  final bool transitionConfirmed;
  final FinancialTransitionInfo? transitionInfo;

  Map<String, dynamic> toJson() => {
    'has_pending': hasPending,
    'pending_monthly_income': pendingMonthlyIncome,
    'pending_monthly_income_formatted': pendingMonthlyIncomeFormatted,
    'pending_salary_day': pendingSalaryDay,
    'effective_date': effectiveDate,
    'effective_date_formatted': effectiveDateFormatted,
    'transition_budget': transitionBudget,
    'transition_budget_formatted': transitionBudgetFormatted,
    'transition_confirmed': transitionConfirmed,
    'transition_info': transitionInfo?.toJson(),
  };

  @override
  List<Object?> get props => [
    hasPending,
    pendingMonthlyIncome,
    pendingMonthlyIncomeFormatted,
    pendingSalaryDay,
    effectiveDate,
    effectiveDateFormatted,
    transitionBudget,
    transitionBudgetFormatted,
    transitionConfirmed,
    transitionInfo,
  ];
}

/// Model Pengaturan Keuangan Lengkap dari API /api/financial-settings.
class FinancialSettings extends Equatable {
  const FinancialSettings({
    required this.currentMonthlyIncome,
    this.currentMonthlyIncomeFormatted,
    required this.currentSalaryDay,
    this.activePeriod,
    this.pendingChange,
  });

  factory FinancialSettings.fromJson(Map<String, dynamic> json) {
    return FinancialSettings(
      currentMonthlyIncome: (json['current_monthly_income'] as num?)?.toInt() ?? 0,
      currentMonthlyIncomeFormatted: json['current_monthly_income_formatted']?.toString(),
      currentSalaryDay: (json['current_salary_day'] as num?)?.toInt() ?? 25,
      activePeriod: json['active_period'] != null && json['active_period'] is Map<String, dynamic>
          ? ActivePeriodInfo.fromJson(json['active_period'] as Map<String, dynamic>)
          : null,
      pendingChange: json['pending_change'] != null && json['pending_change'] is Map<String, dynamic>
          ? PendingFinancialChange.fromJson(json['pending_change'] as Map<String, dynamic>)
          : null,
    );
  }

  final int currentMonthlyIncome;
  final String? currentMonthlyIncomeFormatted;
  final int currentSalaryDay;
  final ActivePeriodInfo? activePeriod;
  final PendingFinancialChange? pendingChange;

  bool get hasPendingChange => pendingChange != null && pendingChange!.hasPending;

  FinancialSettings copyWith({
    int? currentMonthlyIncome,
    String? currentMonthlyIncomeFormatted,
    int? currentSalaryDay,
    ActivePeriodInfo? activePeriod,
    PendingFinancialChange? pendingChange,
    bool clearPending = false,
  }) {
    return FinancialSettings(
      currentMonthlyIncome: currentMonthlyIncome ?? this.currentMonthlyIncome,
      currentMonthlyIncomeFormatted: currentMonthlyIncomeFormatted ?? this.currentMonthlyIncomeFormatted,
      currentSalaryDay: currentSalaryDay ?? this.currentSalaryDay,
      activePeriod: activePeriod ?? this.activePeriod,
      pendingChange: clearPending ? null : (pendingChange ?? this.pendingChange),
    );
  }

  Map<String, dynamic> toJson() => {
    'current_monthly_income': currentMonthlyIncome,
    'current_monthly_income_formatted': currentMonthlyIncomeFormatted,
    'current_salary_day': currentSalaryDay,
    'active_period': activePeriod?.toJson(),
    'pending_change': pendingChange?.toJson(),
  };

  @override
  List<Object?> get props => [
    currentMonthlyIncome,
    currentMonthlyIncomeFormatted,
    currentSalaryDay,
    activePeriod,
    pendingChange,
  ];
}

