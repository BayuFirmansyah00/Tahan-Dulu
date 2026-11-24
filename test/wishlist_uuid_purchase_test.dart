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
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_decide_screen.dart';

class _MockUuidPurchaseRepo implements PurchaseDecisionRepository {
  _MockUuidPurchaseRepo(this.items);

  final List<PurchaseConsideration> items;
  bool recordPurchaseCalled = false;
  String? lastRecordedAccountId;
  String? lastRecordedItemId;

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
  Future<Map<String, dynamic>> getPurchaseAnalysis(String id) async => {
        'can_afford': true,
        'recommendation': 'ready',
        'recommendation_title': 'Kondisi Finansial Mendukung',
        'recommendation_reason': 'Saldo rekening dan anggaran mencukupi.',
      };

  @override
  Future<Map<String, dynamic>> recordPurchase(
    String id, {
    required String accountId,
    String? information,
    String? idempotencyKey,
  }) async {
    recordPurchaseCalled = true;
    lastRecordedItemId = id;
    lastRecordedAccountId = accountId;
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(status: ConsiderationStatus.bought);
    }
    return {
      'success': true,
      'message': 'Pembelian berhasil dicatat ke buku kas.',
      'account_id': accountId,
    };
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
      GoRoute(
        path: '${AppRoutes.tahanDulu}/:id/success',
        builder: (_, _) => const Scaffold(body: Text('SUCCESS_PAGE')),
      ),
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
  group('F03 Wishlist UUID Purchase Contract Test', () {
    testWidgets('Preserves full UUID without converting to 0 or int truncation', (tester) async {
      const testUuidAccount = '550e8400-e29b-41d4-a716-446655440000';
      const testUuidWishlist = 'uuid-item-123';

      final item = PurchaseConsideration(
        id: testUuidWishlist,
        itemName: 'Headphone Sony WH-1000XM5',
        price: 4500000,
        status: ConsiderationStatus.considering,
        createdAt: DateTime.now(),
        category: ProductCategory.electronics,
      );

      final fakeRepo = _MockUuidPurchaseRepo([item]);
      final fakeAccountRepo = _MockAccountRepo([
        const FinancialAccount(
          id: testUuidAccount,
          name: 'Bank Central Asia (BCA)',
          type: AccountType.bank,
          balance: 10000000,
        ),
      ]);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluDecideScreen(itemId: testUuidWishlist),
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

      // Pastikan bottom sheet muncul dan menampilkan Bank Central Asia
      expect(find.text('Pilih Rekening Pembayaran'), findsOneWidget);
      expect(find.text('Bank Central Asia (BCA)'), findsOneWidget);

      // Tap rekening dengan UUID
      await tester.tap(find.text('Bank Central Asia (BCA)'));
      await tester.pumpAndSettle();

      // Verifikasi: recordPurchase terpanggil dengan UUID persis, BUKAN 0
      expect(fakeRepo.recordPurchaseCalled, isTrue);
      expect(fakeRepo.lastRecordedItemId, testUuidWishlist);
      expect(fakeRepo.lastRecordedAccountId, testUuidAccount);
      expect(fakeRepo.lastRecordedAccountId, isNot('0'));
    });
  });
}
