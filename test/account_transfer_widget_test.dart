import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/widgets/app_button.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/transfer_screen.dart';

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(List<FinancialAccount> initial)
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
      bankId: fromAcc.bankId,
      bankSlug: fromAcc.bankSlug,
      bankName: fromAcc.bankName,
      bankLogoUrl: fromAcc.bankLogoUrl,
    );
    accounts[toIdx] = FinancialAccount(
      id: toAcc.id,
      name: toAcc.name,
      type: toAcc.type,
      typeId: toAcc.typeId,
      balance: toAcc.balance + amount,
      institutionName: toAcc.institutionName,
      bankId: toAcc.bankId,
      bankSlug: toAcc.bankSlug,
      bankName: toAcc.bankName,
      bankLogoUrl: toAcc.bankLogoUrl,
    );
  }
}

void main() {
  final initialAccounts = [
    const FinancialAccount(
      id: 'acc-1',
      name: 'BCA Utama',
      type: AccountType.bank,
      balance: 1000000,
      institutionName: 'BCA',
    ),
    const FinancialAccount(
      id: 'acc-2',
      name: 'Bank Jago',
      type: AccountType.digitalBank,
      balance: 500000,
      institutionName: 'Jago',
    ),
  ];

  group('AccountsController Transfer Unit Tests', () {
    test('transfer successfully moves balance without changing total balance', () async {
      final repo = FakeAccountRepository(initialAccounts);
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);

      final totalBefore = await repo.getTotalBalance();
      const transferAmount = 300000.0;

      final result = await controller.transfer(
        fromId: 'acc-1',
        toId: 'acc-2',
        amount: transferAmount,
        notes: 'Uji coba transfer',
      );

      expect(result, isTrue);

      final accountsAfter = await repo.getAccounts();
      final fromAfter = accountsAfter.firstWhere((a) => a.id == 'acc-1');
      final toAfter = accountsAfter.firstWhere((a) => a.id == 'acc-2');

      expect(fromAfter.balance, 700000);
      expect(toAfter.balance, 800000);

      final totalAfter = await repo.getTotalBalance();
      expect(totalAfter, totalBefore, reason: 'Total balance harus net-neutral');
    });

    test('transfer fails when amount exceeds source account balance', () async {
      final repo = FakeAccountRepository(initialAccounts);
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);

      final result = await controller.transfer(
        fromId: 'acc-1',
        toId: 'acc-2',
        amount: 2000000,
      );

      expect(result, isFalse);
    });

    test('transfer fails when source and destination are the same', () async {
      final repo = FakeAccountRepository(initialAccounts);
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);

      final result = await controller.transfer(
        fromId: 'acc-1',
        toId: 'acc-1',
        amount: 50000,
      );

      expect(result, isFalse);
    });

    test('transfer fails when amount is zero or negative', () async {
      final repo = FakeAccountRepository(initialAccounts);
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);

      expect(
        await controller.transfer(
          fromId: 'acc-1',
          toId: 'acc-2',
          amount: 0,
        ),
        isFalse,
      );

      expect(
        await controller.transfer(
          fromId: 'acc-1',
          toId: 'acc-2',
          amount: -50000,
        ),
        isFalse,
      );
    });
  });

  group('TransferScreen Widget Tests', () {
    final sampleOverviews = [
      AccountOverview(
        account: initialAccounts[0],
        currentBalance: 1000000,
        transactionCount: 3,
      ),
      AccountOverview(
        account: initialAccounts[1],
        currentBalance: 500000,
        transactionCount: 2,
      ),
    ];

    testWidgets('renders transfer form with source, destination, and quick chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeAccountRepository(initialAccounts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(repo),
            accountsOverviewProvider.overrideWith((ref) => sampleOverviews),
          ],
          child: const MaterialApp(
            home: TransferScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.transferTitle), findsOneWidget);
      expect(find.text(AppStrings.transferSourceAccount), findsOneWidget);
      expect(find.text(AppStrings.transferDestinationAccount), findsOneWidget);
      expect(find.text(AppStrings.transferAmount), findsOneWidget);
      expect(find.text(AppStrings.transferNotes), findsOneWidget);
      expect(find.text('Simulasi Saldo Setelah Transfer'), findsOneWidget);
      expect(find.text(AppStrings.transferSubmit), findsOneWidget);

      // Quick amount chips
      expect(find.text('50rb'), findsOneWidget);
      expect(find.text('100rb'), findsOneWidget);
      expect(find.text('250rb'), findsOneWidget);
      expect(find.text('500rb'), findsOneWidget);
      expect(find.text('Semua Saldo'), findsOneWidget);
    });

    testWidgets('tapping quick amount chip updates amount and simulation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeAccountRepository(initialAccounts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(repo),
            accountsOverviewProvider.overrideWith((ref) => sampleOverviews),
          ],
          child: const MaterialApp(
            home: TransferScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 100rb chip
      await tester.tap(find.text('100rb'));
      await tester.pumpAndSettle();

      expect(find.text('100.000'), findsOneWidget);

      // Submit button should be enabled
      final submitButton = tester.widget<AppButton>(find.widgetWithText(AppButton, AppStrings.transferSubmit));
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('shows insufficient balance error when entering amount exceeding balance', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeAccountRepository(initialAccounts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(repo),
            accountsOverviewProvider.overrideWith((ref) => sampleOverviews),
          ],
          child: const MaterialApp(
            home: TransferScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '999999999');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.transferInsufficientBalance), findsOneWidget);

      final submitButton = tester.widget<AppButton>(find.widgetWithText(AppButton, AppStrings.transferSubmit));
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('shows warning when user has fewer than 2 accounts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeAccountRepository([initialAccounts[0]]);
      final singleOverview = [sampleOverviews[0]];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(repo),
            accountsOverviewProvider.overrideWith((ref) => singleOverview),
          ],
          child: const MaterialApp(
            home: TransferScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.transferMinAccountsError), findsOneWidget);
      expect(find.text(AppStrings.addAccountTitle), findsOneWidget);
    });
  });
}
