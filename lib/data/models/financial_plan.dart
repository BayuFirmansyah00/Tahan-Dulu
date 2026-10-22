import 'package:equatable/equatable.dart';

/// Ringkasan rencana keuangan akhir onboarding (No.7 -> ringkasan).
///
/// Aturan mock sementara & transparan (diganti perhitungan real nanti):
/// - kebutuhan = total pengeluaran rutin (data No.5)
/// - tabungan & investasi = baseline kanonis (Rp800rb / Rp500rb)
/// - fleksibel = sisa (income - kebutuhan - tabungan - investasi, min 0)
/// - aman harian = fleksibel / 30 hari
///
/// Dengan data kanonis (5jt / 2,5jt) hasilnya persis desain:
/// 2,5jt + 800rb + 500rb + 1,2jt = 5jt; 1,2jt / 30 = Rp40rb.
class FinancialPlan extends Equatable {
  const FinancialPlan({
    required this.monthlyIncome,
    required this.needs,
    required this.saving,
    required this.investment,
    required this.flexible,
    required this.safePerDay,
    required this.goalName,
  });

  final double monthlyIncome;
  final double needs;
  final double saving;
  final double investment;
  final double flexible;
  final double safePerDay;

  /// Nama target (untuk kartu "Target ... Rp... / bulan").
  final String goalName;

  static const double defaultSaving = 800000;
  static const double defaultInvestment = 500000;
  static const int daysInMonth = 30;

  factory FinancialPlan.fromOnboarding({
    required double monthlyIncome,
    required double needsTotal,
    String goalName = 'Investasi',
  }) {
    final flexible = monthlyIncome -
        needsTotal -
        defaultSaving -
        defaultInvestment;
    final safeFlexible = flexible < 0 ? 0.0 : flexible;
    return FinancialPlan(
      monthlyIncome: monthlyIncome,
      needs: needsTotal,
      saving: defaultSaving,
      investment: defaultInvestment,
      flexible: safeFlexible,
      safePerDay: safeFlexible / daysInMonth,
      goalName: goalName,
    );
  }

  @override
  List<Object?> get props => [
        monthlyIncome,
        needs,
        saving,
        investment,
        flexible,
        safePerDay,
        goalName,
      ];
}
