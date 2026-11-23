import 'package:equatable/equatable.dart';

/// Jenis instrumen keuangan.
/// Kategori resmi: Bank, Bank Digital, E-Wallet, dan Uang Tunai.
enum InstrumentType { bank, digitalBank, ewallet, cash }

/// Instrumen/rekening onboarding No.4: pencatatan kepemilikan saja.
class FinancialInstrument extends Equatable {
  const FinancialInstrument({
    required this.id,
    required this.name,
    required this.type,
    this.typeId,
    this.bankId,
    this.bankSlug,
    required this.initialBalance,
    this.institutionName,
    this.monthlyAdminFee = 0,
    this.adminFeeDay = 15,
    this.adminFeeEnabled = false,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final InstrumentType type;

  /// ID tipe instrumen dari instrument_types Laravel (type_id).
  final String? typeId;

  /// ID katalog bank / e-wallet dari bank_catalogs (bank_id).
  final int? bankId;

  /// Slug katalog penyedia (mis. 'bca', 'jago', 'gopay').
  final String? bankSlug;

  /// Saldo awal (numeric). Contoh: 5000000.
  final double initialBalance;

  /// Nama institusi, opsional (mis. bank penerbit).
  final String? institutionName;

  /// Biaya admin bulanan, relevan untuk Bank / Bank Digital. Contoh: 15000.
  final double monthlyAdminFee;

  /// Tanggal pemotongan 1–31. Contoh: 15.
  final int adminFeeDay;

  /// Status apakah instrumen memiliki biaya administrasi bulanan.
  final bool adminFeeEnabled;

  final bool isSelected;

  FinancialInstrument copyWith({
    String? id,
    String? name,
    InstrumentType? type,
    String? typeId,
    int? bankId,
    String? bankSlug,
    double? initialBalance,
    String? institutionName,
    double? monthlyAdminFee,
    int? adminFeeDay,
    bool? adminFeeEnabled,
    bool? isSelected,
  }) {
    return FinancialInstrument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      bankId: bankId ?? this.bankId,
      bankSlug: bankSlug ?? this.bankSlug,
      initialBalance: initialBalance ?? this.initialBalance,
      institutionName: institutionName ?? this.institutionName,
      monthlyAdminFee: monthlyAdminFee ?? this.monthlyAdminFee,
      adminFeeDay: adminFeeDay ?? this.adminFeeDay,
      adminFeeEnabled: adminFeeEnabled ?? this.adminFeeEnabled,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        typeId,
        bankId,
        bankSlug,
        initialBalance,
        institutionName,
        monthlyAdminFee,
        adminFeeDay,
        adminFeeEnabled,
        isSelected,
      ];
}

