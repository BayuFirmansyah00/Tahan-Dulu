import 'package:equatable/equatable.dart';

/// Satu setoran ke target keuangan.
///
/// Aturan finansial (Tahap 10, terdokumentasi): setoran adalah ALOKASI
/// (penandaan sebagian uang yang sudah ada), BUKAN pengeluaran eksternal.
/// Mencatat setoran TIDAK membuat AppTransaction dan TIDAK mengubah
/// saldo akun — sehingga total kekayaan tidak pernah terhitung ganda.
/// [accountId] hanya referensi provenance (sumber dana yang dipilih).
class GoalDeposit extends Equatable {
  const GoalDeposit({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.accountId,
    this.note,
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? accountId;
  final String? note;

  @override
  List<Object?> get props => [id, goalId, amount, date, accountId, note];
}
