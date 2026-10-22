import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../goals/presentation/providers/goals_controller.dart'
    show goalsListProvider;

/// Draf form produk (dibawa antar layar metode -> form).
class ConsiderationDraft extends Equatable {
  const ConsiderationDraft({
    this.id,
    this.itemName = '',
    this.price = 0,
    this.category = ProductCategory.fashion,
    this.productUrl = '',
    this.note = '',
    this.imageRef,
  });

  final String? id;
  final String itemName;
  final double price;
  final ProductCategory category;
  final String productUrl;
  final String note;
  final String? imageRef;

  bool get isNameValid => itemName.trim().isNotEmpty;
  bool get isPriceValid => price > 0;
  bool get isUrlValid =>
      productUrl.trim().isEmpty || isValidProductUrl(productUrl.trim());

  bool get isComplete => isNameValid && isPriceValid && isUrlValid;

  ConsiderationDraft copyWith({
    String? id,
    String? itemName,
    double? price,
    ProductCategory? category,
    String? productUrl,
    String? note,
    String? imageRef,
  }) {
    return ConsiderationDraft(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      category: category ?? this.category,
      productUrl: productUrl ?? this.productUrl,
      note: note ?? this.note,
      imageRef: imageRef ?? this.imageRef,
    );
  }

  @override
  List<Object?> get props =>
      [id, itemName, price, category, productUrl, note, imageRef];
}

/// Validasi URL produk: skema http(s) + host.
bool isValidProductUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// Hasil analisis dampak pembelian (estimasi, read-only).
class PurchaseAnalysis extends Equatable {
  const PurchaseAnalysis({
    required this.item,
    required this.flexible,
    required this.safeDaily,
    required this.share,
    required this.delayDays,
    required this.goalName,
    required this.goalCurrent,
    required this.monthlyContribution,
  });

  final PurchaseConsideration item;
  final double flexible;
  final double safeDaily;

  /// 0..1+ atau null bila anggaran tak tersedia.
  final double? share;

  /// Estimasi mundur target (hari) atau null bila tak terhitung.
  final int? delayDays;
  final String? goalName;
  final double? goalCurrent;
  final double monthlyContribution;

  @override
  List<Object?> get props => [
        item,
        flexible,
        safeDaily,
        share,
        delayDays,
        goalName,
        goalCurrent,
        monthlyContribution,
      ];
}

/// Controller TahanDulu: draf, simpan, status, masa tunggu.
/// Tanpa mutasi saldo/transaksi (simulasi & keputusan murni status).
class TahanDuluController extends Notifier<ConsiderationDraft> {
  bool _saving = false;

  @override
  ConsiderationDraft build() => const ConsiderationDraft();

  void reset([String? linkUrl]) {
    _saving = false;
    state = ConsiderationDraft(productUrl: linkUrl ?? '');
  }

  void setName(String v) => state = state.copyWith(itemName: v);
  void setPrice(double v) => state = state.copyWith(price: v);
  void setPriceText(String v) =>
      setPrice(RupiahInputFormatter.parse(v));
  void setCategory(ProductCategory v) =>
      state = state.copyWith(category: v);
  void setUrl(String v) => state = state.copyWith(productUrl: v);
  void setNote(String v) => state = state.copyWith(note: v);

  Future<PurchaseConsideration?> _persist() async {
    final repo = ref.read(purchaseDecisionRepositoryProvider);
    if (state.id == null) {
      return repo.addConsideration(
        PurchaseConsideration(
          id: 'td-${DateTime.now().millisecondsSinceEpoch}',
          itemName: state.itemName.trim(),
          price: state.price,
          status: ConsiderationStatus.considering,
          createdAt: DateTime.now(),
          reason:
              state.note.trim().isEmpty ? null : state.note.trim(),
          category: state.category,
          productUrl: state.productUrl.trim().isEmpty
              ? null
              : state.productUrl.trim(),
          imageRef: state.imageRef,
        ),
      );
    }
    final items = await repo.getConsiderations();
    final existing = items.firstWhere((e) => e.id == state.id);
    return repo.updateConsideration(
      existing.copyWith(
        itemName: state.itemName.trim(),
        price: state.price,
        category: state.category,
        productUrl:
            state.productUrl.trim().isEmpty ? null : state.productUrl.trim(),
        reason: state.note.trim().isEmpty ? null : state.note.trim(),
        imageRef: state.imageRef,
      ),
    );
  }

  /// Simpan draf (baru/ubah). Guard ganda bawaan.
  /// Setelah buat baru, id tersimpan di state agar Analisis
  /// berikutnya menjadi update (anti-duplikat).
  Future<PurchaseConsideration?> saveDraft() async {
    if (_saving || !state.isComplete) return null;
    _saving = true;
    try {
      final saved = await _persist();
      if (saved != null) state = state.copyWith(id: saved.id);
      _refreshAll();
      return saved;
    } catch (_) {
      return null;
    } finally {
      _saving = false;
    }
  }

  Future<bool> setStatus(String id, ConsiderationStatus status) async {
    if (_saving) return false;
    _saving = true;
    try {
      final items = await ref
          .read(purchaseDecisionRepositoryProvider)
          .getConsiderations();
      final existing = items.firstWhere((e) => e.id == id);
      await ref
          .read(purchaseDecisionRepositoryProvider)
          .updateConsideration(existing.copyWith(status: status));
      _refreshAll();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Mulai masa tunggu: simpan jam + timestamp eksplisit.
  Future<bool> startWait(String id, int hours, {DateTime? now}) async {
    if (_saving || hours <= 0) return false;
    _saving = true;
    try {
      final started = now ?? DateTime.now();
      final items = await ref
          .read(purchaseDecisionRepositoryProvider)
          .getConsiderations();
      final existing = items.firstWhere((e) => e.id == id);
      await ref
          .read(purchaseDecisionRepositoryProvider)
          .updateConsideration(
            existing.copyWith(
              status: ConsiderationStatus.considering,
              waitHours: hours,
              waitStartedAt: started,
              waitEndsAt: started.add(Duration(hours: hours)),
            ),
          );
      _refreshAll();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  void _refreshAll() {
    ref.invalidate(considerationsProvider);
    ref.invalidate(dashboardDataProvider);
  }
}

final tahanDuluControllerProvider =
    NotifierProvider<TahanDuluController, ConsiderationDraft>(
  TahanDuluController.new,
);

/// Analisis dampak pembelian: agregat + item + goal acuan.
/// Murni estimasi read-only (tidak menulis apa pun).
final purchaseAnalysisProvider =
    FutureProvider.family<PurchaseAnalysis?, String>((ref, itemId) async {
  final items = await ref.watch(considerationsProvider.future);
  final matches = items.where((e) => e.id == itemId);
  if (matches.isEmpty) return null;
  final item = matches.first;

  final dashboard = await ref.watch(dashboardDataProvider.future);
  final goals = await ref.watch(goalsListProvider.future);
  final goal = goals.isEmpty ? null : goals.first;

  return PurchaseAnalysis(
    item: item,
    flexible: dashboard.remainingFlexible,
    safeDaily: dashboard.safeDaily,
    share: purchaseBudgetShare(
      price: item.price,
      flexible: dashboard.remainingFlexible,
    ),
    delayDays: targetDelayDays(
      price: item.price,
      monthlyContribution: dashboard.goalContribution,
    ),
    goalName: goal?.name,
    goalCurrent: goal?.currentAmount,
    monthlyContribution: dashboard.goalContribution,
  );
});
