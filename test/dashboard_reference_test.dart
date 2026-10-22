import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';

Widget _dummy(String label) => Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );

GoRouter _router({required String initial}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => _dummy('Dummy Transaksi'),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return TransactionFormScreen(
            initialType: type == 'income'
                ? TransactionType.income
                : type == 'expense'
                    ? TransactionType.expense
                    : null,
          );
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => _dummy('Dummy Reports'),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => _dummy('Dummy Goals'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _dummy('Dummy Goal Detail'),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => _dummy('Dummy Accounts'),
      ),
      GoRoute(
        path: '/tahan-dulu',
        builder: (context, state) => _dummy('Dummy TahanDulu'),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => _dummy('Dummy Notifikasi'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _dummy('Dummy Settings'),
      ),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String initial = '/dashboard',
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = _router(initial: initial);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _isAssetImage(Widget w, String asset) {
  if (w is! Image) return false;
  final provider = w.image;
  return provider is AssetImage && provider.assetName == asset;
}

void main() {
  group('Tahap 23: dashboard referensi', () {
    testWidgets('hero memakai ilustrasi + data aktual', (tester) async {
      await _pump(tester);

      expect(find.text(AppStrings.safeTodayTitle), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.safeBudgetHero),
        ),
        findsOneWidget,
      );
      // Nominal & caption dari provider, bukan dummy.
      expect(find.text(AppStrings.remainingBudgetLabel), findsNothing);
      expect(find.textContaining(AppStrings.remainingBudgetLabel),
          findsOneWidget);
    });

    testWidgets('shortcut pemasukan membuka form terpreset', (tester) async {
      final container = await _pump(tester);

      // Label sama dengan ringkasan bulanan; shortcut selalu yang pertama.
      await _tapVisible(tester, find.text(AppStrings.typeIncome).first);
      expect(find.text(AppStrings.amountLabel), findsOneWidget);
      expect(
        container.read(transactionFormProvider).type,
        TransactionType.income,
      );
    });

    testWidgets('shortcut pengeluaran membuka form terpreset', (tester) async {
      final container = await _pump(tester);

      await _tapVisible(tester, find.text(AppStrings.typeExpense).first);
      expect(find.text(AppStrings.amountLabel), findsOneWidget);
      expect(
        container.read(transactionFormProvider).type,
        TransactionType.expense,
      );
    });

    testWidgets('shortcut laporan menuju reports', (tester) async {
      await _pump(tester);

      await _tapVisible(tester, find.text(AppStrings.shortcutReport));
      expect(find.text('Dummy Reports'), findsWidgets);
    });

    testWidgets('tidak ada shortcut transfer palsu', (tester) async {
      await _pump(tester);

      expect(find.text('Transfer'), findsNothing);
    });

    testWidgets('target investasi memakai ilustrasi celengan', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Target Investasi'), findsOneWidget);
      // Kedua seed berkategori investasi -> dua celengan HD.
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.goalPiggy),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('ikon kategori transaksi dan ringkasan 3D', (tester) async {
      await _pump(tester);

      // Gaji -> panah naik, Investasi -> sprout, Kebutuhan -> panah turun.
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.txArrowUp),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.txInvestment),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.txArrowDown),
        ),
        findsWidgets,
      );
      // Shortcut + saldo memakai set HD yang sama.
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.dashWallet),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.dashChart),
        ),
        findsOneWidget,
      );
    });

    testWidgets('banner memakai ilustrasi + hitung aktual', (tester) async {
      await _pump(tester);

      expect(find.text(AppStrings.tahanDuluTitle), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => _isAssetImage(w, AppAssets.tahanDuluBanner),
        ),
        findsOneWidget,
      );
      await _tapVisible(tester, find.text(AppStrings.tahanDuluSee));
      expect(find.text('Dummy TahanDulu'), findsWidgets);
    });

    testWidgets('transaksi terbaru bersubtitle waktu', (tester) async {
      await _pump(tester);

      expect(
        find.text(AppStrings.recentTransactionsTitle),
        findsOneWidget,
      );
      expect(find.textContaining('\u2022'), findsWidgets);
    });
  });
}
