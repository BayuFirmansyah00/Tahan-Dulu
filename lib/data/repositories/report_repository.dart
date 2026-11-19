import '../models/api_financial_report.dart';

/// Kontrak repositori untuk fitur Laporan Keuangan dan Analisis Finansial TahanDulu.
abstract class ReportRepository {
  /// Mengambil data laporan keuangan, rasio 50/30/20, skor kesehatan,
  /// pengeluaran teratas, dan godaan impulsif yang berhasil ditahan.
  Future<ApiFinancialReport> getFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  });

  /// Mengunduh berkas laporan keuangan dalam format Excel (.xlsx).
  Future<List<int>> exportFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  });
}

/// Implementasi mock untuk pengujian terisolasi dan fallback offline.
class MockReportRepository implements ReportRepository {
  MockReportRepository({this.customReport});

  final ApiFinancialReport? customReport;

  @override
  Future<ApiFinancialReport> getFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    if (customReport != null) return customReport!;

    return ApiFinancialReport(
      period: period,
      startDate: startDate ?? '2026-11-01',
      endDate: endDate ?? '2026-11-30',
      periodLabel: 'November 2026',
      asOfLabel: 'Per 30 Nov 2026',
      summary: const FinancialReportSummary(
        totalIncome: 10000000,
        totalExpense: 4500000,
        totalSaving: 2000000,
        savedImpulseAmount: 1500000,
        savedImpulseCount: 3,
        freeSurplus: 3500000,
        expenseRatio: 45.0,
        savingRatio: 55.0,
        healthScore: 88,
        healthLabel: 'Sangat Sehat & Terkendali',
      ),
      scores: const FinancialReportScores(
        saving: 100,
        needs: 92,
        impulse: 96,
        emergency: 100,
        emergencyMonths: 6.0,
      ),
      composition: const FinancialReportComposition(
        needsAmount: 2500000,
        needsPct: 55.6,
        wantsAmount: 1500000,
        wantsPct: 33.3,
        socialAmount: 500000,
        socialPct: 11.1,
      ),
      topCategories: const [
        FinancialReportTopCategory(
          category: 'Makanan',
          total: 1200000,
          prevTotal: 1000000,
          diff: 200000,
          pct: 20.0,
        ),
        FinancialReportTopCategory(
          category: 'Transportasi',
          total: 800000,
          prevTotal: 750000,
          diff: 50000,
          pct: 6.7,
        ),
      ],
      monthlySeries: const [
        FinancialReportMonthlyPoint(
          label: 'Jul',
          monthYear: '2026-07',
          income: 9500000,
          expense: 4200000,
          surplus: 5300000,
        ),
        FinancialReportMonthlyPoint(
          label: 'Agu',
          monthYear: '2026-08',
          income: 9800000,
          expense: 4300000,
          surplus: 5500000,
        ),
        FinancialReportMonthlyPoint(
          label: 'Sep',
          monthYear: '2026-09',
          income: 10000000,
          expense: 4600000,
          surplus: 5400000,
        ),
        FinancialReportMonthlyPoint(
          label: 'Okt',
          monthYear: '2026-10',
          income: 10000000,
          expense: 4400000,
          surplus: 5600000,
        ),
        FinancialReportMonthlyPoint(
          label: 'Nov',
          monthYear: '2026-11',
          income: 10000000,
          expense: 4500000,
          surplus: 5500000,
        ),
      ],
      savedWishlists: [
        FinancialReportSavedWishlist(
          id: 1,
          title: 'Headphone Sony WH-1000XM5',
          amount: 1500000,
          status: 'cancelled',
          savedAt: DateTime.parse('2026-11-15T10:00:00Z'),
        ),
      ],
    );
  }

  @override
  Future<List<int>> exportFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    return <int>[80, 75, 3, 4]; // Dummy zip/xlsx signature
  }
}
