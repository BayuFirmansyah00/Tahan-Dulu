import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_purchase_decision_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final client = ApiClient(baseUrl: baseUrl);

  group('Tahan Dulu Live End-to-End Remote Integration Verification', () {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userAEmail = 'alice_td_$timestamp@example.com';
    final userBEmail = 'bob_td_$timestamp@example.com';
    const password = 'Password123!';

    final tokenStoreA = MemoryTokenStore();
    final tokenStoreB = MemoryTokenStore();

    late RemoteAuthRepository authRepoA;
    late RemoteAccountRepository accountRepoA;
    late RemoteTransactionRepository transactionRepoA;
    late RemotePurchaseDecisionRepository tahanDuluRepoA;

    late RemoteAuthRepository authRepoB;
    late RemotePurchaseDecisionRepository tahanDuluRepoB;

    String? itemAId;

    setUpAll(() async {
      authRepoA = RemoteAuthRepository(client: client, tokens: tokenStoreA);
      accountRepoA = RemoteAccountRepository(client: client, tokens: tokenStoreA);
      transactionRepoA = RemoteTransactionRepository(client: client, tokens: tokenStoreA);
      tahanDuluRepoA = RemotePurchaseDecisionRepository(client: client, tokens: tokenStoreA);

      authRepoB = RemoteAuthRepository(client: client, tokens: tokenStoreB);
      tahanDuluRepoB = RemotePurchaseDecisionRepository(client: client, tokens: tokenStoreB);
    });

    test('1. Setup User A dan User B registrasi pada backend Laravel', () async {
      final userA = await authRepoA.register(
        name: 'Alice Tahan Dulu',
        email: userAEmail,
        password: password,
      );
      expect(userA.email, userAEmail);
      final tokenA = await tokenStoreA.readToken();
      expect(tokenA, isNotNull);

      final userB = await authRepoB.register(
        name: 'Bob Tahan Dulu',
        email: userBEmail,
        password: password,
      );
      expect(userB.email, userBEmail);
      final tokenB = await tokenStoreB.readToken();
      expect(tokenB, isNotNull);
    });

    test('2. Setup akun keuangan awal User A (saldo Rp5.000.000)', () async {
      final acc = await accountRepoA.addAccount(
        const FinancialAccount(
          id: '',
          name: 'Rekening Operasional Alice',
          type: AccountType.bank,
          balance: 5000000,
          typeId: 1,
        ),
      );
      expect(acc.balance, 5000000.0);

      final totalBalance = await accountRepoA.getTotalBalance();
      expect(totalBalance, 5000000.0);
    });

    test('3. Buat evaluasi pembelian Tahan Dulu di backend Laravel', () async {
      final item = await tahanDuluRepoA.addConsideration(
        PurchaseConsideration(
          id: 'temp-1',
          itemName: 'Sony WH-1000XM5',
          price: 4999000,
          status: ConsiderationStatus.considering,
          category: ProductCategory.electronics,
          createdAt: DateTime.now(),
          productUrl: 'https://sony.co.id/headphones/xm5',
          reason: 'Untuk fokus saat kerja',
        ),
      );

      expect(item.id, isNotEmpty);
      expect(item.id, isNot('temp-1')); // Backend returns real database ID
      expect(item.itemName, 'Sony WH-1000XM5');
      expect(item.price, 4999000.0);
      expect(item.status, ConsiderationStatus.considering);
      expect(item.category, ProductCategory.electronics);
      expect(item.productUrl, 'https://sony.co.id/headphones/xm5');

      itemAId = item.id;

      // Verifikasi daftar dari backend
      final list = await tahanDuluRepoA.getConsiderations();
      expect(list.any((e) => e.id == itemAId), isTrue);

      // Verifikasi KONSISTENSI FINANSIAL: Saldo tidak berkurang dan transaksi tidak bertambah
      final balance = await accountRepoA.getTotalBalance();
      expect(balance, 5000000.0);

      final txs = await transactionRepoA.getTransactions();
      expect(txs.isEmpty, isTrue);
    });

    test('4. Mulai masa tunggu (cooling-off period) 48 jam di backend', () async {
      final now = DateTime.now();
      final list = await tahanDuluRepoA.getConsiderations();
      final existing = list.firstWhere((e) => e.id == itemAId);

      final updated = await tahanDuluRepoA.updateConsideration(
        existing.copyWith(
          waitHours: 48,
          waitStartedAt: now,
          waitEndsAt: now.add(const Duration(hours: 48)),
        ),
      );

      expect(updated.waitHours, 48);
      expect(updated.waitStartedAt, isNotNull);
      expect(updated.waitEndsAt, isNotNull);
      expect(updated.isWaitingAt(now), isTrue);

      // Verifikasi saldo tetap utuh Rp5.000.000
      final balance = await accountRepoA.getTotalBalance();
      expect(balance, 5000000.0);
    });

    test('5. Transisi status keputusan (considering -> wishlist -> bought -> cancelled)', () async {
      final list = await tahanDuluRepoA.getConsiderations();
      final existing = list.firstWhere((e) => e.id == itemAId);

      // A. Simpan ke Wishlist
      final toWishlist = await tahanDuluRepoA.updateConsideration(
        existing.copyWith(status: ConsiderationStatus.wishlist),
      );
      expect(toWishlist.status, ConsiderationStatus.wishlist);

      // B. Tandai Dibeli (bought)
      final toBought = await tahanDuluRepoA.updateConsideration(
        existing.copyWith(status: ConsiderationStatus.bought),
      );
      expect(toBought.status, ConsiderationStatus.bought);
      expect(toBought.isFinal, isTrue);

      // C. Tandai Dibatalkan (cancelled)
      final toCancelled = await tahanDuluRepoA.updateConsideration(
        existing.copyWith(status: ConsiderationStatus.cancelled),
      );
      expect(toCancelled.status, ConsiderationStatus.cancelled);
      expect(toCancelled.isFinal, isTrue);

      // Verifikasi saldo tetap utuh (Tahan Dulu tidak mengubah saldo riil)
      final balance = await accountRepoA.getTotalBalance();
      expect(balance, 5000000.0);
    });

    test('6. Isolasi data multi-user: User B tidak dapat melihat atau memodifikasi item User A', () async {
      // User B getConsiderations harus kosong
      final listB = await tahanDuluRepoB.getConsiderations();
      expect(listB.any((e) => e.id == itemAId), isFalse);

      // User B mencoba update item User A harus ditolak (404)
      expect(
        () => tahanDuluRepoB.updateConsideration(
          PurchaseConsideration(
            id: itemAId!,
            itemName: 'Hacked by User B',
            price: 100,
            status: ConsiderationStatus.bought,
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ApiException>()),
      );

      // User B mencoba delete item User A harus ditolak (404)
      expect(
        () => tahanDuluRepoB.deleteConsideration(itemAId!),
        throwsA(isA<ApiException>()),
      );
    });

    test('7. User A menghapus item dari backend', () async {
      await tahanDuluRepoA.deleteConsideration(itemAId!);

      final listAfterDelete = await tahanDuluRepoA.getConsiderations();
      expect(listAfterDelete.any((e) => e.id == itemAId), isFalse);

      // Verifikasi saldo tetap utuh
      final balance = await accountRepoA.getTotalBalance();
      expect(balance, 5000000.0);
    });
  });
}
