import 'dart:io' as io;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/finance_math.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/reports_providers.dart';
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
    bool clearImageRef = false,
  }) {
    return ConsiderationDraft(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      category: category ?? this.category,
      productUrl: productUrl ?? this.productUrl,
      note: note ?? this.note,
      imageRef: clearImageRef ? null : (imageRef ?? this.imageRef),
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

/// Hasil analisis dampak pembelian (estimasi terpadu Fase 4C).
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
    this.totalLiquidBalance = 0.0,
    this.spendableBalance = 0.0,
    this.cashLegacyBalance = 0.0,
    this.hasCashLegacy = false,
    this.hasAccounts = false,
    this.budgetSufficient = false,
    this.balanceSufficient = false,
    this.isBridgeMode = false,
    this.periodBudgetCeiling,
    this.bridgeModeNotice,
    this.monthlyAdminFees = 0.0,
    this.recurringExpenses = 0.0,
    this.daysRemaining = 1,
    this.recommendation = 'consider',
    this.recommendationTitle = 'Pertimbangkan Kembali (Tahan Dulu)',
    this.recommendationReason = '',
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

  // Properti Terpadu Finansial Fase 4C & 4D:
  final double totalLiquidBalance;
  final double spendableBalance;
  final double cashLegacyBalance;
  final bool hasCashLegacy;
  final bool hasAccounts;
  final bool budgetSufficient;
  final bool balanceSufficient;
  final bool isBridgeMode;
  final double? periodBudgetCeiling;
  final String? bridgeModeNotice;
  final double monthlyAdminFees;
  final double recurringExpenses;
  final int daysRemaining;
  final String recommendation;
  final String recommendationTitle;
  final String recommendationReason;

  bool get isReady => recommendation == 'ready' || recommendation == 'buy';
  bool get isPostpone => recommendation == 'postpone';
  bool get isConsider => !isReady && !isPostpone;

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
        totalLiquidBalance,
        spendableBalance,
        cashLegacyBalance,
        hasCashLegacy,
        hasAccounts,
        budgetSufficient,
        balanceSufficient,
        isBridgeMode,
        periodBudgetCeiling,
        bridgeModeNotice,
        monthlyAdminFees,
        recurringExpenses,
        daysRemaining,
        recommendation,
        recommendationTitle,
        recommendationReason,
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
  void setImageRef(String? v) => state = v == null
      ? state.copyWith(clearImageRef: true)
      : state.copyWith(imageRef: v);

  /// Mengisi data draf produk secara selektif (misal dari hasil ekstraksi link atau foto).
  void prefillDraft({
    String? itemName,
    double? price,
    ProductCategory? category,
    String? productUrl,
    String? note,
    String? imageRef,
  }) {
    state = state.copyWith(
      itemName: itemName ?? state.itemName,
      price: price ?? state.price,
      category: category ?? state.category,
      productUrl: productUrl ?? state.productUrl,
      note: note ?? state.note,
      imageRef: imageRef ?? state.imageRef,
    );
  }

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
      // Jika imageRef adalah file lokal (dari kamera/galeri), unggah permanen ke backend storage
      if (state.imageRef != null && state.imageRef!.isNotEmpty) {
        final refStr = state.imageRef!;
        if (!refStr.startsWith('http://') &&
            !refStr.startsWith('https://') &&
            !refStr.startsWith('wishlists/')) {
          final file = io.File(refStr);
          if (file.existsSync()) {
            final uploaded = await ref
                .read(purchaseDecisionRepositoryProvider)
                .uploadImage(refStr);
            if (uploaded.isEmpty) {
              return null; // Gagal unggah foto, batalkan simpan agar draf parsial tidak terbuat
            }
            state = state.copyWith(imageRef: uploaded);
          }
        }
      }

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

  /// Catat transaksi pembelian ke buku kas & potong saldo rekening (Fase 4C).
  Future<bool> recordPurchase(
    String id, {
    required int accountId,
    String? information,
  }) async {
    if (_saving) return false;
    _saving = true;
    try {
      final repo = ref.read(purchaseDecisionRepositoryProvider);
      await repo.recordPurchase(
        id,
        accountId: accountId,
        information: information,
      );
      _refreshAll();
      ref.invalidate(accountsProvider);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  Future<bool> deleteItem(String id) async {
    if (_saving) return false;
    _saving = true;
    try {
      await ref
          .read(purchaseDecisionRepositoryProvider)
          .deleteConsideration(id);
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
    ref.invalidate(monthlyReportProvider);
    ref.invalidate(apiFinancialReportProvider);
  }
}

final tahanDuluControllerProvider =
    NotifierProvider<TahanDuluController, ConsiderationDraft>(
  TahanDuluController.new,
);

/// Analisis dampak pembelian: agregat + item + goal acuan terpadu (Fase 4C).
final purchaseAnalysisProvider =
    FutureProvider.family<PurchaseAnalysis?, String>((ref, itemId) async {
  final items = await ref.watch(considerationsProvider.future);
  final matches = items.where((e) => e.id == itemId);
  if (matches.isEmpty) return null;
  final item = matches.first;

  final repo = ref.watch(purchaseDecisionRepositoryProvider);

  try {
    final remoteData = await repo.getPurchaseAnalysis(itemId);
    if (remoteData.isNotEmpty) {
      final flex = (remoteData['remaining_pengeluaran_bebas'] ??
              remoteData['flexible_budget'] ??
              0.0)
          .toDouble();
      final safe = (remoteData['safe_daily_spending'] ??
              remoteData['safe_daily'] ??
              0.0)
          .toDouble();
      final totalBalance = (remoteData['total_assets'] ??
              remoteData['total_liquid_balance'] ??
              0.0)
          .toDouble();
      final spendableBalance =
          (remoteData['spendable_balance'] ?? totalBalance).toDouble();
      final cashLegacyBalance =
          (remoteData['cash_legacy_balance'] ?? 0.0).toDouble();
      final hasCashLegacy = remoteData['has_cash_legacy'] as bool? ??
          (cashLegacyBalance > 0);
      final hasAccs = remoteData['has_accounts'] as bool? ?? false;
      final hasSpendableAccs =
          remoteData['has_spendable_accounts'] as bool? ?? hasAccs;
      final bSufficient = remoteData['budget_sufficient'] as bool? ??
          (flex >= item.price);
      final lSufficient = remoteData['balance_sufficient'] as bool? ??
          (hasSpendableAccs && spendableBalance >= item.price);
      final bridge = remoteData['is_bridge_mode'] as bool? ?? false;
      final ceiling = remoteData['period_budget_ceiling'] != null
          ? (remoteData['period_budget_ceiling'] as num).toDouble()
          : null;
      final bridgeNotice = remoteData['bridge_mode_notice'] as String?;
      final obligations =
          remoteData['scheduled_obligations'] as Map<String, dynamic>?;
      final adminFees = obligations != null
          ? ((obligations['pending_admin_fees'] ??
                  obligations['monthly_admin_fees'] ??
                  0.0) as num)
              .toDouble()
          : 0.0;
      final recurring = obligations != null
          ? ((obligations['recurring_expenses'] ?? 0.0) as num).toDouble()
          : 0.0;
      final days = (remoteData['days_remaining'] as num?)?.toInt() ?? 1;
      final rec = remoteData['recommendation'] as String? ?? 'consider';
      final recTitle = remoteData['recommendation_title'] as String? ??
          'Pertimbangkan Kembali (Tahan Dulu)';
      final recReason = remoteData['recommendation_reason'] as String? ?? '';

      final rawShare = remoteData['budget_share'];
      final shareVal = rawShare != null
          ? (rawShare as num).toDouble()
          : purchaseBudgetShare(price: item.price, flexible: flex);

      final rawDelay = remoteData['delay_days'];
      final delayVal = rawDelay != null
          ? (rawDelay as num).toInt()
          : null;

      final goalContribution = remoteData['monthly_goal_contribution'] != null
          ? (remoteData['monthly_goal_contribution'] as num).toDouble()
          : 0.0;

      return PurchaseAnalysis(
        item: item,
        flexible: flex,
        safeDaily: safe,
        share: shareVal,
        delayDays: delayVal,
        goalName: remoteData['goal_name'] as String?,
        goalCurrent: remoteData['goal_current_amount'] != null
            ? (remoteData['goal_current_amount'] as num).toDouble()
            : null,
        monthlyContribution: goalContribution,
        totalLiquidBalance: totalBalance,
        spendableBalance: spendableBalance,
        cashLegacyBalance: cashLegacyBalance,
        hasCashLegacy: hasCashLegacy,
        hasAccounts: hasAccs,
        budgetSufficient: bSufficient,
        balanceSufficient: lSufficient,
        isBridgeMode: bridge,
        periodBudgetCeiling: ceiling,
        bridgeModeNotice: bridgeNotice,
        monthlyAdminFees: adminFees,
        recurringExpenses: recurring,
        daysRemaining: days,
        recommendation: rec,
        recommendationTitle: recTitle,
        recommendationReason: recReason,
      );
    }
  } catch (_) {
    // Gunakan fallback lokal bila remote call gagal
  }

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
    totalLiquidBalance: dashboard.totalBalance,
    spendableBalance: dashboard.spendableBalance,
    cashLegacyBalance: dashboard.cashLegacyBalance,
    hasCashLegacy: dashboard.hasCashLegacy,
    hasAccounts: dashboard.hasAccounts,
    budgetSufficient: dashboard.remainingFlexible >= item.price,
    balanceSufficient: dashboard.hasSpendableAccounts && dashboard.spendableBalance >= item.price,
    isBridgeMode: dashboard.isBridgeMode,
    periodBudgetCeiling: dashboard.periodBudgetCeiling,
    daysRemaining: dashboard.daysRemaining,
  );
});
