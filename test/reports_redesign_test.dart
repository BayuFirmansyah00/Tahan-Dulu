import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_expenses_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_health_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_savings_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/reports_screen.dart';

Finder _assetImage(String asset) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == asset,
);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  // Siram timer mock yang mungkin tersisa agar teardown bersih.
  await tester.pump(const Duration(seconds: 1));
}

/// Transaksi seed agar halaman punya data nyata.
class _SeedTxRepo implements TransactionRepository {
  final List<AppTransaction> items = [
    AppTransaction(
      id: 't1',
      title: 'Gaji',
      type: TransactionType.income,
      amount: 5000000,
      date: DateTime.now(),
      accountId: 'inst-bca',
    ),
    AppTransaction(
      id: 't2',
      title: 'Belanja',
      type: TransactionType.expense,
      amount: 1500000,
      category: 'Kebutuhan',
      date: DateTime.now(),
      accountId: 'inst-bca',
    ),
  ];

  @override
  Future<List<AppTransaction>> getRecentTransactions() async => List.of(items);

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    items.add(transaction);
    return transaction;
  }
}

void main() {
  group('Redesign Reports: aset header terverifikasi', () {
    test('empat header ada di disk', () {
      for (final asset in [
        AppAssets.headerLaporanKeuangan,
        AppAssets.headerPengeluaran,
        AppAssets.headerKesehatanKeuangan,
        AppAssets.headerTabunganInvestasi,
      ]) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });
  });

  group('Redesign Reports: ilustrasi dan ikon tampil', () {
    testWidgets('pengeluaran memakai header + ikon kategori', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(_SeedTxRepo()),
          ],
          child: const MaterialApp(home: ReportExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(_assetImage(AppAssets.headerPengeluaran), findsOneWidget);
      // Kebutuhan dipetakan ke ikon lokal via txIconForLabel.
      expect(_assetImage(AppAssets.txShopping), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kesehatan memakai ilustrasi + ring skor', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(_SeedTxRepo()),
          ],
          child: const MaterialApp(home: ReportHealthScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(_assetImage(AppAssets.headerKesehatanKeuangan), findsOneWidget);
      expect(find.text(AppStrings.healthInsightTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tabungan memakai ikon PNG lokal', (tester) async {
      await _pump(tester, const ReportSavingsScreen());
      expect(_assetImage(AppAssets.txSavings), findsOneWidget);
      expect(_assetImage(AppAssets.txInvestment), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sisa dana emerald menonjol', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(_SeedTxRepo()),
          ],
          child: const MaterialApp(home: ReportsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reportsRemainingLabel), findsOneWidget);
      expect(find.text(AppStrings.reportsVsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Redesign Reports: responsivitas', () {
    testWidgets('tanpa overflow pada lebar 360', (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final screens = <String, Widget>{
        'laporan': const ReportsScreen(),
        'pengeluaran': const ReportExpensesScreen(),
        'kesehatan': const ReportHealthScreen(),
        'tabungan': const ReportSavingsScreen(),
      };
      for (final entry in screens.entries) {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: entry.value)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        await tester.pump(const Duration(seconds: 1));
      }
    });
  });
}
