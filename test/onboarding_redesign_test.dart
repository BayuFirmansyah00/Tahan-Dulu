import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/data/models/financial_plan.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/budget_screen.dart';
import 'package:tahan_dulu/features/onboarding/presentation/screens/plan_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget buildTestWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
    Size screenSize = const Size(390, 844),
    dynamic overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides is List ? overrides.cast() : const [],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: child,
        ),
      ),
    );
  }

  group('Halaman 1: Atur Anggaran Bulanan (BudgetScreen)', () {
    testWidgets('Merender seluruh elemen UI, 3D icons, dan 4 kartu alokasi', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const BudgetScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header & Progress
      expect(find.text('3 dari 5'), findsOneWidget);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
      expect(
        find.text(
          'Bagi penghasilanmu ke dalam 4 pos alokasi keuangan sesuai rekomendasi TahanDulu.',
        ),
        findsOneWidget,
      );

      // Kartu Penghasilan Utama
      expect(find.text('Penghasilan Utama Bulanan'), findsOneWidget);
      expect(find.byTooltip(''), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssets.ob3dWallet,
        ),
        findsOneWidget,
      );

      // 4 Kartu Kategori
      expect(find.text('Kebutuhan Pokok'), findsOneWidget);
      expect(find.text('Pengeluaran Bebas'), findsOneWidget);
      expect(find.text('Investasi dan Tabungan'), findsOneWidget);
      expect(find.text('Dana Darurat'), findsOneWidget);

      // Badge Persentase Awal (50, 5, 30, 15)
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);

      // 4 Sliders
      expect(find.byType(Slider), findsNWidgets(4));

      // Total Alokasi
      expect(find.text('Total Alokasi'), findsOneWidget);
      expect(find.text('100% / 100%'), findsOneWidget);

      // Reset Button
      expect(find.text('Reset ke Rekomendasi (50/5/30/15)'), findsOneWidget);

      // Sticky Bottom Button
      expect(find.text('Lanjut →'), findsOneWidget);
    });

    testWidgets('Responsif pada layar kecil (320px) tanpa overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const BudgetScreen(),
          screenSize: const Size(320, 600),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
      expect(find.text('Lanjut →'), findsOneWidget);
    });

    testWidgets('Merender pada Dark Mode tanpa error kontras atau exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const BudgetScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
    });

    testWidgets('Interaksi reset ke rekomendasi mengembalikan nilai 50/5/30/15', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const BudgetScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final resetButton = find.text('Reset ke Rekomendasi (50/5/30/15)');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('100% / 100%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('Halaman 2: Ringkasan Rencana Keuangan (PlanScreen)', () {
    final mockPlan = FinancialPlan.fromOnboarding(
      monthlyIncome: 5000000,
      salaryDay: 25,
      kebutuhanPokokPercent: 50.0,
      pengeluaranBebasPercent: 5.0,
      investasiTabunganPercent: 30.0,
      danaDaruratPercent: 15.0,
      recurringExpensesTotal: 800000,
      goalName: 'Dana Darurat',
      goalMonthlyContribution: 2142857,
      goalTargetAmount: 15000000,
    );

    testWidgets('Merender seluruh kartu, nominal dinamis, dan 3D icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            financialPlanProvider.overrideWithValue(mockPlan),
          ],
          child: const PlanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kartu Pemasukan Bulanan
      expect(find.text('Pemasukan Bulanan'), findsOneWidget);
      expect(find.text('Rp5.000.000'), findsOneWidget);

      // Section Alokasi Bulanan
      expect(find.text('Alokasi Bulanan'), findsOneWidget);
      expect(find.text('Kebutuhan'), findsOneWidget);
      expect(find.text('Pengeluaran Fleksibel'), findsOneWidget);
      expect(find.text('Investasi & Tabungan'), findsOneWidget);
      expect(find.text('Dana Darurat'), findsOneWidget);

      // Nominal alokasi
      expect(find.text('Rp2.500.000'), findsOneWidget);
      expect(find.text('Rp250.000'), findsOneWidget);
      expect(find.text('Rp1.500.000'), findsOneWidget);
      expect(find.text('Rp750.000'), findsOneWidget);

      // Kartu Batas Belanja Harian
      expect(find.text('Batas Belanja Harian'), findsOneWidget);
      expect(find.textContaining('Perkiraan budget belanja'), findsOneWidget);

      // Kartu Target Dana Darurat & Komitmen Pengeluaran Rutin
      expect(find.text('Target Dana Darurat'), findsOneWidget);
      expect(find.text('Komitmen Pengeluaran Rutin'), findsOneWidget);
      expect(find.text('Rp800.000 / bulan'), findsOneWidget);
      expect(
        find.text('Dicatat terpisah dari alokasi anggaran bulanan.'),
        findsOneWidget,
      );

      // Informasi Tambahan
      expect(
        find.text('Rencana ini dapat disesuaikan kapan saja.'),
        findsOneWidget,
      );

      // Tombol CTA Final
      expect(find.text('Mulai gunakan aplikasi →'), findsOneWidget);
    });

    testWidgets('Responsif pada layar kecil (320px) tanpa overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            financialPlanProvider.overrideWithValue(mockPlan),
          ],
          child: const PlanScreen(),
          screenSize: const Size(320, 600),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pemasukan Bulanan'), findsOneWidget);
      expect(find.text('Mulai gunakan aplikasi →'), findsOneWidget);
    });

    testWidgets('Merender pada Dark Mode tanpa error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            financialPlanProvider.overrideWithValue(mockPlan),
          ],
          child: const PlanScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pemasukan Bulanan'), findsOneWidget);
    });
  });
}
