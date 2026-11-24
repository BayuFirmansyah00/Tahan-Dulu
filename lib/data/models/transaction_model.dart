import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

/// Kategori transaksi input manual.
enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  education,
  salary,
  bonus,
  others,
}

/// Transaksi pemasukan / pengeluaran. v1: IDR only.
///
/// Representasi nominal (Tahap 17): [amount] menyimpan PENGARUH BERSIH
/// terhadap akun — pengeluaran: nominal + biaya; pemasukan: nominal − biaya.
/// [fee] hanya rincian tampilan (berapa bagian yang merupakan biaya) dan
/// TIDAK BOLEH dijumlahkan lagi di agregat mana pun (anti double-count).
/// Transaksi lama tanpa biaya terbaca dengan fee = 0 (perilaku identik).
class AppTransaction extends Equatable {
  const AppTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
    this.accountId,
    this.note,
    this.fee = 0,
    this.idempotencyKey,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? category;
  final String? accountId;

  /// Catatan opsional dari form manual.
  final String? note;

  /// Biaya tambahan per transaksi (opsional, default Rp0).
  /// Sudah tercakup di [amount]; hanya untuk rincian, bukan agregat.
  final double fee;

  /// Kunci idempotensi opsional (UUID v4) untuk mencegah transaksi duplikat saat retry/timeout.
  final String? idempotencyKey;

  AppTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? category,
    String? accountId,
    String? note,
    double? fee,
    String? idempotencyKey,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      fee: fee ?? this.fee,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, amount, type, date, category, accountId, note, fee, idempotencyKey];
}
