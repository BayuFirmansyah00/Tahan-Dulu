/// Matematika keuangan murni & deterministik untuk Dashboard.
/// Terpisah dari widget agar mudah diganti Budget Engine nanti.
library;

/// Jumlah bulan kalender dari [now] menuju [date], minimal 1.
int monthsUntil(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final months = (date.year - current.year) * 12 +
      (date.month - current.month) +
      (date.day >= current.day ? 0 : -1);
  return months < 1 ? 1 : months;
}

/// Jumlah hari dalam bulan berjalan.
int daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

/// Total saldo = jumlah saldo awal semua instrumen.
double totalBalanceOf(Iterable<double> balances) =>
    balances.fold(0, (sum, e) => sum + e);

// ---------------------------------------------------------------------------
// Aturan bisnis Financial Engine (Tahap 8, didokumentasikan eksplisit).
//
// R1. Saldo akun saat ini = saldo awal + pemasukan aktual akun itu
//     - pengeluaran aktual akun itu. Hanya transaksi dengan accountId
//     yang cocok yang dihitung; transaksi tanpa akun cocok diabaikan
//     (tidak error, tidak menempel ke akun lain).
// R2. Total saldo = jumlah saldo per akun (dihitung per akun dulu,
//     lalu dijumlahkan) sehingga saldo awal tidak dihitung ganda.
// R3. Pengeluaran rutin (rencana) BUKAN pengeluaran aktual. Keduanya
//     dilaporkan terpisah dan tidak pernah dijumlahkan.
// R4. Sisa fleksibel tetap definisi rencana: income - rutin - kontribusi.
//     Tidak diubah demi angka tampilan.
// R5. Aman harian memakai sisa + bulan kalender berjalan, floor Rp1.000.
// R6. Ringkasan bulanan memakai transaksi aktual pada bulan kalender
//     berjalan (berdasarkan tanggal transaksi).
// R7. Biaya tambahan transaksi (Tahap 17, opsional, default Rp0):
//     - pengeluaran: uang keluar = nominal + biaya.
//     - pemasukan: uang bersih masuk = nominal − biaya (tidak boleh ≤ 0).
//     - amount tersimpan SELALU nilai bersih; fee hanya rincian tampilan
//       dan tidak pernah dijumlahkan lagi di agregat (anti double-count).
//     - fee Rp0 → perilaku identik dengan sebelum Tahap 17.
//     - Biaya admin bulanan akun (monthlyAdminFee) entitas TERPISAH:
//       hanya tampil di onboarding, tidak pernah dipotong otomatis per
//       transaksi (belum ada alur pencatatannya).
// Gap terdokumentasi: model TIDAK mengenal transfer (hanya income/
// expense), jadi tidak ada risiko salah hitung transfer; edit & hapus
// transaksi belum tersedia (dependensi tahap berikutnya).
// ---------------------------------------------------------------------------

/// Saldo satu akun setelah transaksi aktualnya (murni, tanpa import model).
double accountBalanceOf({
  required double initial,
  required double income,
  required double expense,
}) =>
    initial + income - expense;

/// Uang keluar transaksi pengeluaran = nominal + biaya (R7).
/// Contoh: 100.000 + 2.500 = 102.500.
double expenseOutflow({required double amount, required double fee}) =>
    amount + fee;

/// Uang bersih masuk transaksi pemasukan = nominal − biaya (R7).
/// Contoh: 100.000 − 2.500 = 97.500. Negatif berarti tidak valid.
double incomeInflow({required double amount, required double fee}) =>
    amount - fee;

/// Satu titik perhitungan bersih (R7) agar UI tidak menduplikasi rumus.
double netTransactionAmount({
  required bool isExpense,
  required double amount,
  required double fee,
}) =>
    isExpense
        ? expenseOutflow(amount: amount, fee: fee)
        : incomeInflow(amount: amount, fee: fee);

/// Estimasi mundur target (hari) bila membeli seharga [price] dengan
/// kontribusi bulanan [monthlyContribution]. Null bila tak terhitung.
/// Contoh: 750rb / 1,25jt x 30 hari = 18 hari.
int? targetDelayDays({
  required double price,
  required double monthlyContribution,
}) {
  if (price <= 0 || monthlyContribution <= 0) return null;
  return (price / monthlyContribution * 30).ceil();
}

/// Persentase harga terhadap anggaran fleksibel (0..1+, bukan persen).
/// Null bila anggaran tidak tersedia. Bukan nasihat finansial.
double? purchaseBudgetShare({
  required double price,
  required double flexible,
}) {
  if (price < 0 || flexible <= 0) return null;
  return price / flexible;
}

/// Estimasi bulan hingga target tercapai (simulasi).
/// Null bila rencana tak dapat mencapai target (setoran <= 0).
/// Selalu >= 1 bila tercapai (pembulatan ke atas agar cukup).
int? monthsToReachGoal({
  required double remaining,
  required double perDeposit,
  required int depositsPerMonth,
}) {
  if (remaining <= 0) return 0;
  if (perDeposit <= 0 || depositsPerMonth <= 0) return null;
  return (remaining / (perDeposit * depositsPerMonth)).ceil();
}

/// Total pengeluaran rutin = jumlah nominal semua expenses.
double totalExpensesOf(Iterable<double> amounts) =>
    amounts.fold(0, (sum, e) => sum + e);

/// Sisa fleksibel = income - expenses - kontribusi goal.
double remainingFlexible({
  required double income,
  required double expenses,
  required double goalContribution,
}) =>
    income - expenses - goalContribution;

/// Aman harian = sisa fleksibel / hari dalam bulan ini,
/// dibulatkan ke bawah per Rp1.000 (konservatif).
/// Contoh: 1.250.000 / 31 = 40.322 -> Rp40.000.
double safeDailySpending({required double remaining, DateTime? now}) {
  final days = daysInMonth(now ?? DateTime.now());
  if (days <= 0 || remaining <= 0) return 0;
  return (remaining / days ~/ 1000) * 1000;
}
