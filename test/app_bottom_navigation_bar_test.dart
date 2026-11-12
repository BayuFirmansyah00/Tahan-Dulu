import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/widgets/app_bottom_navigation_bar.dart';

Widget _createTestApp({
  int? currentIndex,
  ValueChanged<int>? onTap,
  String initialLocation = '/',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: const Center(child: Text('Home Page')),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) => Scaffold(
          body: const Center(child: Text('Transactions Page')),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.goals,
        builder: (context, state) => Scaffold(
          body: const Center(child: Text('Goals Page')),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => Scaffold(
          body: const Center(child: Text('Settings Page')),
          bottomNavigationBar: AppBottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionRecordMethod,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Record Method Page')),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
  );
}

void main() {
  group('AppBottomNavigationBar Component Tests', () {
    testWidgets('Renders all five menus symmetrically with 3D icons & labels', (
      tester,
    ) async {
      await tester.pumpWidget(_createTestApp(currentIndex: 0));
      await tester.pumpAndSettle();

      // Lima menu tersusun simetris
      expect(find.text(AppStrings.navHome), findsOneWidget); // Beranda
      expect(find.text(AppStrings.navTransactions), findsOneWidget); // Transaksi
      expect(find.text(AppStrings.navRecord), findsOneWidget); // Catat
      expect(find.text(AppStrings.navGoals), findsOneWidget); // Tujuan
      expect(find.text(AppStrings.navProfile), findsOneWidget); // Profil

      // Tombol primary action Catat (+) memiliki key yang kompatibel
      expect(find.byKey(const Key('record_button')), findsOneWidget);
      expect(find.byKey(const Key('record_button_icon')), findsOneWidget);
    });

    testWidgets('Tapping each navigation item triggers callback with correct index', (
      tester,
    ) async {
      int? tappedIndex;

      await tester.pumpWidget(
        _createTestApp(
          currentIndex: 0,
          onTap: (i) => tappedIndex = i,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Transaksi (index 1)
      await tester.tap(find.text(AppStrings.navTransactions));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));

      // Tap Catat (+) (index 2)
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(2));

      // Tap Tujuan (index 3)
      await tester.tap(find.text(AppStrings.navGoals));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(3));

      // Tap Profil (index 4)
      await tester.tap(find.text(AppStrings.navProfile));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(4));

      // Tap Beranda (index 0)
      await tester.tap(find.text(AppStrings.navHome));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(0));
    });

    testWidgets('Auto-resolves active index based on route location when currentIndex is null', (
      tester,
    ) async {
      // 1. Lokasi root / dashboard -> Beranda aktif
      await tester.pumpWidget(_createTestApp(initialLocation: '/'));
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);

      // 2. Navigasi default ke Transaksi
      await tester.tap(find.text(AppStrings.navTransactions));
      await tester.pumpAndSettle();
      expect(find.text('Transactions Page'), findsOneWidget);

      // 3. Navigasi default ke Tujuan
      await tester.tap(find.text(AppStrings.navGoals));
      await tester.pumpAndSettle();
      expect(find.text('Goals Page'), findsOneWidget);

      // 4. Navigasi default ke Profil
      await tester.tap(find.text(AppStrings.navProfile));
      await tester.pumpAndSettle();
      expect(find.text('Settings Page'), findsOneWidget);

      // 5. Navigasi default Catat (+)
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();
      expect(find.text('Record Method Page'), findsOneWidget);
    });

    testWidgets('Helper resolveIndexFromLocation accurately maps paths', (
      tester,
    ) async {
      expect(AppBottomNavigationBar.resolveIndexFromLocation('/'), equals(0));
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation(AppRoutes.dashboard),
        equals(0),
      );
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation(AppRoutes.transactions),
        equals(1),
      );
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation(
          AppRoutes.transactionRecordMethod,
        ),
        equals(2),
      );
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation(AppRoutes.goals),
        equals(3),
      );
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation(AppRoutes.settings),
        equals(4),
      );
      expect(
        AppBottomNavigationBar.resolveIndexFromLocation('/unknown-sub-page'),
        isNull,
      );
    });
  });
}

