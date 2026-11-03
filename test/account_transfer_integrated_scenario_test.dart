import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/data/providers/reports_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';

class ScenarioAccountRepository implements AccountRepository {
  ScenarioAccountRepository(List<FinancialAccount> initial)
      : accounts = List.from(initial);

  final List<FinancialAccount> accounts;

  @override
  Future<List<FinancialAccount>> getAccounts() async => List.unmodifiable(accounts);

  @override
  Future<double> getTotalBalance() async =>
      accounts.fold<double>(0.0, (sum, a) => sum + a.balance);

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

  @override
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {
    final fromIdx = accounts.indexWhere((a) => a.id == fromId);
    final toIdx = accounts.indexWhere((a) => a.id == toId);
    if (fromIdx == -1 || toIdx == -1) {
      throw Exception('Akun tidak ditemukan');
    }
    final fromAcc = accounts[fromIdx];
    final toAcc = accounts[toIdx];
    if (fromAcc.balance < amount) {
      throw Exception('Saldo instrumen sumber tidak mencukupi.');
    }
    accounts[fromIdx] = FinancialAccount(
      id: fromAcc.id,
      name: fromAcc.name,
      type: fromAcc.type,
      typeId: fromAcc.typeId,
      balance: fromAcc.balance - amount,
      institutionName: fromAcc.institutionName,
    );
    accounts[toIdx] = FinancialAccount(
      id: toAcc.id,
      name: toAcc.name,
      type: toAcc.type,
      typeId: toAcc.typeId,
      balance: toAcc.balance + amount,
      institutionName: toAcc.institutionName,
    );
  }
}

class ScenarioTransactionRepository implements TransactionRepository {
  ScenarioTransactionRepository(List<AppTransaction> initial)
      : txs = List.from(initial);

  final List<AppTransaction> txs;

  @override
  Future<List<AppTransaction>> getRecentTransactions() async => List.unmodifiable(txs);

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    txs.insert(0, transaction);
    return transaction;
  }

  @override
  Future<AppTransaction> getTransactionById(String id) async =>
      txs.firstWhere((t) => t.id == id);

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    int? instrumentId,
    int? perPage,
  }) async {
    var filtered = txs.where((t) => true);
    if (instrumentId != null) {
      filtered = filtered.where((t) => t.accountId == instrumentId.toString());
    }
    if (category != null) {
      filtered = filtered.where((t) => t.category == category);
    }
    return filtered.toList();
  }

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async {
    final idx = txs.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) txs[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    txs.removeWhere((t) => t.id == id);
  }
}

void main() {
  test('Integrated Scenario: BCA & Mandiri, Transfer, Expense, Income, and Cashflow Isolation', () async {
    final now = DateTime.now();

    // Kondisi awal:
    // - Akun BCA Rp1.000.000
    // - Akun Mandiri Rp500.000
    // - Total Rp1.500.000
    final accountRepo = ScenarioAccountRepository([
      const FinancialAccount(
        id: 'acc-bca',
        name: 'BCA',
        type: AccountType.bank,
        balance: 1000000,
      ),
      const FinancialAccount(
        id: 'acc-mandiri',
        name: 'Mandiri',
        type: AccountType.bank,
        balance: 500000,
      ),
    ]);

    final txRepo = ScenarioTransactionRepository([]);

    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepo),
        transactionRepositoryProvider.overrideWithValue(txRepo),
        dashboardRepositoryProvider.overrideWithValue(MockDashboardRepository()),
        goalRepositoryProvider.overrideWithValue(MockGoalRepository()),
        notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
        purchaseDecisionRepositoryProvider.overrideWithValue(MockPurchaseDecisionRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
        currentBudgetProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(accountsControllerProvider);

    // Langkah 1: Transfer Rp200.000 dari BCA ke Mandiri
    final transferOk = await controller.transfer(
      fromId: 'acc-bca',
      toId: 'acc-mandiri',
      amount: 200000,
      notes: 'Pindahan saldo tabungan',
    );
    expect(transferOk, isTrue);

    // Catat mutasi transaksi transfer
    await txRepo.addTransaction(
      AppTransaction(
        id: 'tx-tf-out',
        title: 'Transfer Keluar ke Mandiri',
        type: TransactionType.expense,
        category: 'Transfer',
        amount: 200000,
        date: now,
        accountId: 'acc-bca',
      ),
    );
    await txRepo.addTransaction(
      AppTransaction(
        id: 'tx-tf-in',
        title: 'Transfer Masuk dari BCA',
        type: TransactionType.income,
        category: 'Transfer',
        amount: 200000,
        date: now,
        accountId: 'acc-mandiri',
      ),
    );

    var accounts = await accountRepo.getAccounts();
    expect(accounts.firstWhere((a) => a.id == 'acc-bca').balance, 800000);
    expect(accounts.firstWhere((a) => a.id == 'acc-mandiri').balance, 700000);
    expect(await accountRepo.getTotalBalance(), 1500000);

    // Langkah 2: Catat pengeluaran aktual Rp150.000 dari Mandiri
    await accountRepo.updateAccount(
      const FinancialAccount(
        id: 'acc-mandiri',
        name: 'Mandiri',
        type: AccountType.bank,
        balance: 550000, // 700.000 - 150.000
      ),
    );
    await txRepo.addTransaction(
      AppTransaction(
        id: 'tx-exp-1',
        title: 'Belanja Sayur',
        type: TransactionType.expense,
        category: 'makanan',
        amount: 150000,
        date: now,
        accountId: 'acc-mandiri',
      ),
    );

    // Langkah 3: Catat pemasukan aktual Rp100.000 ke BCA
    await accountRepo.updateAccount(
      const FinancialAccount(
        id: 'acc-bca',
        name: 'BCA',
        type: AccountType.bank,
        balance: 900000, // 800.000 + 100.000
      ),
    );
    await txRepo.addTransaction(
      AppTransaction(
        id: 'tx-inc-1',
        title: 'Freelance Pemasukan',
        type: TransactionType.income,
        category: 'gaji',
        amount: 100000,
        date: now,
        accountId: 'acc-bca',
      ),
    );

    // Langkah 4: Verifikasi Saldo Akhir
    accounts = await accountRepo.getAccounts();
    final bcaFinal = accounts.firstWhere((a) => a.id == 'acc-bca');
    final mandiriFinal = accounts.firstWhere((a) => a.id == 'acc-mandiri');
    final totalFinal = await accountRepo.getTotalBalance();

    expect(bcaFinal.balance, 900000, reason: 'Saldo BCA akhir harus Rp900.000');
    expect(mandiriFinal.balance, 550000, reason: 'Saldo Mandiri akhir harus Rp550.000');
    expect(totalFinal, 1450000, reason: 'Total saldo akhir harus Rp1.450.000');

    // Langkah 5: Periksa Dashboard Data
    final dashboard = await container.read(dashboardDataProvider.future);
    expect(dashboard.totalBalance, 1450000, reason: 'Total saldo dashboard harus Rp1.450.000');
    expect(dashboard.actualMonthIncome, 100000, reason: 'Pemasukan bulanan dashboard HANYA pemasukan eksternal Rp100.000');
    expect(dashboard.actualMonthExpense, 150000, reason: 'Pengeluaran bulanan dashboard HANYA pengeluaran eksternal Rp150.000');

    // Langkah 6: Periksa Laporan Bulanan
    final report = await container.read(monthlyReportProvider(DateTime(now.year, now.month)).future);
    expect(report.income, 100000, reason: 'Laporan pemasukan harus Rp100.000');
    expect(report.expense, 150000, reason: 'Laporan pengeluaran harus Rp150.000');
    expect(
      report.categories.any((c) => c.label.toLowerCase() == 'transfer'),
      isFalse,
      reason: 'Kategori Transfer TIDAK boleh muncul dalam breakdown pengeluaran laporan',
    );
    expect(
      report.categories.firstWhere((c) => c.label == 'makanan').amount,
      150000,
      reason: 'Kategori makanan harus mencatat pengeluaran riil Rp150.000',
    );
  });
}
