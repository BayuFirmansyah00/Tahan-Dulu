import 'package:equatable/equatable.dart';

import '../../core/utils/finance_math.dart';

/// Ringkasan rencana keuangan akhir onboarding (No.7 -> ringkasan).
///
/// Menggunakan alokasi riil dari langkah Budget (Kebutuhan Pokok, Pengeluaran Bebas,
/// Investasi & Tabungan, Dana Darurat), sisa belum dialokasikan,
/// komitmen pengeluaran rutin terpisah, serta Batas Belanja Harian dinamis
/// dengan rumus yang sama persis seperti Dashboard dan Backend Laravel.
class FinancialPlan extends Equatable {
  const FinancialPlan({
    required this.monthlyIncome,
    required this.kebutuhanPokok,
    required this.kebutuhanPokokPercent,
    required this.pengeluaranBebas,
    required this.pengeluaranBebasPercent,
    required this.investasiTabungan,
    required this.investasiTabunganPercent,
    required this.danaDarurat,
    required this.danaDaruratPercent,
    required this.unallocated,
    required this.unallocatedPercent,
    required this.daysRemaining,
    required this.dailySpendingLimit,
    required this.goalName,
    required this.goalMonthlyContribution,
    required this.goalTargetAmount,
    required this.recurringExpensesTotal,
  });

  final double monthlyIncome;
  final double kebutuhanPokok;
  final double kebutuhanPokokPercent;
  final double pengeluaranBebas;
  final double pengeluaranBebasPercent;
  final double investasiTabungan;
  final double investasiTabunganPercent;
  final double danaDarurat;
  final double danaDaruratPercent;
  final double unallocated;
  final double unallocatedPercent;
  final int daysRemaining;
  final int dailySpendingLimit;

  /// Nama target (untuk kartu "Target ... Rp... / bulan").
  final String goalName;
  final double goalMonthlyContribution;
  final double goalTargetAmount;

  /// Total pengeluaran rutin (komitmen bulanan, bukan pemotong alokasi).
  final double recurringExpensesTotal;

  // Backward-compatible getters
  double get needs => kebutuhanPokok;
  double get flexible => pengeluaranBebas;
  double get saving => danaDarurat;
  double get investment => investasiTabungan;
  double get safePerDay => dailySpendingLimit.toDouble();

  factory FinancialPlan.fromOnboarding({
    required double monthlyIncome,
    int salaryDay = 25,
    double kebutuhanPokokPercent = 50.0,
    double pengeluaranBebasPercent = 5.0,
    double investasiTabunganPercent = 30.0,
    double danaDaruratPercent = 15.0,
    double recurringExpensesTotal = 0.0,
    String goalName = 'Investasi',
    double goalMonthlyContribution = 0.0,
    double goalTargetAmount = 0.0,
    DateTime? referenceDate,
    double? needsTotal,
  }) {
    final recTotal = recurringExpensesTotal > 0
        ? recurringExpensesTotal
        : (needsTotal ?? 0.0);
    final pokNominal = monthlyIncome * (kebutuhanPokokPercent / 100);
    final bebNominal = monthlyIncome * (pengeluaranBebasPercent / 100);
    final invNominal = monthlyIncome * (investasiTabunganPercent / 100);
    final darNominal = monthlyIncome * (danaDaruratPercent / 100);

    final totalPercent = kebutuhanPokokPercent +
        pengeluaranBebasPercent +
        investasiTabunganPercent +
        danaDaruratPercent;
    final unallocPercent = (100.0 - totalPercent).clamp(0.0, 100.0);
    final unallocNominal = monthlyIncome * (unallocPercent / 100);

    final days = budgetPeriodDaysRemaining(salaryDay, now: referenceDate);
    final spendable = pokNominal + bebNominal;
    final limit = dailySpendingBaseline(
      spendableAllocation: spendable,
      spentBeforeToday: 0,
      daysRemaining: days,
    );

    return FinancialPlan(
      monthlyIncome: monthlyIncome,
      kebutuhanPokok: pokNominal,
      kebutuhanPokokPercent: kebutuhanPokokPercent,
      pengeluaranBebas: bebNominal,
      pengeluaranBebasPercent: pengeluaranBebasPercent,
      investasiTabungan: invNominal,
      investasiTabunganPercent: investasiTabunganPercent,
      danaDarurat: darNominal,
      danaDaruratPercent: danaDaruratPercent,
      unallocated: unallocNominal,
      unallocatedPercent: unallocPercent,
      daysRemaining: days,
      dailySpendingLimit: limit,
      goalName: goalName,
      goalMonthlyContribution: goalMonthlyContribution,
      goalTargetAmount: goalTargetAmount,
      recurringExpensesTotal: recTotal,
    );
  }

  @override
  List<Object?> get props => [
        monthlyIncome,
        kebutuhanPokok,
        kebutuhanPokokPercent,
        pengeluaranBebas,
        pengeluaranBebasPercent,
        investasiTabungan,
        investasiTabunganPercent,
        danaDarurat,
        danaDaruratPercent,
        unallocated,
        unallocatedPercent,
        daysRemaining,
        dailySpendingLimit,
        goalName,
        goalMonthlyContribution,
        goalTargetAmount,
        recurringExpensesTotal,
      ];
}
