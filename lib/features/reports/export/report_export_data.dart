import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/finance_math.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/models/monthly_report.dart';

/// Satu baris kategori untuk PDF (turunan langsung CategoryTotal).
class ReportCategoryExport extends Equatable {
  const ReportCategoryExport({
    required this.label,
    required this.amount,
    required this.share,
  });

  final String label;
  final double amount;

  /// 0..1 terhadap total pengeluaran.
  final double share;

  String get percentLabel => '${(share * 100).round()}%';
  String get amountLabel => CurrencyFormatter.formatCompact(amount);

  @override
  List<Object?> get props => [label, amount, share];
}

/// Ringkasan target untuk PDF (dari goal + setoran periode berjalan).
class ReportGoalSummary extends Equatable {
  const ReportGoalSummary({
    required this.activeCount,
    required this.reachedCount,
    required this.monthDeposits,
  });

  final int activeCount;
  final int reachedCount;
  final double monthDeposits;

  String get monthDepositsLabel =>
      CurrencyFormatter.formatCompact(monthDeposits);

  @override
  List<Object?> get props => [activeCount, reachedCount, monthDeposits];
}

/// ID laporan unik: TD-YYYY-MM-NNNN (NNN 4 digit dari waktu pembuatan).
String buildReportId(DateTime month, {DateTime? now}) {
  final stamp = now ?? DateTime.now();
  final seq = (stamp.millisecondsSinceEpoch % 9000) + 1000;
  final mm = month.month.toString().padLeft(2, '0');
  return 'TD-${month.year}-$mm-$seq';
}

/// Nama file informatif: laporan_keuangan_2026-10.pdf.
String exportFilename(DateTime month) {
  final mm = month.month.toString().padLeft(2, '0');
  return 'laporan_keuangan_${month.year}-$mm.pdf';
}

/// Isi QR: identitas laporan lokal + periode. Tanpa nominal, merchant,
/// data pribadi, URL, atau klaim verifikasi (belum ada backend).
String qrPayloadFor(String reportId, DateTime month) {
  final mm = month.month.toString().padLeft(2, '0');
  return 'TAHANDULU|$reportId|${month.year}-$mm';
}

/// Payload PDF laporan: SATU perakitan dari provider existing
/// ([MonthlyReport] + daftar goal). Tidak ada sumber data kedua.
class ReportExportData extends Equatable {
  const ReportExportData({
    required this.reportId,
    required this.qrPayload,
    required this.month,
    required this.periodLabel,
    required this.dateRangeLabel,
    required this.generatedLabel,
    required this.income,
    required this.expense,
    required this.net,
    required this.categories,
    required this.goalSummary,
    required this.filename,
  });

  final String reportId;
  final String qrPayload;
  final DateTime month;
  final String periodLabel;
  final String dateRangeLabel;
  final String generatedLabel;
  final double income;
  final double expense;
  final double net;
  final List<ReportCategoryExport> categories;
  final ReportGoalSummary? goalSummary;
  final String filename;

  String get incomeLabel => CurrencyFormatter.formatCompact(income);
  String get expenseLabel => CurrencyFormatter.formatCompact(expense);
  String get netLabel => CurrencyFormatter.formatCompact(net);

  bool get hasExpenseData => expense > 0 && categories.isNotEmpty;

  @override
  List<Object?> get props => [
        reportId,
        qrPayload,
        month,
        periodLabel,
        dateRangeLabel,
        generatedLabel,
        income,
        expense,
        net,
        categories,
        goalSummary,
        filename,
      ];
}

/// Rakit payload dari agregat existing. Nominal amount transaksi
/// (net, sudah mencakup fee — Tahap 17) dipakai apa adanya:
/// TIDAK dijumlahkan ulang dengan fee (anti double-count) dan
/// setoran target TIDAK dihitung sebagai expense (sudah terpisah
/// di MonthlyReport).
ReportExportData buildReportExportData({
  required MonthlyReport report,
  required List<FinancialGoal> goals,
  DateTime? now,
}) {
  final generatedAt = now ?? DateTime.now();
  final month = report.month;
  final reportId = buildReportId(month, now: generatedAt);
  final lastDay = daysInMonth(month);
  final period = DateFormatter.monthYear(month);
  return ReportExportData(
    reportId: reportId,
    qrPayload: qrPayloadFor(reportId, month),
    month: month,
    periodLabel: period,
    dateRangeLabel: '1 - $lastDay $period',
    generatedLabel:
        '${DateFormatter.dayMonthYear(generatedAt)}, '
        '${DateFormatter.hourMinute(generatedAt)} WIB',
    income: report.income,
    expense: report.expense,
    net: report.net,
    categories: [
      for (final c in report.categories)
        ReportCategoryExport(
          label: c.label,
          amount: c.amount,
          share: c.share,
        ),
    ],
    goalSummary: goals.isEmpty
        ? null
        : ReportGoalSummary(
            activeCount: goals.where((g) => !g.isReached).length,
            reachedCount: goals.where((g) => g.isReached).length,
            monthDeposits:
                report.savingsMonth + report.investmentMonth,
          ),
    filename: exportFilename(month),
  );
}
