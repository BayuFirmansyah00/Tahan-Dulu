import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/add_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/edit_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/utils/account_ui.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 16: tepat tiga jenis akun', () {
    test('enum hanya Bank, Bank Digital, E-Wallet', () {
      expect(AccountType.values.length, 3);
      expect(
        AccountType.values,
        containsAll(
            [AccountType.bank, AccountType.digitalBank, AccountType.ewallet]),
      );
      expect(InstrumentType.values.length, 3);
      expect(
        InstrumentType.values,
        containsAll([
          InstrumentType.bank,
          InstrumentType.digitalBank,
          InstrumentType.ewallet,
        ]),
      );
      for (final t in [...AccountType.values, ...InstrumentType.values]) {
        expect(t.name, isNot(anyOf('cash', 'investment', 'lainnya')));
      }
    });

    test('visual tiap jenis berbeda dan tanpa emoji', () {
      final bank = accountVisual(AccountType.bank);
      final digital = accountVisual(AccountType.digitalBank);
      final ewallet = accountVisual(AccountType.ewallet);
      expect(bank.icon, Icons.account_balance_outlined);
      expect(digital.icon, Icons.smartphone_outlined);
      expect(ewallet.icon, Icons.account_balance_wallet_outlined);
      expect(accountTypeLabel(AccountType.digitalBank), 'Bank Digital');
    });

    test('seed memakai tiga jenis, ID dan saldo tetap', () async {
      final accounts = await _container()
          .read(accountRepositoryProvider)
          .getAccounts();
      expect(accounts.map((e) => e.id),
          ['inst-bca', 'inst-jago', 'inst-cash']);
      expect(accounts.map((e) => e.type),
          [AccountType.bank, AccountType.digitalBank, AccountType.ewallet]);
      // 5.000.000 + 1.000.000 + 500.000, sekali hitung.
      final overviews =
          await _container().read(accountsOverviewProvider.future);
      final total = await _container().read(accountsTotalProvider.future);
      expect(total, 6500000);
      expect(
        total,
        overviews.fold<double>(0, (s, e) => s + e.currentBalance),
      );
    });

    test('tambah akun tiap jenis + institusi manual', () async {
      final container = _container();
      final controller = container.read(accountsControllerProvider);
      for (final (type, name, institution) in [
        (AccountType.bank, 'BRI', 'Bank Rakyat Indonesia'),
        (AccountType.digitalBank, 'neobank', 'Neo Commerce'),
        (AccountType.ewallet, 'GoPay', 'Gojek'),
      ]) {
        expect(
          await controller.addAccount(
            name: name,
            type: type,
            initialBalance: 100000,
            institutionName: institution,
          ),
          isTrue,
        );
      }
      final accounts =
          await container.read(accountRepositoryProvider).getAccounts();
      expect(accounts.length, 3 + 3);
      expect(accounts.last.institutionName, 'Gojek');
    });

    test('edit ganti jenis tanpa kehilangan field lain', () async {
      final container = _container();
      final controller = container.read(accountsControllerProvider);
      expect(
        await controller.updateAccount(
          id: 'inst-jago',
          name: 'Bank Jago',
          type: AccountType.bank,
          initialBalance: 1000000,
          institutionName: 'Bank Jago',
        ),
        isTrue,
      );
      final updated = (await container
              .read(accountRepositoryProvider)
              .getAccounts())
          .firstWhere((e) => e.id == 'inst-jago');
      expect(updated.type, AccountType.bank);
      expect(updated.name, 'Bank Jago');
      expect(updated.balance, 1000000);
    });

    test('dashboard konsisten memakai tiga jenis', () async {
      final data = await _container().read(dashboardDataProvider.future);
      expect(data.totalBalance, 6500000);
    });

    test('target Investasi dan setoran tidak tersentuh', () async {
      final container = _container();
      expect(GoalCategory.values, contains(GoalCategory.investment));
      final ok = await container.read(goalRepositoryProvider).addDeposit(
            GoalDeposit(
              id: 'dep-16',
              goalId: 'goal-investment',
              amount: 500000,
              date: DateTime.now(),
            ),
          );
      expect(ok.amount, 500000);
      final goals = await container.read(goalRepositoryProvider).getGoals();
      final goal = goals.firstWhere((e) => e.id == 'goal-investment');
      expect(goal.category, GoalCategory.investment);
      expect(goal.currentAmount, 3500000 + 500000);
    });
  });

  group('Tahap 16: UI hanya tiga pilihan', () {
    testWidgets('dialog onboarding tanpa Tunai/Investasi', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InstrumentsScreen())),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.addInstrument));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Pilih instrumen...'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.typeBank), findsOneWidget);
      expect(find.text(AppStrings.typeDigitalBank), findsOneWidget);
      expect(find.text(AppStrings.typeEWallet), findsOneWidget);
      expect(find.text('Tunai'), findsNothing);
      expect(find.text('Investasi'), findsNothing);
    });

    testWidgets('dropdown tambah akun memuat tipe instrumen master', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AddAccountScreen())),
      );
      await tester.pumpAndSettle();

      // Tipe instrumen dimuat dari data master (dropdown, bukan grid kartu).
      await _tapVisible(tester, find.byType(DropdownButtonFormField<int>));
      expect(find.text(AppStrings.typeBank), findsOneWidget);
      expect(find.text(AppStrings.typeDigitalBank), findsOneWidget);
      expect(find.text(AppStrings.typeEWallet), findsOneWidget);
      expect(find.text('Tunai'), findsNothing);
      // Pilih Bank Digital + institusi manual.
      await _tapVisible(tester, find.text(AppStrings.typeDigitalBank));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'SeaBank');
      await tester.enterText(fields.at(1), 'SeaBank Indonesia');
      await tester.enterText(fields.at(2), '200000');
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.saveAccount),
      );
      expect(find.text(AppStrings.addAccountTitle), findsNothing);
    });

    testWidgets('daftar akun menampilkan label jenis baru', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AccountsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bank Digital'), findsWidgets);
      expect(find.text('E-Wallet'), findsWidgets);
      expect(find.text('Rp6.500.000'), findsOneWidget);
    });

    testWidgets('dropdown edit akun berisi tiga jenis', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
            child: MaterialApp(
                home: EditAccountScreen(accountId: 'inst-jago'))),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
          tester, find.byType(DropdownButtonFormField<AccountType>));
      expect(find.text(AppStrings.typeBank), findsWidgets);
      expect(find.text(AppStrings.typeDigitalBank), findsWidgets);
      expect(find.text(AppStrings.typeEWallet), findsWidgets);
    });

    testWidgets('dropdown transaksi bernama + institusi/jenis', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
            child: MaterialApp(home: TransactionFormScreen())),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
          tester, find.byType(DropdownButtonFormField<String>));
      expect(find.text('BCA — Bank'), findsWidgets);
      expect(find.text('Bank Jago — Bank Digital'), findsWidgets);
      expect(find.text('GoPay — E-Wallet'), findsWidgets);
    });
  });
}
