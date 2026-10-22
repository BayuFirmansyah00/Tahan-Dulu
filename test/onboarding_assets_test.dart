import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/login_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/expenses_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/goals_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/plan_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/salary_screen.dart';

Finder obAssetImage(String asset) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == asset,
    );

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pumpAndSettle();
}

Future<void> ensureAssetVisible(
  WidgetTester tester,
  String asset,
) async {
  await tester.ensureVisible(obAssetImage(asset));
  await tester.pumpAndSettle();
  expect(obAssetImage(asset), findsOneWidget, reason: asset);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Tahap 30: ikon lokal onboarding', () {
    testWidgets('login memakai ilustrasi utama', (tester) async {
      await pumpScreen(tester, const LoginScreen());
      expect(obAssetImage(AppAssets.loginIllustration), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gaji memakai ilustrasi + ikon dompet', (tester) async {
      await pumpScreen(tester, const SalaryScreen());
      expect(
        obAssetImage(AppAssets.incomeSetupIllustration),
        findsOneWidget,
      );
      expect(obAssetImage(AppAssets.obSalaryWallet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('instrumen memakai tiga ikon tipe', (tester) async {
      await pumpScreen(tester, const InstrumentsScreen());
      for (final asset in [
        AppAssets.obBank,
        AppAssets.obDigitalBank,
        AppAssets.obEWallet,
      ]) {
        await ensureAssetVisible(tester, asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('pengeluaran memakai empat ikon kategori', (tester) async {
      await pumpScreen(tester, const ExpensesScreen());
      for (final asset in [
        AppAssets.obNeeds,
        AppAssets.obTransport,
        AppAssets.obBills,
        AppAssets.obShopping,
      ]) {
        await ensureAssetVisible(tester, asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('tujuan memakai enam ikon kategori', (tester) async {
      await pumpScreen(tester, const GoalsScreen());
      for (final asset in [
        AppAssets.obEmergency,
        AppAssets.obGoalSavings,
        AppAssets.obInvestment,
        AppAssets.obHouse,
        AppAssets.obEducation,
        AppAssets.obHoliday,
      ]) {
        await ensureAssetVisible(tester, asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ringkasan memakai ilustrasi + empat ikon alokasi',
        (tester) async {
      await pumpScreen(tester, const PlanScreen());
      expect(obAssetImage(AppAssets.successIllustration), findsOneWidget);
      // needs & saving & investment & flexible memakai ikon berbeda.
      final found = <String>{
        for (final asset in [
          AppAssets.obNeeds,
          AppAssets.obEmergency,
          AppAssets.obInvestment,
          AppAssets.obAllocFlexible,
        ])
          if (obAssetImage(asset).evaluate().isNotEmpty) asset,
      };
      expect(found.length, 4);
      expect(tester.takeException(), isNull);
    });
  });
}
