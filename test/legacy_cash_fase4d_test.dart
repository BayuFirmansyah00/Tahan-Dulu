import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/providers/tahandulu_controller.dart';

Widget _buildTestApp({
  required Widget child,
  required List<dynamic> overrides,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
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
  group('Fase 4D: FinancialAccount Model', () {
    test('isLegacyCash dan isSpendable mendeteksi tipe dengan tepat', () {
      const cash = FinancialAccount(
        id: 'acc-cash',
        name: 'Dompet Fisik',
        type: AccountType.legacyCash,
        balance: 500000,
      );
      const bank = FinancialAccount(
        id: 'acc-bank',
        name: 'BCA Utama',
        type: AccountType.bank,
        balance: 2000000,
      );
      const ewallet = FinancialAccount(
        id: 'acc-ewallet',
        name: 'GoPay',
        type: AccountType.ewallet,
        balance: 150000,
      );

      expect(cash.isLegacyCash, isTrue);
      expect(cash.isSpendable, isFalse);

      expect(bank.isLegacyCash, isFalse);
      expect(bank.isSpendable, isTrue);

      expect(ewallet.isLegacyCash, isFalse);
      expect(ewallet.isSpendable, isTrue);
    });
  });

  group('Fase 4D: MockAccountRepository Reconcile Legacy Cash', () {
    test('reconcileLegacyCash memindahkan saldo secara netral tanpa mengubah total aset', () async {
      final onboardingRepo = InMemoryOnboardingRepository();
      await onboardingRepo.saveInstruments([
        const FinancialInstrument(
          id: 'inst-cash',
          name: 'Dompet Tunai',
          type: InstrumentType.cash,
          initialBalance: 500000,
        ),
        const FinancialInstrument(
          id: 'inst-bank',
          name: 'BCA Utama',
          type: InstrumentType.bank,
          initialBalance: 2000000,
        ),
      ]);
      final repo = MockAccountRepository(onboardingRepo);
      final accountsBefore = await repo.getAccounts();
      final totalBefore = await repo.getTotalBalance();

      final cash = accountsBefore.firstWhere((a) => a.type == AccountType.legacyCash);
      final bank = accountsBefore.firstWhere((a) => a.type == AccountType.bank);

      final initialCashBalance = cash.balance;
      final initialBankBalance = bank.balance;
      final transferAmount = 200000.0;

      await repo.reconcileLegacyCash(
        fromId: cash.id,
        toId: bank.id,
        amount: transferAmount,
        notes: 'Setoran tunai ke rekening bank',
      );

      final accountsAfter = await repo.getAccounts();
      final cashAfter = accountsAfter.firstWhere((a) => a.id == cash.id);
      final bankAfter = accountsAfter.firstWhere((a) => a.id == bank.id);
      final totalAfter = await repo.getTotalBalance();

      expect(cashAfter.balance, equals(initialCashBalance - transferAmount));
      expect(bankAfter.balance, equals(initialBankBalance + transferAmount));
      expect(totalAfter, equals(totalBefore)); // Net-zero asset change!
    });
  });

  group('Fase 4D: AccountsScreen Cash Legacy Display', () {
    testWidgets('menampilkan status Uang Tunai — Akun Lama dan badge Akun Lama', (tester) async {
      const cashAcc = FinancialAccount(
        id: 'acc-cash',
        name: 'Dompet Tunai',
        type: AccountType.legacyCash,
        balance: 350000,
      );
      const bankAcc = FinancialAccount(
        id: 'acc-bank',
        name: 'BCA Tabungan',
        type: AccountType.bank,
        balance: 1500000,
      );

      final overviews = [
        const AccountOverview(
          account: cashAcc,
          currentBalance: 350000,
          transactionCount: 2,
        ),
        const AccountOverview(
          account: bankAcc,
          currentBalance: 1500000,
          transactionCount: 5,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: const AccountsScreen(),
          overrides: [
            accountsOverviewProvider.overrideWith((ref) => Future.value(overviews)),
            accountsTotalProvider.overrideWith((ref) => Future.value(1850000.0)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dompet Tunai'), findsOneWidget);
      expect(find.text('Akun Lama'), findsOneWidget);
      expect(find.text('Uang Tunai — Akun Lama'), findsOneWidget);
      expect(
        find.text('Akun ini dipertahankan untuk menjaga saldo dan riwayat pencatatan sebelumnya. Akun Uang Tunai baru tidak lagi didukung.'),
        findsOneWidget,
      );
      expect(find.text('Total Aset Tercatat'), findsOneWidget);
    });
  });

  group('Fase 4D: AccountDetailScreen Cash Legacy', () {
    testWidgets('menyembunyikan tombol Edit dan menampilkan tombol Rekonsiliasi Saldo', (tester) async {
      const cashAcc = FinancialAccount(
        id: 'acc-cash',
        name: 'Dompet Tunai',
        type: AccountType.legacyCash,
        balance: 350000,
      );
      const bankAcc = FinancialAccount(
        id: 'acc-bank',
        name: 'BCA Tabungan',
        type: AccountType.bank,
        balance: 1500000,
      );

      final overviews = [
        const AccountOverview(
          account: cashAcc,
          currentBalance: 350000,
          transactionCount: 2,
        ),
        const AccountOverview(
          account: bankAcc,
          currentBalance: 1500000,
          transactionCount: 5,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: const AccountDetailScreen(accountId: 'acc-cash'),
          overrides: [
            accountsOverviewProvider.overrideWith((ref) => Future.value(overviews)),
            transactionsProvider.overrideWith((ref) => Future.value(<AppTransaction>[])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Rekonsiliasi Saldo button harus muncul
      expect(find.text('Rekonsiliasi Saldo ke Rekening'), findsOneWidget);
      // Tombol transfer reguler dan edit reguler tidak boleh muncul
      expect(find.text('Transfer Saldo'), findsNothing);
      expect(find.text('Ubah Akun'), findsNothing);
    });
  });

  group('Fase 4D: PurchaseAnalysis & Wishlist', () {
    test('PurchaseAnalysis memisahkan total assets dan spendable balance', () {
      final item = PurchaseConsideration(
        id: 'w-1',
        itemName: 'Sepatu Running',
        price: 500000,
        status: ConsiderationStatus.wishlist,
        createdAt: DateTime.now(),
      );

      final analysis = PurchaseAnalysis(
        item: item,
        flexible: 600000,
        safeDaily: 50000,
        share: 0.25,
        delayDays: 5,
        goalName: 'Dana Liburan',
        goalCurrent: 2000000,
        monthlyContribution: 500000,
        totalLiquidBalance: 800000,
        spendableBalance: 300000,
        cashLegacyBalance: 500000,
        hasCashLegacy: true,
        hasAccounts: true,
        budgetSufficient: true,
        balanceSufficient: false, // spendable (300k) < price (500k) meskipun total (800k) >= price
        recommendation: 'consider',
        recommendationTitle: 'Saldo Berada di Akun Uang Tunai (Lama)',
        recommendationReason: 'Saldo siap pakai tidak mencukupi, berada di uang tunai lama.',
      );

      expect(analysis.totalLiquidBalance, equals(800000));
      expect(analysis.spendableBalance, equals(300000));
      expect(analysis.cashLegacyBalance, equals(500000));
      expect(analysis.hasCashLegacy, isTrue);
      expect(analysis.balanceSufficient, isFalse);
    });
  });
}
