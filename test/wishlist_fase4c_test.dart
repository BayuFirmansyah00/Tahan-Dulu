import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/providers/tahandulu_controller.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_analysis_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_decide_screen.dart';

class _MockFase4CPurchaseRepo implements PurchaseDecisionRepository {
  _MockFase4CPurchaseRepo(this.items);

  final List<PurchaseConsideration> items;
  Map<String, dynamic> analysisData = {};
  bool recordPurchaseCalled = false;
  String? lastRecordedAccountId;

  @override
  Future<List<PurchaseConsideration>> getConsiderations() async => List.of(items);

  @override
  Future<PurchaseConsideration> addConsideration(PurchaseConsideration item) async {
    items.add(item);
    return item;
  }

  @override
  Future<PurchaseConsideration> updateConsideration(PurchaseConsideration item) async {
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx != -1) items[idx] = item;
    return item;
  }

  @override
  Future<void> deleteConsideration(String id) async {
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<Map<String, dynamic>> extractMetadata(String url) async => {};

  @override
  Future<String> uploadImage(String filePath) async => '';

  @override
  Future<Map<String, dynamic>> getPurchaseAnalysis(String id) async => analysisData;

  @override
  Future<Map<String, dynamic>> recordPurchase(
    String id, {
    required String accountId,
    String? information,
    String? idempotencyKey,
  }) async {
    recordPurchaseCalled = true;
    lastRecordedAccountId = accountId;
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(status: ConsiderationStatus.bought);
    }
    return {'success': true};
  }

  @override
  void clear() {
    items.clear();
  }
}

class _MockAccountRepo implements AccountRepository {
  _MockAccountRepo(this.accounts);
  final List<FinancialAccount> accounts;

  @override
  Future<List<FinancialAccount>> getAccounts() async => List.of(accounts);

  @override
  Future<double> getTotalBalance() async =>
      accounts.fold<double>(0.0, (double sum, a) => sum + a.balance);

  @override
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {}

  @override
  Future<void> reconcileLegacyCash({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {}

  @override
  Future<FinancialAccount> addAccount(FinancialAccount account) async {
    accounts.add(account);
    return account;
  }

  @override
  Future<FinancialAccount> updateAccount(FinancialAccount account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) accounts[idx] = account;
    return account;
  }

  @override
  Future<void> removeAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
  }

  Future<void> syncAccounts(List<FinancialAccount> accounts) async {}

  void clear() => accounts.clear();
}

Widget _buildTestApp({
  required Widget child,
  required List<dynamic> overrides,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '${AppRoutes.tahanDulu}/:id/simulate', builder: (_, _) => const SizedBox()),
      GoRoute(path: '${AppRoutes.tahanDulu}/:id/wait', builder: (_, _) => const SizedBox()),
      GoRoute(path: '${AppRoutes.tahanDulu}/:id/success', builder: (_, _) => const SizedBox()),
      GoRoute(path: AppRoutes.tahanDulu, builder: (_, _) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 4C - PurchaseAnalysis Model & Provider Tests', () {
    test('PurchaseAnalysis calculates readiness and status flags correctly', () {
      final item = PurchaseConsideration(
        id: 'td-1',
        itemName: 'Sepatu Lari',
        price: 750000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.fashion,
      );

      final analysisReady = PurchaseAnalysis(
        item: item,
        flexible: 1500000,
        safeDaily: 50000,
        share: 0.5,
        delayDays: 15,
        goalName: 'Dana Liburan',
        goalCurrent: 2000000,
        monthlyContribution: 500000,
        totalLiquidBalance: 4000000,
        hasAccounts: true,
        budgetSufficient: true,
        balanceSufficient: true,
        recommendation: 'ready',
        recommendationTitle: 'Kondisi Finansial Mendukung',
      );

      expect(analysisReady.isReady, isTrue);
      expect(analysisReady.isPostpone, isFalse);
      expect(analysisReady.isConsider, isFalse);

      final analysisPostpone = PurchaseAnalysis(
        item: item,
        flexible: 500000,
        safeDaily: 20000,
        share: 1.5,
        delayDays: 45,
        goalName: null,
        goalCurrent: null,
        monthlyContribution: 0,
        totalLiquidBalance: 300000,
        hasAccounts: true,
        budgetSufficient: false,
        balanceSufficient: false,
        recommendation: 'postpone',
        recommendationTitle: 'Disarankan Menunda Pembelian',
      );

      expect(analysisPostpone.isPostpone, isTrue);
      expect(analysisPostpone.isReady, isFalse);
      expect(analysisPostpone.isConsider, isFalse);
    });

    test('PurchaseAnalysis handles Bridge Mode properties', () {
      final item = PurchaseConsideration(
        id: 'td-2',
        itemName: 'Headphone',
        price: 300000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.electronics,
      );

      final analysisBridge = PurchaseAnalysis(
        item: item,
        flexible: 800000,
        safeDaily: 40000,
        share: 0.375,
        delayDays: null,
        goalName: null,
        goalCurrent: null,
        monthlyContribution: 0,
        totalLiquidBalance: 2500000,
        hasAccounts: true,
        budgetSufficient: true,
        balanceSufficient: true,
        isBridgeMode: true,
        periodBudgetCeiling: 1200000,
        bridgeModeNotice: 'Periode Transisi (Bridge Mode) aktif dengan batas anggaran Rp 1.200.000.',
        monthlyAdminFees: 15000,
        recurringExpenses: 100000,
        recommendation: 'consider',
      );

      expect(analysisBridge.isBridgeMode, isTrue);
      expect(analysisBridge.periodBudgetCeiling, 1200000);
      expect(analysisBridge.bridgeModeNotice, contains('Bridge Mode'));
      expect(analysisBridge.monthlyAdminFees, 15000);
      expect(analysisBridge.recurringExpenses, 100000);
    });
  });

  group('Fase 4C - UI Analysis & Decision Screens', () {
    testWidgets('TahanDuluAnalysisScreen displays financial metrics and recommendation', (tester) async {
      final item = PurchaseConsideration(
        id: 'td-ui-1',
        itemName: 'Mechanical Keyboard RGB',
        price: 500000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.electronics,
      );

      final fakeRepo = _MockFase4CPurchaseRepo([item]);
      fakeRepo.analysisData = {
        'remaining_pengeluaran_bebas': 1200000.0,
        'flexible_budget': 1200000.0,
        'total_liquid_balance': 3500000.0,
        'has_accounts': true,
        'budget_sufficient': true,
        'balance_sufficient': true,
        'is_bridge_mode': true,
        'period_budget_ceiling': 1500000.0,
        'bridge_mode_notice': 'Periode Transisi (Bridge Mode) aktif hingga siklus baru.',
        'scheduled_obligations': {
          'monthly_admin_fees': 20000.0,
          'pending_admin_fees': 20000.0,
          'recurring_expenses': 250000.0,
        },
        'safe_daily_spending': 45000.0,
        'days_remaining': 10,
        'recommendation': 'consider',
        'recommendation_title': 'Pertimbangkan Kembali (Tahan Dulu)',
        'recommendation_reason': 'Budget cukup namun melebihi jatah harian.',
      };

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluAnalysisScreen(itemId: 'td-ui-1'),
          overrides: [
            purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Cek nama barang
      expect(find.text('Mechanical Keyboard RGB'), findsOneWidget);

      // Cek banner Bridge Mode
      expect(find.textContaining('Periode Transisi (Bridge Mode)'), findsOneWidget);

      // Cek banner rekomendasi
      expect(find.text('Pertimbangkan Kembali (Tahan Dulu)'), findsOneWidget);
      expect(find.text('Budget cukup namun melebihi jatah harian.'), findsOneWidget);

      // Cek kartu budget & saldo
      expect(find.text(AppStrings.flexibleBudgetLabel), findsOneWidget);
      expect(find.text('Total Saldo Rekening'), findsOneWidget);

      // Cek kewajiban terjadwal
      expect(find.textContaining('Kewajiban terjadwal'), findsOneWidget);
    });

    testWidgets('TahanDuluDecideScreen shows confirm options and handles mark as bought without transaction', (tester) async {
      final item = PurchaseConsideration(
        id: 'td-ui-2',
        itemName: 'Buku Pemrograman',
        price: 150000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.education,
      );

      final fakeRepo = _MockFase4CPurchaseRepo([item]);
      final fakeAccountRepo = _MockAccountRepo([
        const FinancialAccount(
          id: '1',
          name: 'BCA Utama',
          type: AccountType.bank,
          balance: 2000000,
        ),
      ]);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluDecideScreen(itemId: 'td-ui-2'),
          overrides: [
            purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
            accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Cek tampilan layar keputusan
      expect(find.text(AppStrings.decideTitle), findsOneWidget);
      expect(find.text('Buku Pemrograman'), findsOneWidget);

      // Tap opsi "Beli Sekarang"
      final buyButton = find.text(AppStrings.decideBuy);
      expect(buyButton, findsOneWidget);
      await tester.tap(buyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi bottom sheet konfirmasi pembelian muncul dengan 2 opsi terpisah
      expect(find.text('Konfirmasi Pembelian'), findsOneWidget);
      expect(find.text('Catat Pembelian & Potong Saldo'), findsOneWidget);
      expect(find.text('Tandai Dibeli Saja (Tanpa Transaksi)'), findsOneWidget);

      // Tap opsi "Tandai Dibeli Saja"
      await tester.tap(find.text('Tandai Dibeli Saja (Tanpa Transaksi)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pastikan status di repo berubah menjadi bought
      expect(fakeRepo.items.first.status, ConsiderationStatus.bought);
      // Pastikan recordPurchase (transaksi mutasi saldo) TIDAK dipanggil
      expect(fakeRepo.recordPurchaseCalled, isFalse);
    });

    testWidgets('TahanDuluDecideScreen handles record purchase with account selection', (tester) async {
      final item = PurchaseConsideration(
        id: 'td-ui-3',
        itemName: 'Mouse Gaming',
        price: 250000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.electronics,
      );

      final fakeRepo = _MockFase4CPurchaseRepo([item]);
      final fakeAccountRepo = _MockAccountRepo([
        const FinancialAccount(
          id: '10',
          name: 'Bank Jago',
          type: AccountType.digitalBank,
          balance: 1500000,
        ),
      ]);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluDecideScreen(itemId: 'td-ui-3'),
          overrides: [
            purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
            accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap opsi "Beli Sekarang"
      await tester.tap(find.text(AppStrings.decideBuy));
      await tester.pumpAndSettle();

      // Tap opsi "Catat Pembelian & Potong Saldo"
      await tester.tap(find.text('Catat Pembelian & Potong Saldo'));
      await tester.pumpAndSettle();

      // Verifikasi bottom sheet pemilihan rekening muncul
      expect(find.text('Pilih Rekening Pembayaran'), findsOneWidget);
      expect(find.text('Bank Jago'), findsOneWidget);

      // Pilih rekening Bank Jago
      await tester.tap(find.text('Bank Jago'));
      await tester.pumpAndSettle();

      // Pastikan recordPurchase dipanggil dengan accountId '10'
      expect(fakeRepo.recordPurchaseCalled, isTrue);
      expect(fakeRepo.lastRecordedAccountId, '10');
      expect(fakeRepo.items.first.status, ConsiderationStatus.bought);
    });

    testWidgets('TahanDuluDecideScreen prevents purchase and shows error when account balance is insufficient', (tester) async {
      final item = PurchaseConsideration(
        id: 'td-ui-overdraft',
        itemName: 'Kamera Mirrorless',
        price: 8000000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.electronics,
      );

      final fakeRepo = _MockFase4CPurchaseRepo([item]);
      // Akun dengan saldo hanya Rp1.000.000 (< Rp8.000.000)
      final fakeAccountRepo = _MockAccountRepo([
        const FinancialAccount(
          id: '20',
          name: 'BCA Tabungan',
          type: AccountType.bank,
          balance: 1000000,
        ),
      ]);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluDecideScreen(itemId: 'td-ui-overdraft'),
          overrides: [
            purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
            accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap opsi "Beli Sekarang"
      await tester.tap(find.text(AppStrings.decideBuy));
      await tester.pumpAndSettle();

      // Tap opsi "Catat Pembelian & Potong Saldo"
      await tester.tap(find.text('Catat Pembelian & Potong Saldo'));
      await tester.pumpAndSettle();

      // Verifikasi bottom sheet menampilkan rekening dengan badge "Saldo Kurang"
      expect(find.text('Pilih Rekening Pembayaran'), findsOneWidget);
      expect(find.text('BCA Tabungan'), findsOneWidget);
      expect(find.text('Saldo Kurang'), findsOneWidget);

      // Coba tap rekening yang saldonya kurang
      await tester.tap(find.text('BCA Tabungan'));
      await tester.pump(); // trigger snackbar

      // Verifikasi SnackBar overdraft muncul
      expect(find.textContaining('tidak mencukupi untuk membayar'), findsOneWidget);

      // Pastikan recordPurchase TIDAK dipanggil dan status item tetap considering
      expect(fakeRepo.recordPurchaseCalled, isFalse);
      expect(fakeRepo.items.first.status, ConsiderationStatus.considering);
    });
  });
}
