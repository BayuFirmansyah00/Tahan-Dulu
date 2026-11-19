import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tahan_dulu/data/models/api_financial_report.dart';
import 'package:tahan_dulu/data/repositories/report_repository.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/reports_providers.dart';
import 'package:tahan_dulu/features/reports/export/report_export.dart';

void main() {
  group('ApiFinancialReport Model & Conversion Tests', () {
    test('ApiFinancialReport.fromJson parses complete backend payload correctly', () {
      final json = {
        'period': 'this_month',
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'period_label': 'November 2026',
        'as_of_label': 'Per 30 Nov 2026',
        'summary': {
          'total_income': 10000000.0,
          'total_expense': 4500000.0,
          'total_saving': 2000000.0,
          'saved_impulse_amount': 2500000.0,
          'saved_impulse_count': 3,
          'free_surplus': 3500000.0,
          'expense_ratio': 45.0,
          'saving_ratio': 20.0,
          'health_score': 88,
          'health_label': 'Sangat Baik',
        },
        'scores': {
          'saving': 85,
          'needs': 90,
          'impulse': 95,
          'emergency': 80,
          'emergency_months': 4.5,
        },
        'composition': {
          'needs_amount': 2500000.0,
          'needs_pct': 55.6,
          'wants_amount': 1500000.0,
          'wants_pct': 33.3,
          'social_amount': 500000.0,
          'social_pct': 11.1,
        },
        'top_categories': [
          {'category': 'Makanan & Minuman', 'total': 1200000.0, 'percentage': 26.67},
          {'category': 'Transportasi', 'total': 800000.0, 'percentage': 17.78},
        ],
        'monthly_series': [
          {'label': 'Okt', 'month_year': '2026-10', 'income': 9500000.0, 'expense': 4200000.0, 'surplus': 5300000.0},
          {'label': 'Nov', 'month_year': '2026-11', 'income': 10000000.0, 'expense': 4500000.0, 'surplus': 5500000.0},
        ],
        'saved_wishlists': [
          {'id': 1, 'item_name': 'Sepatu Lari', 'price': 1200000.0, 'period': 'this_month'},
          {'id': 2, 'item_name': 'Smartwatch', 'price': 1300000.0, 'period': 'this_month'},
        ],
      };

      final report = ApiFinancialReport.fromJson(json);

      expect(report.period, 'this_month');
      expect(report.startDate, '2026-11-01');
      expect(report.endDate, '2026-11-30');
      expect(report.summary.totalIncome, 10000000.0);
      expect(report.summary.totalExpense, 4500000.0);
      expect(report.summary.totalSaving, 2000000.0);
      expect(report.summary.savedImpulseAmount, 2500000.0);
      expect(report.summary.savedImpulseCount, 3);
      expect(report.summary.freeSurplus, 3500000.0);
      expect(report.summary.healthScore, 88);
      expect(report.summary.healthLabel, 'Sangat Baik');
      expect(report.scores.saving, 85);
      expect(report.scores.emergencyMonths, 4.5);
      expect(report.composition.needsAmount, 2500000.0);
      expect(report.composition.needsPct, 55.6);
      expect(report.topCategories.length, 2);
      expect(report.topCategories.first.category, 'Makanan & Minuman');
      expect(report.monthlySeries.length, 2);
      expect(report.savedWishlists.length, 2);
      expect(report.savedWishlists.first.title, 'Sepatu Lari');
      expect(report.savedWishlists.first.amount, 1200000.0);
    });

    test('ApiFinancialReport gracefully handles missing / empty payload', () {
      final minimalJson = <String, dynamic>{};

      final report = ApiFinancialReport.fromJson(minimalJson);

      expect(report.period, 'this_month');
      expect(report.summary.totalIncome, 0.0);
      expect(report.summary.totalExpense, 0.0);
      expect(report.summary.healthScore, 0);
      expect(report.topCategories, isEmpty);
      expect(report.monthlySeries, isEmpty);
      expect(report.savedWishlists, isEmpty);
    });

    test('toMonthlyReport converts to Flutter MonthlyReport domain model accurately', () {
      final json = {
        'period': 'this_month',
        'summary': {
          'total_income': 8000000.0,
          'total_expense': 3000000.0,
          'total_saving': 1500000.0,
          'saved_impulse_amount': 500000.0,
          'saved_impulse_count': 1,
          'free_surplus': 3500000.0,
          'expense_ratio': 37.5,
          'saving_ratio': 18.75,
          'health_score': 82,
          'health_label': 'Sangat Baik',
        },
        'top_categories': [
          {'category': 'Makanan', 'total': 1500000.0, 'percentage': 50.0},
        ],
        'monthly_series': [
          {'label': 'Okt', 'month_year': '2026-10', 'income': 7000000.0, 'expense': 2800000.0, 'surplus': 4200000.0},
          {'label': 'Nov', 'month_year': '2026-11', 'income': 8000000.0, 'expense': 3000000.0, 'surplus': 5000000.0},
        ],
      };

      final apiReport = ApiFinancialReport.fromJson(json);
      final monthlyReport = apiReport.toMonthlyReport(DateTime(2026, 11, 1));

      expect(monthlyReport.month.year, 2026);
      expect(monthlyReport.month.month, 11);
      expect(monthlyReport.income, 8000000.0);
      expect(monthlyReport.expense, 3000000.0);
      expect(monthlyReport.prevIncome, 7000000.0);
      expect(monthlyReport.prevExpense, 2800000.0);
      expect(monthlyReport.categories.length, 2);
      expect(monthlyReport.categories.first.label, 'Makanan');
      expect(monthlyReport.categories.first.amount, 1500000.0);
      expect(monthlyReport.categories[1].label, 'Lainnya');
      expect(monthlyReport.categories[1].amount, 1500000.0);
    });
  });

  group('ReportRepository & Providers Tests', () {
    test('MockReportRepository returns non-empty financial report and excel bytes', () async {
      final repo = MockReportRepository();
      final report = await repo.getFinancialReport(period: 'this_month');

      expect(report.period, 'this_month');
      expect(report.summary.totalIncome, greaterThan(0));

      final excelBytes = await repo.exportFinancialReport(period: 'this_month');
      expect(excelBytes, isNotEmpty);
    });

    test('monthlyReportProvider maps data from apiFinancialReportProvider', () async {
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(MockReportRepository()),
        ],
      );
      addTearDown(container.dispose);

      final targetMonth = DateTime(2026, 11, 1);
      final monthly = await container.read(monthlyReportProvider(targetMonth).future);

      expect(monthly.income, greaterThan(0));
      expect(monthly.expense, greaterThan(0));
      expect(monthly.month, targetMonth);
    });
  });

  group('Excel Export Helper Tests', () {
    test('exportReportExcel returns empty when bytes are empty', () async {
      final result = await exportReportExcel(
        bytes: Uint8List(0),
        filename: 'test.xlsx',
      );
      expect(result.ok, isFalse);
      expect(result.message, 'empty');
    });

    test('exportReportExcel delegates to injected shareWith successfully', () async {
      var sharedFilename = '';
      var sharedBytesLength = 0;

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await exportReportExcel(
        bytes: testBytes,
        filename: 'laporan_nov_2026.xlsx',
        shareWith: (bytes, filename) async {
          sharedFilename = filename;
          sharedBytesLength = bytes.length;
          return true;
        },
      );

      expect(result.ok, isTrue);
      expect(sharedFilename, 'laporan_nov_2026.xlsx');
      expect(sharedBytesLength, 5);
    });
  });
}
