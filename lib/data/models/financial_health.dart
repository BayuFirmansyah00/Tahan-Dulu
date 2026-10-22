import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_formatter.dart';

/// Tingkat kesehatan keuangan (aturan transparan, bukan nasihat pro).
enum HealthLevel { healthy, fair, poor, insufficient }

/// Satu indikator beserta skor 0..100 (null = data tak cukup).
class HealthIndicator extends Equatable {
  const HealthIndicator({
    required this.title,
    required this.detail,
    required this.score,
  });

  final String title;
  final String detail;
  final double? score;

  @override
  List<Object?> get props => [title, detail, score];
}

/// Hasil evaluasi kesehatan: skor 0..100 + level + indikator.
class HealthScore extends Equatable {
  const HealthScore({
    required this.score,
    required this.level,
    required this.indicators,
  });

  final int score;
  final HealthLevel level;
  final List<HealthIndicator> indicators;

  @override
  List<Object?> get props => [score, level, indicators];
}

String _pct(double ratio) => '${(ratio * 100).round()}%';

/// Aturan penilaian transparan (terdokumentasi, diuji):
/// - Pengeluaran terkendali: 1 - expense/income (null bila income <= 0).
/// - Tabungan berjalan: progres tabungan 0..1 (null bila tanpa target).
/// - Sisa anggaran: 100 bila remaining > 0, 0 bila <= 0, null bila
///   tanpa aktivitas sama sekali (income == 0 && expense == 0).
/// - Progres target: rata-rata progres goals (null bila tanpa goals).
/// Skor = rata-rata indikator tersedia; < 2 indikator -> insufficient.
/// Sehat >= 75, Cukup >= 50, selainnya Perlu Perhatian.
HealthScore evaluateFinancialHealth({
  required double monthIncome,
  required double monthExpense,
  double? savingsProgress,
  required double remaining,
  double? goalProgress,
}) {
  final indicators = <HealthIndicator>[];

  double? spending;
  String spendingDetail;
  if (monthIncome <= 0) {
    spendingDetail = 'Belum ada pemasukan tercatat bulan ini.';
  } else {
    spending = (1 - monthExpense / monthIncome).clamp(0.0, 1.0).toDouble();
    spendingDetail = monthExpense <= monthIncome
        ? 'Dalam batas yang direncanakan'
        : 'Melebihi pemasukan bulan ini';
  }
  indicators.add(
    HealthIndicator(
      title: 'Pengeluaran terkendali',
      detail: spendingDetail,
      score: spending == null ? null : spending * 100,
    ),
  );

  if (savingsProgress != null) {
    indicators.add(
      HealthIndicator(
        title: 'Tabungan berjalan',
        detail: '${_pct(savingsProgress)} dari target',
        score: (savingsProgress.clamp(0.0, 1.0)) * 100,
      ),
    );
  } else {
    indicators.add(
      const HealthIndicator(
        title: 'Tabungan berjalan',
        detail: 'Belum ada target tabungan.',
        score: null,
      ),
    );
  }

  double? budget;
  String budgetDetail;
  if (monthIncome == 0 && monthExpense == 0) {
    budgetDetail = 'Belum ada aktivitas bulan ini.';
  } else if (remaining > 0) {
    budget = 100;
    budgetDetail =
        'Masih memiliki sisa anggaran ${CurrencyFormatter.formatCompact(remaining)}';
  } else {
    budget = 0;
    budgetDetail = 'Anggaran bulan ini habis.';
  }
  indicators.add(
    HealthIndicator(
      title: 'Sisa anggaran tersedia',
      detail: budgetDetail,
      score: budget,
    ),
  );

  if (goalProgress != null) {
    indicators.add(
      HealthIndicator(
        title: 'Progres target',
        detail: '${_pct(goalProgress)} tercapai',
        score: goalProgress.clamp(0.0, 1.0) * 100,
      ),
    );
  } else {
    indicators.add(
      const HealthIndicator(
        title: 'Progres target',
        detail: 'Belum ada target keuangan.',
        score: null,
      ),
    );
  }

  final available =
      indicators.where((e) => e.score != null).map((e) => e.score!).toList();
  if (available.length < 2) {
    return HealthScore(
      score: 0,
      level: HealthLevel.insufficient,
      indicators: indicators,
    );
  }
  final average = available.reduce((a, b) => a + b) / available.length;
  final level = average >= 75
      ? HealthLevel.healthy
      : average >= 50
          ? HealthLevel.fair
          : HealthLevel.poor;
  return HealthScore(
    score: average.round(),
    level: level,
    indicators: indicators,
  );
}

/// Label kondisi untuk skor.
String healthLevelLabel(HealthLevel level) {
  switch (level) {
    case HealthLevel.healthy:
      return 'Sehat';
    case HealthLevel.fair:
      return 'Cukup';
    case HealthLevel.poor:
      return 'Perlu Perhatian';
    case HealthLevel.insufficient:
      return 'Data belum cukup';
  }
}
