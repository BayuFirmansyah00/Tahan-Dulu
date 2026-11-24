import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../../data/providers/reports_providers.dart';
import '../utils/transaction_categories.dart'
    show categoriesFor, categoryLabel;

/// Sumber asal pengisian form transaksi.
enum TransactionInputSource { manual, voice, scan }

/// Draf form input manual (sumber kebenaran selama mengisi & review).
class TransactionDraft extends Equatable {
  const TransactionDraft({
    this.title = '',
    this.type = TransactionType.expense,
    this.amount = 0,
    this.category,
    this.accountId,
    this.date,
    this.note = '',
    this.fee = 0,
    this.idempotencyKey = '',
    this.source = TransactionInputSource.manual,
    this.sourceNotice,
    this.attachmentPath,
  });

  /// Judul transaksi (misal: nama merchant dari struk atau ringkasan suara).
  /// Bila kosong, akan fallback ke label kategori saat simpan.
  final String title;
  final TransactionType type;
  final double amount;
  final TransactionCategory? category;
  final String? accountId;
  final DateTime? date;
  final String note;

  /// Path berkas lampiran struk lokal (jika ada).
  final String? attachmentPath;

  /// Biaya tambahan opsional (default Rp0, tak negatif).
  final double fee;

  /// Kunci idempotensi unik (UUID v4) untuk sesi draf transaksi ini.
  final String idempotencyKey;

  /// Sumber asal pengisian draf (manual, voice, atau scan struk).
  final TransactionInputSource source;

  /// Keterangan atau notifikasi kontekstual untuk pengguna (misal konfirmasi ekstraksi).
  final String? sourceNotice;

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
    String? title,
    TransactionType? type,
    double? amount,
    TransactionCategory? category,
    String? accountId,
    DateTime? date,
    String? note,
    double? fee,
    String? idempotencyKey,
    TransactionInputSource? source,
    String? sourceNotice,
    String? attachmentPath,
    bool clearAttachment = false,
  }) {
    return TransactionDraft(
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      fee: fee ?? this.fee,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      source: source ?? this.source,
      sourceNotice: sourceNotice ?? this.sourceNotice,
      attachmentPath: clearAttachment ? null : (attachmentPath ?? this.attachmentPath),
    );
  }

  @override
  List<Object?> get props => [
        title,
        type,
        amount,
        category,
        accountId,
        date,
        note,
        fee,
        idempotencyKey,
        source,
        sourceNotice,
        attachmentPath,
      ];
}

/// Controller form manual: validasi, review, simpan anti-ganda.
/// UI me-await [save]; guard ganda dijaga flag internal.
class TransactionFormController extends Notifier<TransactionDraft> {
  bool _saving = false;
  AppTransaction? _lastSaved;

  AppTransaction? get lastSaved => _lastSaved;

  /// ID akun/instrumen yang valid saat ini.
  Set<String> _accountIds() {
    final accounts = ref.read(accountsProvider).value;
    if (accounts != null && accounts.isNotEmpty) {
      return {for (final a in accounts) a.id};
    }
    final data =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    return {
      for (final e in data?.financialInstruments ?? const []) e.id,
    };
  }

  @override
  TransactionDraft build() => TransactionDraft(
        date: DateTime.now(),
        idempotencyKey: generateUuidV4(),
      );

  void reset() {
    _saving = false;
    _lastSaved = null;
    state = TransactionDraft(
      date: DateTime.now(),
      idempotencyKey: generateUuidV4(),
    );
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

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void setSource(TransactionInputSource source, {String? notice}) {
    state = state.copyWith(source: source, sourceNotice: notice);
  }

  void prefillFromVoice({
    required TransactionType type,
    double? amount,
    TransactionCategory? category,
    String? accountId,
    DateTime? date,
    String? title,
    String? note,
    String? notice,
  }) {
    final compatibleCategory =
        category != null && categoriesFor(type).contains(category)
            ? category
            : null;

    state = state.copyWith(
      type: type,
      amount: amount ?? state.amount,
      category: compatibleCategory,
      accountId: accountId ?? state.accountId,
      date: date ?? state.date,
      title: title ?? state.title,
      note: note ?? state.note,
      source: TransactionInputSource.voice,
      sourceNotice: notice ??
          'Data terisi dari input suara. Silakan periksa kembali sebelum menyimpan.',
    );
  }

  void prefillFromScan({
    required double amount,
    DateTime? date,
    String? title,
    String? note,
    String? notice,
    String? attachmentPath,
  }) {
    state = state.copyWith(
      type: TransactionType.expense,
      amount: amount,
      date: date ?? state.date,
      title: title ?? state.title,
      note: note ?? state.note,
      attachmentPath: attachmentPath,
      source: TransactionInputSource.scan,
      sourceNotice: notice ??
          'Data terisi dari scan struk. Pilih kategori dan rekening pembayaran.',
    );
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
      final categoryName = categoryLabel(state.category!);
      String finalTitle = state.title.trim();
      if (finalTitle.isEmpty) {
        finalTitle = categoryName;
      }
      if (finalTitle.length > 255) {
        finalTitle = finalTitle.substring(0, 255).trim();
      }

      final key = state.idempotencyKey.isNotEmpty
          ? state.idempotencyKey
          : generateUuidV4();
      if (state.idempotencyKey.isEmpty) {
        state = state.copyWith(idempotencyKey: key);
      }

      final saved = await ref
          .read(transactionRepositoryProvider)
          .addTransaction(
            AppTransaction(
              id: 'trx-${DateTime.now().millisecondsSinceEpoch}',
              title: finalTitle,
              amount: state.netAmount,
              type: state.type,
              date: state.date!,
              category: categoryName,
              accountId: state.accountId,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
              fee: state.fee,
              idempotencyKey: key,
            ),
          );
      _lastSaved = saved;

      if (state.attachmentPath != null && state.attachmentPath!.isNotEmpty) {
        try {
          await ref.read(transactionRepositoryProvider).uploadReceiptAttachment(
            saved.id,
            state.attachmentPath!,
          );
        } catch (_) {
          // Gagal upload lampiran tidak menggagalkan transaksi yang sudah tersimpan
        }
      }

      // Invalidate semua provider yang bergantung pada transaksi dan saldo akun:
      ref.invalidate(transactionsProvider);
      ref.invalidate(paginatedTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(accountsOverviewProvider);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(monthlyReportProvider);
      ref.invalidate(apiFinancialReportProvider);
      // Persiapkan key baru agar draft berikutnya tidak menggunakan key lama
      state = state.copyWith(idempotencyKey: generateUuidV4());
      return true;
    } on ApiException {
      // Error validasi dari backend (422) akan ditangani oleh UI melalui
      // rethrow ke caller yang dapat membaca e.fieldErrors.
      rethrow;
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

/// State paginasi transaksi terstruktur (F06B).
class PaginatedTransactionsState extends Equatable {
  const PaginatedTransactionsState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.hasNextPage = false,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
    this.typeFilter,
    this.categoryFilter,
    this.accountIdFilter,
  });

  final List<AppTransaction> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasNextPage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;
  final String? typeFilter;
  final String? categoryFilter;
  final String? accountIdFilter;

  PaginatedTransactionsState copyWith({
    List<AppTransaction>? items,
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
    bool? hasNextPage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    String? loadMoreErrorMessage,
    String? typeFilter,
    String? categoryFilter,
    String? accountIdFilter,
    bool clearError = false,
    bool clearLoadMoreError = false,
    bool clearAccountIdFilter = false,
  }) {
    return PaginatedTransactionsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreErrorMessage:
          clearLoadMoreError ? null : (loadMoreErrorMessage ?? this.loadMoreErrorMessage),
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      accountIdFilter:
          clearAccountIdFilter ? null : (accountIdFilter ?? this.accountIdFilter),
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentPage,
        lastPage,
        perPage,
        total,
        hasNextPage,
        isLoadingInitial,
        isLoadingMore,
        errorMessage,
        loadMoreErrorMessage,
        typeFilter,
        categoryFilter,
        accountIdFilter,
      ];
}

/// Notifier untuk paginasi riwayat transaksi end-to-end (F06B).
class PaginatedTransactionsNotifier
    extends Notifier<PaginatedTransactionsState> {
  static const int defaultPerPage = 20;

  @override
  PaginatedTransactionsState build() {
    final existing = ref.watch(transactionsProvider).value;
    if (existing != null && existing.isNotEmpty) {
      final sorted = List.of(existing)..sort((a, b) => b.date.compareTo(a.date));
      return PaginatedTransactionsState(
        items: sorted,
        currentPage: 1,
        lastPage: (sorted.length / defaultPerPage).ceil() == 0 ? 1 : (sorted.length / defaultPerPage).ceil(),
        perPage: defaultPerPage,
        total: sorted.length,
        hasNextPage: sorted.length > defaultPerPage,
        isLoadingInitial: false,
      );
    }
    Future.microtask(() => loadInitial());
    return const PaginatedTransactionsState(isLoadingInitial: true);
  }

  Future<void> loadInitial({
    String? type,
    String? category,
    String? accountId,
  }) async {
    state = state.copyWith(
      isLoadingInitial: true,
      clearError: true,
      typeFilter: type,
      categoryFilter: category,
      accountIdFilter: accountId,
      clearAccountIdFilter: accountId == null,
    );

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final result = await repo.getPaginatedTransactions(
        type: state.typeFilter,
        category: state.categoryFilter,
        instrumentId: state.accountIdFilter,
        page: 1,
        perPage: defaultPerPage,
      );

      final seen = <String>{};
      final uniqueItems = <AppTransaction>[];
      for (final item in result.items) {
        if (seen.add(item.id)) {
          uniqueItems.add(item);
        }
      }

      state = state.copyWith(
        items: uniqueItems,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        perPage: result.perPage,
        total: result.total,
        hasNextPage: result.hasNextPage,
        isLoadingInitial: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial(
      type: state.typeFilter,
      category: state.categoryFilter,
      accountId: state.accountIdFilter,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      clearLoadMoreError: true,
    );

    try {
      final nextPage = state.currentPage + 1;
      final repo = ref.read(transactionRepositoryProvider);
      final result = await repo.getPaginatedTransactions(
        type: state.typeFilter,
        category: state.categoryFilter,
        instrumentId: state.accountIdFilter,
        page: nextPage,
        perPage: defaultPerPage,
      );

      final seen = {for (final item in state.items) item.id};
      final merged = List.of(state.items);
      for (final item in result.items) {
        if (seen.add(item.id)) {
          merged.add(item);
        }
      }

      state = state.copyWith(
        items: merged,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        perPage: result.perPage,
        total: result.total,
        hasNextPage: result.hasNextPage,
        isLoadingMore: false,
        clearLoadMoreError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: e.toString(),
      );
    }
  }

  void setFilter({String? type, String? category, String? accountId}) {
    loadInitial(type: type, category: category, accountId: accountId);
  }
}

final paginatedTransactionsProvider =
    NotifierProvider<PaginatedTransactionsNotifier, PaginatedTransactionsState>(
  PaginatedTransactionsNotifier.new,
);
