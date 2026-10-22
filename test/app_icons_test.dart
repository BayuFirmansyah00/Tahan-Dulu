import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/widgets/app_icons.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goals_list_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transactions_screen.dart';

bool _isAsset(Widget w, String asset) {
  if (w is! Image) return false;
  final p = w.image;
  return p is AssetImage && p.assetName == asset;
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp(home: screen)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 25: pemetaan ikon konsisten', () {
    test('semua kategori transaksi punya aset', () {
      for (final c in TransactionCategory.values) {
        if (c == TransactionCategory.others) {
          // Lainnya memakai fallback outline (tidak ada aset generik).
          expect(txIconForCategory(c), isEmpty);
          continue;
        }
        expect(txIconForCategory(c), isNotEmpty, reason: '$c');
      }
      // Bonus memakai kado, bukan panah generik.
      expect(txIconForCategory(TransactionCategory.bonus), AppAssets.txGift);
    });

    test('label warisan dan tak dikenal', () {
      expect(
        txIconForLabel('Makanan', TransactionType.expense),
        AppAssets.txFood,
      );
      expect(
        txIconForLabel('KEBUTUHAN', TransactionType.expense),
        AppAssets.txShopping,
      );
      expect(
        txIconForLabel('Investasi', TransactionType.expense),
        AppAssets.txInvestment,
      );
      expect(
        txIconForLabel('Pemasukan', TransactionType.income),
        AppAssets.txArrowUp,
      );
      expect(
        txIconForLabel('Xyz-tak-ada', TransactionType.expense),
        AppAssets.txArrowDown,
      );
      expect(
        txIconForLabel(null, TransactionType.income),
        AppAssets.txArrowUp,
      );
    });

    test('semua kategori goal dan jenis akun punya aset berbeda', () {
      final goals = {
        for (final c in GoalCategory.values) goalIconForCategory(c),
      };
      expect(goals.length, GoalCategory.values.length);
      expect(
        {for (final t in AccountType.values) accountIconForType(t)}.length,
        AccountType.values.length,
      );
    });

    testWidgets('fallback tampil bila aset kosong', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIconFallback(size: 44)),
        ),
      );
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });
  });

  group('Tahap 25: ikon di layar', () {
    testWidgets('riwayat memakai ikon kategori aktual', (tester) async {
      await _pump(tester, const TransactionsScreen());
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txArrowUp)),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txShopping)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txInvestment)),
        findsOneWidget,
      );
    });

    testWidgets('form memakai ikon kategori + jenis', (tester) async {
      await _pump(tester, const TransactionFormScreen());
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txFood)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txArrowUp)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txArrowDown)),
        findsOneWidget,
      );
    });

    testWidgets('rekening memakai ikon penyedia', (tester) async {
      await _pump(tester, const AccountsScreen());
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txBills)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
            (w) => _isAsset(w, AppAssets.txArrowTransfer)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => _isAsset(w, AppAssets.txWallet)),
        findsOneWidget,
      );
    });

    testWidgets('daftar target memakai ikon kategori', (tester) async {
      await _pump(tester, const GoalsListScreen());
      // Seed Target Investasi memakai ikon paket icons (Tahap 32/39).
      expect(
        find.byWidgetPredicate(
          (w) => _isAsset(w, AppAssets.goalIconInvestment),
        ),
        findsOneWidget,
      );
    });
  });
}
