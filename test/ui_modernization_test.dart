import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/theme/app_colors.dart';
import 'package:tahan_dulu/core/widgets/app_states.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transactions_screen.dart';

/// Repository yang selalu gagal dibaca (uji error state).
class _FailingTransactionRepo implements TransactionRepository {
  @override
  Future<List<AppTransaction>> getRecentTransactions() =>
      Future.error(StateError('offline'));

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async =>
      transaction;
}

Future<void> _pumpTransactions(
  WidgetTester tester, {
  TransactionRepository? txRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (txRepo != null)
          transactionRepositoryProvider.overrideWithValue(txRepo),
      ],
      child: const MaterialApp(home: TransactionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 20: komponen state generik', () {
    testWidgets('AppErrorState tampil + retry memanggil balik', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(onRetry: () => retried++),
          ),
        ),
      );

      expect(find.text(AppStrings.loadFailed), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      expect(retried, 1);
    });

    testWidgets('tanpa retry tidak ada tombol', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorState()),
        ),
      );
      expect(find.text(AppStrings.retry), findsNothing);
    });

    testWidgets('riwayat gagal tampil error + retry pulih', (tester) async {
      await _pumpTransactions(
        tester,
        txRepo: _FailingTransactionRepo(),
      );

      expect(find.text(AppStrings.loadFailed), findsOneWidget);
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();
      // Repo tetap gagal: state error bertahan tanpa crash.
      expect(find.text(AppStrings.loadFailed), findsOneWidget);
    });
  });

  group('Tahap 20: pencarian transaksi', () {
    testWidgets('query menyaring judul', (tester) async {
      await _pumpTransactions(tester);

      await tester.enterText(
        find.byType(TextField),
        'gaji',
      );
      await tester.pumpAndSettle();
      expect(find.text('Gaji Bulanan'), findsOneWidget);
      expect(find.text('Belanja Bulanan'), findsNothing);
    });

    testWidgets('tombol hapus mengembalikan daftar', (tester) async {
      await _pumpTransactions(tester);

      await tester.enterText(find.byType(TextField), 'gaji');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Gaji Bulanan'), findsOneWidget);
      expect(find.text('Belanja Bulanan'), findsOneWidget);
    });

    testWidgets('query kombinasi dengan filter jenis', (tester) async {
      await _pumpTransactions(tester);

      await tester.tap(find.text(AppStrings.filterExpense).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'belanja');
      await tester.pumpAndSettle();
      expect(find.text('Belanja Bulanan'), findsOneWidget);
      expect(find.text('Gaji Bulanan'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz-tanpa-hasil');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.searchEmptyTitle), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });
  });

  group('Tahap 20: layar kecil & teks besar', () {
    testWidgets('dashboard 360px tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    });

    testWidgets('ringkasan memakai warna semantik', (tester) async {      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final nominals = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => (t.data ?? '').startsWith('Rp'))
          .toList();
      expect(
        nominals.any((t) => t.style?.color == AppColors.error),
        isTrue,
      );
      expect(
        nominals.any((t) => t.style?.color == AppColors.primary),
        isTrue,
      );
    });

    testWidgets('transaksi terbaru dari provider tampil', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.recentTransactionsTitle), findsOneWidget);
      expect(find.text('Gaji Bulanan'), findsWidgets);
    });

    testWidgets('riwayat 360px tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpTransactions(tester);
      expect(find.text(AppStrings.transactionsTitle), findsWidgets);
    });

    testWidgets('riwayat skala teks 1.4 tanpa overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
      );

      await _pumpTransactions(tester);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.transactionsTitle), findsWidgets);
    });
  });
}
