import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/features/goals/presentation/utils/goal_category_ui.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/expenses_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/goals_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/instruments_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/plan_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/salary_screen.dart';

/// Semua aset lokal yang dipakai lima screen onboarding (Tahap 30).
const _onboardingAssets = [
  // Salary.
  AppAssets.incomeSetupIllustration,
  AppAssets.obSalaryWallet,
  // Instrumen.
  AppAssets.obBank,
  AppAssets.obDigitalBank,
  AppAssets.obEWallet,
  // Pengeluaran.
  AppAssets.obNeeds,
  AppAssets.obTransport,
  AppAssets.obBills,
  AppAssets.obShopping,
  // Tujuan.
  AppAssets.obEmergency,
  AppAssets.obGoalSavings,
  AppAssets.obInvestment,
  AppAssets.obHouse,
  AppAssets.obEducation,
  AppAssets.obHoliday,
  // Ringkasan.
  AppAssets.successIllustration,
  AppAssets.obAllocFlexible,
];

Finder _assetImage(String asset) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == asset,
    );

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Tahap 30: file aset onboarding benar-benar ada di disk', () {
    for (final asset in _onboardingAssets) {
      test('$asset ada', () {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      });
    }
  });

  group('Tahap 30: pemetaan aset tujuan', () {
    test('enam kategori punya aset lokal', () {
      expect(goalOnboardingAssetFor(GoalCategory.emergency),
          AppAssets.obEmergency);
      expect(goalOnboardingAssetFor(GoalCategory.savings),
          AppAssets.obGoalSavings);
      expect(goalOnboardingAssetFor(GoalCategory.investment),
          AppAssets.obInvestment);
      expect(
          goalOnboardingAssetFor(GoalCategory.house), AppAssets.obHouse);
      expect(goalOnboardingAssetFor(GoalCategory.education),
          AppAssets.obEducation);
      expect(goalOnboardingAssetFor(GoalCategory.holiday),
          AppAssets.obHoliday);
    });

    test('kendaraan, gadget, lainnya memakai fallback (null)', () {
      expect(goalOnboardingAssetFor(GoalCategory.vehicle), isNull);
      expect(goalOnboardingAssetFor(GoalCategory.gadget), isNull);
      expect(goalOnboardingAssetFor(GoalCategory.others), isNull);
    });
  });

  group('Tahap 30: spesifikasi visual aset onboarding', () {
    testWidgets('salary: ilustrasi 170 contain + dompet 30x30 contain',
        (tester) async {
      await _pumpScreen(tester, const SalaryScreen());

      final illustration =
          tester.widget<Image>(_assetImage(AppAssets.incomeSetupIllustration));
      expect(illustration.height, 170);
      expect(illustration.fit, BoxFit.contain);

      final wallet =
          tester.widget<Image>(_assetImage(AppAssets.obSalaryWallet));
      expect(wallet.width, 30);
      expect(wallet.height, 30);
      expect(wallet.fit, BoxFit.contain);
      expect(tester.takeException(), isNull);
    });

    testWidgets('instrumen: tiga ikon 48x48 contain', (tester) async {
      await _pumpScreen(tester, const InstrumentsScreen());
      for (final asset in [
        AppAssets.obBank,
        AppAssets.obDigitalBank,
        AppAssets.obEWallet,
      ]) {
        await tester.ensureVisible(_assetImage(asset));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(_assetImage(asset));
        expect(image.width, 48, reason: asset);
        expect(image.height, 48, reason: asset);
        expect(image.fit, BoxFit.contain, reason: asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('pengeluaran: empat ikon 48x48 contain', (tester) async {
      await _pumpScreen(tester, const ExpensesScreen());
      for (final asset in [
        AppAssets.obNeeds,
        AppAssets.obTransport,
        AppAssets.obBills,
        AppAssets.obShopping,
      ]) {
        await tester.ensureVisible(_assetImage(asset));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(_assetImage(asset));
        expect(image.width, 48, reason: asset);
        expect(image.height, 48, reason: asset);
        expect(image.fit, BoxFit.contain, reason: asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('tujuan: enam ikon chip 22x22 contain', (tester) async {
      await _pumpScreen(tester, const GoalsScreen());
      for (final asset in [
        AppAssets.obEmergency,
        AppAssets.obGoalSavings,
        AppAssets.obInvestment,
        AppAssets.obHouse,
        AppAssets.obEducation,
        AppAssets.obHoliday,
      ]) {
        await tester.ensureVisible(_assetImage(asset));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(_assetImage(asset));
        expect(image.width, 22, reason: asset);
        expect(image.height, 22, reason: asset);
        expect(image.fit, BoxFit.contain, reason: asset);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ringkasan: ilustrasi 190 contain + alokasi 40x40 contain',
        (tester) async {
      await _pumpScreen(tester, const PlanScreen());

      final hero =
          tester.widget<Image>(_assetImage(AppAssets.successIllustration));
      expect(hero.height, 190);
      expect(hero.fit, BoxFit.contain);

      for (final asset in [
        AppAssets.obNeeds,
        AppAssets.obEmergency,
        AppAssets.obInvestment,
        AppAssets.obAllocFlexible,
      ]) {
        await tester.ensureVisible(_assetImage(asset));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(_assetImage(asset));
        expect(image.width, 40, reason: asset);
        expect(image.height, 40, reason: asset);
        expect(image.fit, BoxFit.contain, reason: asset);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
