import 'package:equatable/equatable.dart';

/// Jenis akun keuangan.
///
/// Tiga jenis aktif: Bank, Bank Digital, E-Wallet.
/// legacyCash dipertahankan semata untuk kompatibilitas membaca akun historis pengguna lama.
enum AccountType { bank, digitalBank, ewallet, legacyCash }

/// Akun keuangan (BCA, Bank Jago, DANA).
class FinancialAccount extends Equatable {
  const FinancialAccount({
    required this.id,
    required this.name,
    required this.type,
    this.typeId,
    required this.balance,
    this.institutionName,
    this.bankId,
    this.bankSlug,
    this.bankName,
    this.bankLogoUrl,
    this.monthlyAdminFee = 0,
    this.adminFeeDay,
    this.adminFeeEnabled = false,
  });

  final String id;
  final String name;
  final AccountType type;

  /// ID tipe instrumen dari instrument_types (dikirim ke backend sebagai type_id).
  final int? typeId;

  /// Saldo TERCATAT (opening). Saldo saat ini dihitung engine.
  final double balance;

  /// Nama institusi, opsional (mis. bank penerbit).
  final String? institutionName;

  /// ID bank dari katalog backend (bank_catalogs).
  final int? bankId;

  /// Slug stabil bank dari idn-finlogos (mis. 'bca', 'mandiri').
  final String? bankSlug;

  /// Nama bank dari katalog (mis. 'BCA', 'Mandiri').
  final String? bankName;

  /// URL logo bank dari CDN idn-finlogos.
  final String? bankLogoUrl;

  /// Biaya administrasi bulanan (Rp). Contoh: 15000.
  final double monthlyAdminFee;

  /// Tanggal jadwal pemotongan (1–31). Contoh: 5.
  final int? adminFeeDay;

  /// Status apakah akun ini memiliki biaya administrasi bulanan.
  final bool adminFeeEnabled;

  /// Penanda apakah akun ini merupakan akun Uang Tunai (Cash legacy).
  bool get isLegacyCash => type == AccountType.legacyCash;

  /// Penanda apakah akun ini dapat digunakan untuk transaksi baru (Bank, Digital Bank, E-Wallet).
  bool get isSpendable => type != AccountType.legacyCash;

  /// Hitung estimasi tanggal jadwal pemotongan berikutnya.
  /// Menerapkan aturan penyesuaian: jika tanggal tidak ada di bulan tersebut (cth. 31 di Februari),
  /// otomatis menggunakan hari terakhir bulan tersebut.
  DateTime? getNextAdminFeeDate([DateTime? fromDate]) {
    if (!adminFeeEnabled || adminFeeDay == null) return null;
    final day = adminFeeDay!;
    if (day < 1 || day > 31) return null;

    final base = fromDate ?? DateTime.now();
    // 1. Coba bulan berjalan
    final daysInCurrentMonth = DateTime(base.year, base.month + 1, 0).day;
    final effectiveDayCurrent = day > daysInCurrentMonth ? daysInCurrentMonth : day;
    final candidateCurrent = DateTime(base.year, base.month, effectiveDayCurrent);

    final todayStart = DateTime(base.year, base.month, base.day);
    if (!candidateCurrent.isBefore(todayStart)) {
      return candidateCurrent;
    }

    // 2. Bulan berikutnya
    final nextMonthDate = DateTime(base.year, base.month + 1, 1);
    final daysInNextMonth = DateTime(nextMonthDate.year, nextMonthDate.month + 1, 0).day;
    final effectiveDayNext = day > daysInNextMonth ? daysInNextMonth : day;
    return DateTime(nextMonthDate.year, nextMonthDate.month, effectiveDayNext);
  }

  FinancialAccount copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? typeId,
    double? balance,
    String? institutionName,
    int? bankId,
    String? bankSlug,
    String? bankName,
    String? bankLogoUrl,
    double? monthlyAdminFee,
    int? adminFeeDay,
    bool? adminFeeEnabled,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      balance: balance ?? this.balance,
      institutionName: institutionName ?? this.institutionName,
      bankId: bankId ?? this.bankId,
      bankSlug: bankSlug ?? this.bankSlug,
      bankName: bankName ?? this.bankName,
      bankLogoUrl: bankLogoUrl ?? this.bankLogoUrl,
      monthlyAdminFee: monthlyAdminFee ?? this.monthlyAdminFee,
      adminFeeDay: adminFeeDay ?? this.adminFeeDay,
      adminFeeEnabled: adminFeeEnabled ?? this.adminFeeEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        typeId,
        balance,
        institutionName,
        bankId,
        bankSlug,
        bankName,
        bankLogoUrl,
        monthlyAdminFee,
        adminFeeDay,
        adminFeeEnabled,
      ];
}
