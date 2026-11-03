import 'package:equatable/equatable.dart';

/// Jenis akun keuangan. v1: tanpa transfer antar rekening kompleks.
///
/// Tepat tiga jenis (Tahap 16): Bank, Bank Digital, E-Wallet.
/// Kategori target Investasi tidak terpengaruh (tujuan, bukan akun).
enum AccountType { bank, digitalBank, ewallet }

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
      ];
}
