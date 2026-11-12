import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_add_screen.dart';

Widget _createTestApp({required Widget child}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: AppRoutes.tahanDuluForm,
        builder: (context, state) =>
            const Scaffold(body: Text('TahanDulu Form Screen')),
      ),
      GoRoute(
        path: AppRoutes.tahanDuluLink,
        builder: (context, state) =>
            const Scaffold(body: Text('TahanDulu Link Screen')),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('TahanDuluAddScreen UI & Interaction Tests', () {
    testWidgets('Renders redesigned Tambah Barang UI components accurately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TahanDuluAddScreen()),
      );
      await tester.pumpAndSettle();

      // 1. AppBar
      expect(find.text('Tambah Barang'), findsOneWidget);

      // 2. Hero Section
      expect(find.text('Tambah barang impianmu'), findsOneWidget);
      expect(
        find.text(
          'Simpan barang yang ingin dibeli dan lihat dampaknya pada keuanganmu.',
        ),
        findsOneWidget,
      );

      // 3. Pilihan Metode Tambah Barang
      expect(find.text(AppStrings.methodManual), findsOneWidget);
      expect(find.text('Isi detail barang sendiri'), findsOneWidget);

      expect(find.text(AppStrings.methodLink), findsOneWidget);
      expect(
        find.text('Tempel tautan barang dari toko online'),
        findsOneWidget,
      );

      expect(find.text(AppStrings.methodPhoto), findsOneWidget);
      expect(find.text('Tambahkan barang melalui foto'), findsOneWidget);

      // 4. Catatan Informasi
      expect(
        find.text(
          'Tahan Dulu membantu melihat dampak pembelian terhadap kondisi keuanganmu, bukan memberikan saran finansial.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Masukkan manual navigates to Form screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TahanDuluAddScreen()),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.methodManual));
      expect(find.text('TahanDulu Form Screen'), findsOneWidget);
    });

    testWidgets('Tapping Masukkan link produk navigates to Link screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TahanDuluAddScreen()),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.methodLink));
      expect(find.text('TahanDulu Link Screen'), findsOneWidget);
    });

    testWidgets('Tapping Upload foto displays source selection bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TahanDuluAddScreen()),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.methodPhoto));
      expect(find.text('Pilih Sumber Foto'), findsOneWidget);
      expect(find.text('Ambil Foto (Kamera)'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
    });
  });
}
