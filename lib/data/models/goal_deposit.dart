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
    this.type = 'deposit',
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? accountId;
  final String? note;
  final String type; // 'deposit' | 'withdraw'

  bool get isWithdraw => type == 'withdraw';
  bool get isDeposit => type != 'withdraw';

  /// Nilai bertanda untuk visualisasi riwayat:
  /// Positif (+) untuk setoran (alokasi masuk),
  /// Negatif (-) untuk penarikan/pencairan (alokasi keluar).
  double get signedAmount => isWithdraw ? -amount.abs() : amount.abs();

  GoalDeposit copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? accountId,
    String? note,
    String? type,
  }) {
    return GoalDeposit(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, goalId, amount, date, accountId, note, type];
}
