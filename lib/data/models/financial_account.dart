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
    required this.balance,
    this.institutionName,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Saldo TERCATAT (opening). Saldo saat ini dihitung engine.
  final double balance;

  /// Nama institusi, opsional (mis. bank penerbit).
  final String? institutionName;

  @override
  List<Object?> get props => [id, name, type, balance, institutionName];
}
