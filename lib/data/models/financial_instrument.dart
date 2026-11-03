import 'package:equatable/equatable.dart';

/// Jenis instrumen keuangan (MVP, tanpa integrasi bank).
///
/// Keputusan produk Tahap 16: tepat tiga jenis. Bank Digital dibedakan
/// dari Bank konvensional. Tunai dan Investasi bukan jenis akun;
/// Target Investasi (GoalCategory.investment) tidak terpengaruh.
enum InstrumentType { bank, digitalBank, ewallet }

/// Instrumen/rekening onboarding No.4: pencatatan kepemilikan saja.
class FinancialInstrument extends Equatable {
  const FinancialInstrument({
    required this.id,
    required this.name,
    required this.type,
    this.typeId,
    required this.initialBalance,
    this.institutionName,
    this.monthlyAdminFee = 0,
    this.adminFeeDay = 15,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final InstrumentType type;

  /// ID tipe instrumen dari instrument_types Laravel (type_id).
  final int? typeId;

  /// Saldo awal (numeric). Contoh: 5000000.
  final double initialBalance;

  /// Nama institusi, opsional (mis. bank penerbit).
  final String? institutionName;

  /// Biaya admin bulanan, relevan untuk Bank. Contoh: 14000.
  final double monthlyAdminFee;

  /// Tanggal pemotongan 1–31. Contoh: 15.
  final int adminFeeDay;

  final bool isSelected;

  FinancialInstrument copyWith({
    String? id,
    String? name,
    InstrumentType? type,
    int? typeId,
    double? initialBalance,
    String? institutionName,
    double? monthlyAdminFee,
    int? adminFeeDay,
    bool? isSelected,
  }) {
    return FinancialInstrument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      initialBalance: initialBalance ?? this.initialBalance,
      institutionName: institutionName ?? this.institutionName,
      monthlyAdminFee: monthlyAdminFee ?? this.monthlyAdminFee,
      adminFeeDay: adminFeeDay ?? this.adminFeeDay,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        typeId,
        initialBalance,
        institutionName,
        monthlyAdminFee,
        adminFeeDay,
        isSelected,
      ];
}

