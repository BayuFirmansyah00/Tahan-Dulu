import 'package:equatable/equatable.dart';

import 'monthly_report.dart';

/// Data respons penuh dari endpoint `GET /api/reports/financial`.
class ApiFinancialReport extends Equatable {
  const ApiFinancialReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    required this.asOfLabel,
    required this.summary,
    required this.scores,
    required this.composition,
    required this.topCategories,
    required this.monthlySeries,
    required this.savedWishlists,
  });

  factory ApiFinancialReport.fromJson(Map<String, dynamic> json) {
    return ApiFinancialReport(
      period: json['period'] as String? ?? 'this_month',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      periodLabel: json['period_label'] as String? ?? '',
      asOfLabel: json['as_of_label'] as String? ?? '',
      summary: FinancialReportSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      scores: FinancialReportScores.fromJson(
        json['scores'] as Map<String, dynamic>? ?? const {},
      ),
      composition: FinancialReportComposition.fromJson(
        json['composition'] as Map<String, dynamic>? ?? const {},
      ),
      topCategories: (json['top_categories'] as List<dynamic>?)
              ?.map((e) =>
                  FinancialReportTopCategory.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      monthlySeries: (json['monthly_series'] as List<dynamic>?)
              ?.map((e) =>
                  FinancialReportMonthlyPoint.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      savedWishlists: (json['saved_wishlists'] as List<dynamic>?)
              ?.map((e) =>
                  FinancialReportSavedWishlist.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
    );
  }

  final String period;
  final String startDate;
  final String endDate;
  final String periodLabel;
  final String asOfLabel;
  final FinancialReportSummary summary;
  final FinancialReportScores scores;
  final FinancialReportComposition composition;
  final List<FinancialReportTopCategory> topCategories;
  final List<FinancialReportMonthlyPoint> monthlySeries;
  final List<FinancialReportSavedWishlist> savedWishlists;

  /// Mengonversi laporan backend ke model UI [MonthlyReport] existing
  /// agar seluruh kartu dan grafik existing di Flutter dapat merender data riil.
  MonthlyReport toMonthlyReport(DateTime month) {
    double? prevInc;
    double? prevExp;
    if (monthlySeries.length >= 2) {
      final prevPoint = monthlySeries[monthlySeries.length - 2];
      prevInc = prevPoint.income;
      prevExp = prevPoint.expense;
    }

    final categoryList = <CategoryTotal>[];
    double sumTop = 0.0;
    for (final tc in topCategories) {
      sumTop += tc.total;
      categoryList.add(
        CategoryTotal(
          label: tc.category,
          amount: tc.total,
          share: summary.totalExpense > 0
              ? tc.total / summary.totalExpense
              : 0.0,
        ),
      );
    }
    final remainder = summary.totalExpense - sumTop;
    if (remainder > 1) {
      categoryList.add(
        CategoryTotal(
          label: 'Lainnya',
          amount: remainder,
          share: summary.totalExpense > 0
              ? remainder / summary.totalExpense
              : 0.0,
        ),
      );
    }

    return MonthlyReport(
      month: month,
      income: summary.totalIncome,
      expense: summary.totalExpense,
      prevIncome: prevInc,
      prevExpense: prevExp,
      categories: categoryList,
      savingsMonth: summary.totalSaving,
      investmentMonth: 0.0,
      savingsTarget: 0.0,
      savingsSaved: summary.totalSaving,
      investmentTarget: 0.0,
      investmentSaved: 0.0,
      lastSix: [
        for (final pt in monthlySeries)
          MonthPoint(
            month: pt.toDateTime(),
            savings: pt.surplus > 0 ? pt.surplus : 0.0,
            investment: 0.0,
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [
        period,
        startDate,
        endDate,
        periodLabel,
        asOfLabel,
        summary,
        scores,
        composition,
        topCategories,
        monthlySeries,
        savedWishlists,
      ];
}

class FinancialReportSummary extends Equatable {
  const FinancialReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSaving,
    required this.savedImpulseAmount,
    required this.savedImpulseCount,
    required this.freeSurplus,
    required this.expenseRatio,
    required this.savingRatio,
    required this.healthScore,
    required this.healthLabel,
  });

  factory FinancialReportSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return FinancialReportSummary(
      totalIncome: parseDouble(json['total_income']),
      totalExpense: parseDouble(json['total_expense']),
      totalSaving: parseDouble(json['total_saving']),
      savedImpulseAmount: parseDouble(json['saved_impulse_amount']),
      savedImpulseCount: parseInt(json['saved_impulse_count']),
      freeSurplus: parseDouble(json['free_surplus']),
      expenseRatio: parseDouble(json['expense_ratio']),
      savingRatio: parseDouble(json['saving_ratio']),
      healthScore: parseInt(json['health_score']),
      healthLabel: json['health_label'] as String? ?? 'Belum Ada Data Transaksi',
    );
  }

  final double totalIncome;
  final double totalExpense;
  final double totalSaving;
  final double savedImpulseAmount;
  final int savedImpulseCount;
  final double freeSurplus;
  final double expenseRatio;
  final double savingRatio;
  final int healthScore;
  final String healthLabel;

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        totalSaving,
        savedImpulseAmount,
        savedImpulseCount,
        freeSurplus,
        expenseRatio,
        savingRatio,
        healthScore,
        healthLabel,
      ];
}

class FinancialReportScores extends Equatable {
  const FinancialReportScores({
    required this.saving,
    required this.needs,
    required this.impulse,
    required this.emergency,
    required this.emergencyMonths,
  });

  factory FinancialReportScores.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return FinancialReportScores(
      saving: parseInt(json['saving']),
      needs: parseInt(json['needs']),
      impulse: parseInt(json['impulse']),
      emergency: parseInt(json['emergency']),
      emergencyMonths: parseDouble(json['emergency_months']),
    );
  }

  final int saving;
  final int needs;
  final int impulse;
  final int emergency;
  final double emergencyMonths;

  @override
  List<Object?> get props => [
        saving,
        needs,
        impulse,
        emergency,
        emergencyMonths,
      ];
}

class FinancialReportComposition extends Equatable {
  const FinancialReportComposition({
    required this.needsAmount,
    required this.needsPct,
    required this.wantsAmount,
    required this.wantsPct,
    required this.socialAmount,
    required this.socialPct,
  });

  factory FinancialReportComposition.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return FinancialReportComposition(
      needsAmount: parseDouble(json['needs_amount']),
      needsPct: parseDouble(json['needs_pct']),
      wantsAmount: parseDouble(json['wants_amount']),
      wantsPct: parseDouble(json['wants_pct']),
      socialAmount: parseDouble(json['social_amount']),
      socialPct: parseDouble(json['social_pct']),
    );
  }

  final double needsAmount;
  final double needsPct;
  final double wantsAmount;
  final double wantsPct;
  final double socialAmount;
  final double socialPct;

  @override
  List<Object?> get props => [
        needsAmount,
        needsPct,
        wantsAmount,
        wantsPct,
        socialAmount,
        socialPct,
      ];
}

class FinancialReportTopCategory extends Equatable {
  const FinancialReportTopCategory({
    required this.category,
    required this.total,
    required this.prevTotal,
    required this.diff,
    required this.pct,
  });

  factory FinancialReportTopCategory.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return FinancialReportTopCategory(
      category: json['category'] as String? ?? 'Lainnya',
      total: parseDouble(json['total']),
      prevTotal: parseDouble(json['prev_total']),
      diff: parseDouble(json['diff']),
      pct: parseDouble(json['pct']),
    );
  }

  final String category;
  final double total;
  final double prevTotal;
  final double diff;
  final double pct;

  @override
  List<Object?> get props => [category, total, prevTotal, diff, pct];
}

class FinancialReportMonthlyPoint extends Equatable {
  const FinancialReportMonthlyPoint({
    required this.label,
    required this.monthYear,
    required this.income,
    required this.expense,
    required this.surplus,
  });

  factory FinancialReportMonthlyPoint.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return FinancialReportMonthlyPoint(
      label: json['label'] as String? ?? '',
      monthYear: json['month_year'] as String? ?? '',
      income: parseDouble(json['income']),
      expense: parseDouble(json['expense']),
      surplus: parseDouble(json['surplus']),
    );
  }

  final String label;
  final String monthYear;
  final double income;
  final double expense;
  final double surplus;

  DateTime toDateTime() {
    try {
      final parts = monthYear.split('-');
      if (parts.length >= 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month);
      }
    } catch (_) {}
    return DateTime.now();
  }

  @override
  List<Object?> get props => [label, monthYear, income, expense, surplus];
}

class FinancialReportSavedWishlist extends Equatable {
  const FinancialReportSavedWishlist({
    required this.id,
    required this.title,
    required this.amount,
    required this.status,
    this.savedAt,
  });

  factory FinancialReportSavedWishlist.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return FinancialReportSavedWishlist(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? json['item_name'] ?? json['name'] ?? '') as String,
      amount: parseDouble(json['amount'] ?? json['price']),
      status: json['status'] as String? ?? json['period'] as String? ?? '',
      savedAt: json['saved_at'] != null
          ? DateTime.tryParse(json['saved_at'].toString())
          : null,
    );
  }

  final int id;
  final String title;
  final double amount;
  final String status;
  final DateTime? savedAt;

  @override
  List<Object?> get props => [id, title, amount, status, savedAt];
}
