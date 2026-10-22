import 'package:equatable/equatable.dart';

/// Total satu kategori pengeluaran + pangsa terhadap total.
class CategoryTotal extends Equatable {
  const CategoryTotal({
    required this.label,
    required this.amount,
    required this.share,
  });

  final String label;
  final double amount;

  /// 0..1 terhadap total pengeluaran periode.
  final double share;

  @override
  List<Object?> get props => [label, amount, share];
}

/// Satu titik bulanan untuk grafik 6 bulan.
class MonthPoint extends Equatable {
  const MonthPoint({
    required this.month,
    required this.savings,
    required this.investment,
  });

  /// Hari pertama bulan berjalan.
  final DateTime month;
  final double savings;
  final double investment;

  @override
  List<Object?> get props => [month, savings, investment];
}

/// Agregat laporan satu bulan kalender (dihitung, bukan disimpan).
///
/// Sumber (terdokumentasi):
/// - income/expense: transaksi aktual pada bulan berjalan.
/// - categories: pengeluaran aktual dikelompokkan label kategori.
/// - savings/investment bulanan: setoran tercatat ke goal berkategori
///   tabungan/investasi pada bulan berjalan (BUKAN transaksi baru,
///   sehingga tidak ganda dengan riwayat transaksi).
/// - target: jumlah targetAmount goal per kategori terkait.
/// - lastSix: 6 bulan terakhir (termasuk bulan aktif), tertua dulu.
/// - prevIncome/prevExpense: bulan sebelumnya; null bila keduanya nol
///   (tidak ada data pembanding yang valid).
class MonthlyReport extends Equatable {
  const MonthlyReport({
    required this.month,
    required this.income,
    required this.expense,
    required this.prevIncome,
    required this.prevExpense,
    required this.categories,
    required this.savingsMonth,
    required this.investmentMonth,
    required this.savingsTarget,
    required this.savingsSaved,
    required this.investmentTarget,
    required this.investmentSaved,
    required this.lastSix,
  });

  final DateTime month;
  final double income;
  final double expense;
  final double? prevIncome;
  final double? prevExpense;
  final List<CategoryTotal> categories;
  final double savingsMonth;
  final double investmentMonth;
  final double savingsTarget;
  final double savingsSaved;
  final double investmentTarget;
  final double investmentSaved;
  final List<MonthPoint> lastSix;

  /// Selisih arus kas: pemasukan - pengeluaran (bisa negatif).
  double get net => income - expense;

  @override
  List<Object?> get props => [
        month,
        income,
        expense,
        prevIncome,
        prevExpense,
        categories,
        savingsMonth,
        investmentMonth,
        savingsTarget,
        savingsSaved,
        investmentTarget,
        investmentSaved,
        lastSix,
      ];
}
