import '../../data/models/financial_goal.dart';

/// Mesin kalkulasi Target Keuangan (Tahap 31): satu sumber perhitungan
/// murni untuk Atur Target, Detail Target, dan Simulasi.
///
/// Aturan:
/// - Sisa target = max(0, nominal - terkumpul).
/// - Rekomendasi = sisa / jumlah periode kalender hingga tenggat.
/// - Periode mingguan memakai minggu kalender nyata (7 hari), bukan
///   asumsi "1 bulan = 4 minggu".
/// - Pembulatan selalu KE ATAS per Rp1.000 agar total setoran yang
///   direkomendasikan pasti mencapai target sesuai jadwal.
/// - Tenggat lewat/tidak valid -> null (tanpa bagi-nol, tanpa estimasi
///   menyesatkan). Target tercapai -> rekomendasi 0.
/// - Tanpa asumsi bunga/imbal hasil apa pun.

/// Kelipatan pembulatan Rupiah yang aman untuk rekomendasi setoran.
const int goalRoundingStep = 1000;

/// Sisa target yang masih harus dikumpulkan (tidak pernah negatif).
/// Contoh: target 10jt, terkumpul 3,5jt -> 6,5jt.
double goalRemaining({
  required double target,
  required double collected,
}) =>
    (target - collected).clamp(0, double.infinity).toDouble();

/// Bulatkan [value] KE ATAS ke kelipatan [step].
/// Contoh: 166666.67 -> 167000 (6x setor = 1002000 >= 1000000).
double ceilToStep(double value, [int step = goalRoundingStep]) {
  if (value <= 0 || step <= 0) return 0;
  return ((value + step - 1) ~/ step * step).toDouble();
}

/// Jumlah periode setoran kalender dari [now] hingga [deadline].
/// Null bila tenggat tidak valid (null) atau sudah lewat.
/// Bulanan: bulan kalender (minimal 1 bila tenggat masih di depan).
/// Mingguan: ceil(hari / 7) — minggu kalender nyata.
int? periodsUntil({
  required DateTime? deadline,
  required DepositFrequency frequency,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  if (deadline == null || !deadline.isAfter(current)) return null;
  if (frequency == DepositFrequency.monthly) {
    final months = (deadline.year - current.year) * 12 +
        (deadline.month - current.month) +
        (deadline.day >= current.day ? 1 : 0);
    return months < 1 ? 1 : months;
  }
  final days = deadline.difference(current).inDays;
  if (days < 1) return 1;
  return (days / 7).ceil();
}

/// Rekomendasi nominal setoran per periode.
/// 0 bila target sudah tercapai; null bila tenggat tak valid/sudah lewat.
double? recommendedPerPeriod({
  required double target,
  required double collected,
  required DateTime? deadline,
  required DepositFrequency frequency,
  DateTime? now,
}) {
  final remaining = goalRemaining(target: target, collected: collected);
  if (remaining <= 0) return 0;
  final periods = periodsUntil(
    deadline: deadline,
    frequency: frequency,
    now: now,
  );
  if (periods == null || periods <= 0) return null;
  return ceilToStep(remaining / periods);
}

/// Estimasi tanggal tercapai bila menyetor [perDeposit] tiap periode.
/// Null bila sisa <= 0 (sudah tercapai) atau nominal <= 0 (tak terhitung).
/// Bulanan: tambah N bulan kalender; mingguan: tambah Nx7 hari.
DateTime? estimateReachDate({
  required double target,
  required double collected,
  required double perDeposit,
  required DepositFrequency frequency,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final remaining = goalRemaining(target: target, collected: collected);
  if (remaining <= 0 || perDeposit <= 0) return null;
  final count = (remaining / perDeposit).ceil();
  if (frequency == DepositFrequency.monthly) {
    return DateTime(current.year, current.month + count, current.day);
  }
  return current.add(Duration(days: count * 7));
}
