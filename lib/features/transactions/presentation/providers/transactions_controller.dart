import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../../data/providers/reports_providers.dart';
import '../utils/transaction_categories.dart'
    show categoriesFor, categoryLabel;

/// Draf form input manual (sumber kebenaran selama mengisi & review).
class TransactionDraft extends Equatable {
  const TransactionDraft({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.category,
    this.accountId,
    this.date,
    this.note = '',
    this.fee = 0,
  });

  final TransactionType type;
  final double amount;
  final TransactionCategory? category;
  final String? accountId;
  final DateTime? date;
  final String note;

  /// Biaya tambahan opsional (default Rp0, tak negatif).
  final double fee;

  bool get isAmountValid => amount > 0;
  bool get isCategoryValid => category != null;
  bool get isDateValid => date != null;

  /// Total bersih menurut R7 (dipakai preview, review, dan simpan).
  double get netAmount => netTransactionAmount(
        isExpense: type == TransactionType.expense,
        amount: amount,
        fee: fee,
      );

  /// Bersih tak boleh ≤ 0 (mencegah biaya ≥ nominal pada pemasukan).
  bool get isNetValid => netAmount > 0;

  bool isAccountValid(Set<String> accountIds) =>
      accountId != null && accountIds.contains(accountId);

  bool isComplete(Set<String> accountIds) =>
      isAmountValid &&
      isCategoryValid &&
      isDateValid &&
      isAccountValid(accountIds);

  TransactionDraft copyWith({
    TransactionType? type,
    double? amount,
    TransactionCategory? category,
    String? accountId,
    DateTime? date,
    String? note,
    double? fee,
  }) {
    return TransactionDraft(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      fee: fee ?? this.fee,
    );
  }

  @override
  List<Object?> get props =>
      [type, amount, category, accountId, date, note, fee];
}

/// Controller form manual: validasi, review, simpan anti-ganda.
/// UI me-await [save]; guard ganda dijaga flag internal.
class TransactionFormController extends Notifier<TransactionDraft> {
  bool _saving = false;
  AppTransaction? _lastSaved;

  AppTransaction? get lastSaved => _lastSaved;

  /// ID akun/instrumen yang valid saat ini.
  Set<String> _accountIds() {
    final data =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    return {
      for (final e in data?.financialInstruments ?? const []) e.id,
    };
  }

  @override
  TransactionDraft build() => TransactionDraft(date: DateTime.now());

  void reset() {
    _saving = false;
    _lastSaved = null;
    state = TransactionDraft(date: DateTime.now());
  }

  void setType(TransactionType type) {
    // Ganti kategori bila tidak cocok dengan jenis baru.
    final compatible = categoriesFor(type).contains(state.category);
    state = state.copyWith(
      type: type,
      category: compatible ? state.category : null,
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setAmountText(String text) {
    setAmount(RupiahInputFormatter.parse(text));
  }

  void setCategory(TransactionCategory category) {
    state = state.copyWith(category: category);
  }

  void setAccount(String? accountId) {
    state = state.copyWith(accountId: accountId);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  /// Biaya tambahan: kosong/negatif -> Rp0 (ditolak, bukan disimpan).
  /// Batas digit mengikuti masker Rupiah (maks 15 digit).
  static const double maxFee = 999999999999999;

  void setFee(double fee) {
    if (fee.isNaN || fee < 0) {
      state = state.copyWith(fee: 0);
    } else if (fee > maxFee) {
      state = state.copyWith(fee: maxFee);
    } else {
      state = state.copyWith(fee: fee);
    }
  }

  void setFeeText(String text) {
    setFee(RupiahInputFormatter.parse(text));
  }

  /// Simpan satu transaksi. Aman dipanggil berulang (anti-ganda).
  /// Menyimpan NILAI BERSIH (R7); fee hanya rincian, bukan transaksi kedua.
  Future<bool> save() async {
    if (_saving) return false;
    final ids = _accountIds();
    if (!state.isComplete(ids) || !state.isNetValid) return false;
    _saving = true;
    try {
      final saved = await ref
          .read(transactionRepositoryProvider)
          .addTransaction(
            AppTransaction(
              id: 'trx-${DateTime.now().millisecondsSinceEpoch}',
              title: categoryLabel(state.category!),
              amount: state.netAmount,
              type: state.type,
              date: state.date!,
              category: categoryLabel(state.category!),
              accountId: state.accountId,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
              fee: state.fee,
            ),
          );
      _lastSaved = saved;
      ref.invalidate(transactionsProvider);
      ref.invalidate(monthlyReportProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }
}

final transactionFormProvider =
    NotifierProvider<TransactionFormController, TransactionDraft>(
  TransactionFormController.new,
);

