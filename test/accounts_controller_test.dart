import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

Future<List<FinancialAccount>> _accounts(ProviderContainer c) =>
    c.read(accountRepositoryProvider).getAccounts();

void main() {
  test('list seeded from single canonical source', () async {
    final accounts = await _container().read(accountRepositoryProvider)
        .getAccounts();

    expect(accounts.length, 3);
    expect(accounts.map((e) => e.id),
        ['inst-bca', 'inst-jago', 'inst-cash']);
    // BCA membawa nama institusi sesuai desain.
    expect(accounts.first.institutionName, 'BCA');
  });

  test('add account validates and appears with updated total', () async {
    final container = _container();
    final controller = container.read(accountsControllerProvider);

    expect(
      await controller.addAccount(
          name: '  ', type: AccountType.ewallet, initialBalance: 100000),
      isFalse,
    );
    expect(
      await controller.addAccount(
          name: 'DANA', type: AccountType.ewallet, initialBalance: -1),
      isFalse,
    );
    expect(
      await controller.addAccount(
        name: 'DANA',
        type: AccountType.ewallet,
        initialBalance: 750000,
        institutionName: 'DANA Indonesia',
      ),
      isTrue,
    );

    final accounts = await _accounts(container);
    expect(accounts.length, 4);
    final dana = accounts.last;
    expect(dana.name, 'DANA');
    expect(dana.type, AccountType.ewallet);
    expect(dana.balance, 750000);
    expect(dana.institutionName, 'DANA Indonesia');

    final overviews =
        await container.read(accountsOverviewProvider.future);
    expect(overviews.length, 4);
    final total = await container.read(accountsTotalProvider.future);
    expect(total, 6500000 + 750000);
  });

  test('update preserves relations and unrelated fields', () async {
    final container = _container();
    final controller = container.read(accountsControllerProvider);

    expect(
      await controller.updateAccount(
        id: 'inst-bca',
        name: 'BCA Utama',
        type: AccountType.bank,
        initialBalance: 6000000,
        institutionName: 'Bank Central Asia',
      ),
      isTrue,
    );

    final repo = container.read(onboardingRepositoryProvider);
    final updated = repo
        .getOnboardingData()!
        .financialInstruments
        .firstWhere((e) => e.id == 'inst-bca');
    expect(updated.name, 'BCA Utama');
    expect(updated.initialBalance, 6000000);
    expect(updated.institutionName, 'Bank Central Asia');
    // Fee & flag No.4 tidak ikut berubah.
    expect(updated.monthlyAdminFee, 14000);
    expect(updated.isSelected, isTrue);

    expect(
      await controller.updateAccount(
        id: 'tidak-ada',
        name: 'X',
        type: AccountType.bank,
        initialBalance: 0,
      ),
      isFalse,
    );
  });

  test('per-account balance follows linked transactions only', () async {
    final container = _container();
    final txRepo = container.read(transactionRepositoryProvider);
    await txRepo.addTransaction(
      AppTransaction(
        id: 'trx-acc-1',
        title: 'Gaji',
        amount: 200000,
        type: TransactionType.income,
        date: DateTime.now(),
        category: 'Gaji',
        accountId: 'inst-jago',
      ),
    );
    await txRepo.addTransaction(
      AppTransaction(
        id: 'trx-acc-2',
        title: 'Jajan',
        amount: 50000,
        type: TransactionType.expense,
        date: DateTime.now(),
        category: 'Lainnya',
        accountId: 'inst-jago',
      ),
    );
    container.invalidate(accountsOverviewProvider);

    final overviews =
        await container.read(accountsOverviewProvider.future);
    final jago = overviews.firstWhere((e) => e.account.id == 'inst-jago');
    expect(jago.currentBalance, 1000000 + 200000 - 50000);
    expect(jago.transactionCount, 2);
    // Akun lain tak terpengaruh.
    final bca = overviews.firstWhere((e) => e.account.id == 'inst-bca');
    expect(bca.currentBalance, 5000000);
  });

  test('unknown account transactions touch nothing', () async {
    final container = _container();
    await container.read(transactionRepositoryProvider).addTransaction(
          AppTransaction(
            id: 'trx-acc-3',
            title: 'Misteri',
            amount: 999000,
            type: TransactionType.expense,
            date: DateTime.now(),
            category: 'Lainnya',
            accountId: 'acc-tidak-ada',
          ),
        );
    container.invalidate(accountsOverviewProvider);

    final total = await container.read(accountsTotalProvider.future);
    expect(total, 6500000);
  });

  test('delete blocked when transactions reference the account', () async {
    final container = _container();
    final controller = container.read(accountsControllerProvider);
    await container.read(transactionRepositoryProvider).addTransaction(
          AppTransaction(
            id: 'trx-acc-4',
            title: 'Top up',
            amount: 100000,
            type: TransactionType.income,
            date: DateTime.now(),
            category: 'Gaji',
            accountId: 'inst-cash',
          ),
        );

    // Riwayat tetap utuh: hapus ditolak.
    expect(await controller.deleteAccount('inst-cash'), isFalse);
    expect((await _accounts(container)).length, 3);

    // Tanpa referensi: hapus berhasil.
    expect(await controller.deleteAccount('inst-jago'), isTrue);
    expect((await _accounts(container)).length, 2);
  });

  test('model has no transfer to miscalculate', () {
    // Tahap 16: tepat tiga jenis akun (Bank, Bank Digital, E-Wallet).
    expect(AccountType.values.length, 3);
    expect(AccountType.values,
        containsAll([AccountType.bank, AccountType.digitalBank, AccountType.ewallet]));
    expect(TransactionType.values.length, 2);
  });
}
