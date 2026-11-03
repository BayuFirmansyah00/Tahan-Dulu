import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final client = ApiClient(baseUrl: baseUrl);

  group('TahanDulu Goals End-to-End Remote Integration Verification', () {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userAEmail = 'alice_$timestamp@example.com';
    final userBEmail = 'bob_$timestamp@example.com';
    const password = 'Password123!';

    final tokenStoreA = MemoryTokenStore();
    final tokenStoreB = MemoryTokenStore();

    late RemoteAuthRepository authRepoA;
    late RemoteGoalRepository goalRepoA;
    late RemoteAccountRepository accountRepoA;
    late RemoteTransactionRepository transactionRepoA;

    late RemoteAuthRepository authRepoB;
    late RemoteGoalRepository goalRepoB;

    setUpAll(() async {
      authRepoA = RemoteAuthRepository(client: client, tokens: tokenStoreA);
      goalRepoA = RemoteGoalRepository(client: client, tokens: tokenStoreA);
      accountRepoA = RemoteAccountRepository(client: client, tokens: tokenStoreA);
      transactionRepoA = RemoteTransactionRepository(client: client, tokens: tokenStoreA);

      authRepoB = RemoteAuthRepository(client: client, tokens: tokenStoreB);
      goalRepoB = RemoteGoalRepository(client: client, tokens: tokenStoreB);
    });

    test('1. Setup User A dan registrasi pada backend Laravel', () async {
      final userA = await authRepoA.register(
        name: 'Alice Integrasi',
        email: userAEmail,
        password: password,
      );

      expect(userA.email, userAEmail);
      final tokenA = await tokenStoreA.readToken();
      expect(tokenA, isNotNull);
      expect(tokenA!.isNotEmpty, isTrue);
    });

    test('2. CRUD Target, perubahan prioritas, tie-breaker tenggat waktu, dan persistensi', () async {
      // Buat 3 Target:
      // Goal A: priority 1, deadline 2026-12-15
      // Goal B: priority 0, deadline 2026-11-01
      // Goal C: priority 1, deadline 2026-10-31 (tie priority dengan Goal A, tapi tenggat lebih dekat)
      final createdGoalA = await goalRepoA.addGoal(
        FinancialGoal(
          id: 'temp-a',
          name: 'Tabungan Liburan',
          targetAmount: 10000000,
          currentAmount: 0,
          category: GoalCategory.holiday,
          frequency: DepositFrequency.monthly,
          deadline: DateTime(2026, 12, 15),
          priority: 1,
        ),
      );

      final createdGoalB = await goalRepoA.addGoal(
        FinancialGoal(
          id: 'temp-b',
          name: 'Dana Darurat Siaga',
          targetAmount: 20000000,
          currentAmount: 0,
          category: GoalCategory.emergency,
          frequency: DepositFrequency.monthly,
          deadline: DateTime(2026, 11, 1),
          priority: 0,
        ),
      );

      final createdGoalC = await goalRepoA.addGoal(
        FinancialGoal(
          id: 'temp-c',
          name: 'Beli Gadget Baru',
          targetAmount: 5000000,
          currentAmount: 0,
          category: GoalCategory.gadget,
          frequency: DepositFrequency.monthly,
          deadline: DateTime(2026, 10, 31),
          priority: 1,
        ),
      );

      expect(int.parse(createdGoalA.id), greaterThan(0));
      expect(int.parse(createdGoalB.id), greaterThan(0));
      expect(int.parse(createdGoalC.id), greaterThan(0));

      // Ambil ulang dari backend untuk verifikasi sorting backend:
      // Urutan: Goal B (prio 0), lalu Goal C (prio 1, tenggat 31 Okt), lalu Goal A (prio 1, tenggat 15 Des)
      final list1 = await goalRepoA.getGoals();
      expect(list1.length, 3);
      expect(list1[0].id, createdGoalB.id);
      expect(list1[1].id, createdGoalC.id);
      expect(list1[2].id, createdGoalA.id);

      // Update Goal A
      final updatedA = await goalRepoA.updateGoal(
        createdGoalA.copyWith(
          name: 'Tabungan Liburan Jepang',
          targetAmount: 12000000,
        ),
      );
      expect(updatedA.name, 'Tabungan Liburan Jepang');
      expect(updatedA.targetAmount, 12000000);

      // Verifikasi via getGoalById
      final fetchedA = await goalRepoA.getGoalById(createdGoalA.id);
      expect(fetchedA.name, 'Tabungan Liburan Jepang');
      expect(fetchedA.targetAmount, 12000000);

      // Reorder Target secara manual via saveGoalOrder:
      // Jadikan urutan: [Goal A, Goal B, Goal C]
      await goalRepoA.saveGoalOrder([createdGoalA.id, createdGoalB.id, createdGoalC.id]);

      // Ambil ulang dari remote backend untuk verifikasi persistensi reorder
      final listAfterReorder = await goalRepoA.getGoals();
      expect(listAfterReorder[0].id, createdGoalA.id);
      expect(listAfterReorder[1].id, createdGoalB.id);
      expect(listAfterReorder[2].id, createdGoalC.id);
    });

    test('3. Penambahan alokasi target tidak mengubah saldo akun riil atau total aset', () async {
      // Buat akun rekening riil Alice
      final bcaAccount = await accountRepoA.addAccount(
        const FinancialAccount(
          id: 'temp-bca',
          name: 'BCA Utama',
          type: AccountType.bank,
          balance: 10000000,
        ),
      );
      expect(bcaAccount.balance, 10000000);

      final totalBefore = await accountRepoA.getTotalBalance();
      expect(totalBefore, 10000000);

      final goals = await goalRepoA.getGoals();
      final emergencyGoal = goals.firstWhere((g) => g.category == GoalCategory.emergency);
      expect(emergencyGoal.currentAmount, 0);

      // Alokasikan Rp 2.500.000 ke Target Dana Darurat
      final deposit = await goalRepoA.addDeposit(
        GoalDeposit(
          id: 'temp-dep',
          goalId: emergencyGoal.id,
          amount: 2500000,
          date: DateTime.now(),
          note: 'Alokasi tabungan pertama',
        ),
      );
      expect(deposit.amount, 2500000);

      // Ambil ulang target: currentAmount harus bertambah menjadi 2.500.000
      final updatedEmergencyGoal = await goalRepoA.getGoalById(emergencyGoal.id);
      expect(updatedEmergencyGoal.currentAmount, 2500000);

      // Verifikasi riwayat setoran
      final deposits = await goalRepoA.getDeposits(emergencyGoal.id);
      expect(deposits.length, 1);
      expect(deposits.first.amount, 2500000);

      // KRUSIAL: Saldo akun BCA dan total aset TIDAK BERUBAH
      final accountsAfterDeposit = await accountRepoA.getAccounts();
      final freshBca = accountsAfterDeposit.firstWhere((a) => a.id == bcaAccount.id);
      expect(freshBca.balance, 10000000);

      final totalAfter = await accountRepoA.getTotalBalance();
      expect(totalAfter, 10000000);
    });

    test('4. Pembelian nyata terkait target memotong saldo tepat satu kali', () async {
      final accounts = await accountRepoA.getAccounts();
      final bca = accounts.first;
      expect(bca.balance, 10000000);

      // Catat transaksi pengeluaran aktual (mis. beli perlengkapan/tiket liburan Rp 3.000.000)
      final tx = await transactionRepoA.addTransaction(
        AppTransaction(
          id: 'temp-tx',
          title: 'Beli Tiket Liburan Jepang',
          amount: 3000000,
          type: TransactionType.expense,
          date: DateTime.now(),
          accountId: bca.id,
          category: 'Liburan',
          note: 'Pengeluaran riil untuk liburan',
        ),
      );
      expect(tx.amount, 3000000);

      // Saldo akun riil dan total aset berkurang tepat satu kali sebesar Rp 3.000.000
      final accountsAfterTx = await accountRepoA.getAccounts();
      final bcaAfterTx = accountsAfterTx.firstWhere((a) => a.id == bca.id);
      expect(bcaAfterTx.balance, 7000000);

      final totalAfterTx = await accountRepoA.getTotalBalance();
      expect(totalAfterTx, 7000000);

      // Transaksi pengeluaran tercatat satu kali di riwayat
      final recent = await transactionRepoA.getRecentTransactions();
      final txMatch = recent.where((t) => t.title == 'Beli Tiket Liburan Jepang');
      expect(txMatch.length, 1);

      // Target Dana Darurat alokasinya tetap utuh (Rp 2.500.000)
      final goals = await goalRepoA.getGoals();
      final emergencyGoal = goals.firstWhere((g) => g.category == GoalCategory.emergency);
      expect(emergencyGoal.currentAmount, 2500000);
    });

    test('5. Hapus target tidak merusak transaksi historis atau saldo akun riil', () async {
      final goals = await goalRepoA.getGoals();
      final emergencyGoal = goals.firstWhere((g) => g.category == GoalCategory.emergency);

      // Hapus target Dana Darurat yang memiliki alokasi Rp 2.500.000
      await goalRepoA.deleteGoal(emergencyGoal.id);

      // Verifikasi target sudah terhapus dari backend
      final goalsAfterDelete = await goalRepoA.getGoals();
      expect(goalsAfterDelete.any((g) => g.id == emergencyGoal.id), isFalse);

      // Verifikasi transaksi pengeluaran riil tetap ada dan utuh di tabel transactions
      final recent = await transactionRepoA.getRecentTransactions();
      expect(recent.any((t) => t.title == 'Beli Tiket Liburan Jepang'), isTrue);

      // Verifikasi saldo akun riil tetap Rp 7.000.000 (tidak berubah)
      final accounts = await accountRepoA.getAccounts();
      expect(accounts.first.balance, 7000000);
      expect(await accountRepoA.getTotalBalance(), 7000000);
    });

    test('6. Isolasi data multi-akun: Akun B tidak bisa melihat atau memodifikasi target Akun A', () async {
      // Registrasi Akun B (Bob)
      final userB = await authRepoB.register(
        name: 'Bob Integrasi',
        email: userBEmail,
        password: password,
      );
      expect(userB.email, userBEmail);

      // Bob memuat daftar target: harus kosong (tidak boleh ada target milik Alice)
      final bobGoals = await goalRepoB.getGoals();
      expect(bobGoals, isEmpty);

      // Dapatkan salah satu target milik Alice yang masih ada
      final aliceGoals = await goalRepoA.getGoals();
      expect(aliceGoals.isNotEmpty, isTrue);
      final aliceGoal = aliceGoals.first;

      // Bob mencoba mengakses detail target Alice secara langsung -> harus ditolak (404/403)
      expect(
        () => goalRepoB.getGoalById(aliceGoal.id),
        throwsA(isA<ApiException>()),
      );

      // Bob mencoba mengupdate target milik Alice -> harus ditolak (404/403)
      expect(
        () => goalRepoB.updateGoal(aliceGoal.copyWith(name: 'Dibajak oleh Bob')),
        throwsA(isA<ApiException>()),
      );

      // Bob mencoba menghapus target milik Alice -> harus ditolak (404/403)
      expect(
        () => goalRepoB.deleteGoal(aliceGoal.id),
        throwsA(isA<ApiException>()),
      );

      // Bob logout (bersihkan token)
      await authRepoB.logout();
      expect(await tokenStoreB.readToken(), isNull);

      // Alice login ulang
      final reloadedAlice = await authRepoA.loginWithEmail(
        email: userAEmail,
        password: password,
      );
      expect(reloadedAlice.email, userAEmail);

      // Target milik Alice tetap utuh dan aman
      final verifiedAliceGoals = await goalRepoA.getGoals();
      expect(verifiedAliceGoals.length, aliceGoals.length);
      expect(verifiedAliceGoals.first.id, aliceGoal.id);
    });
  });
}

