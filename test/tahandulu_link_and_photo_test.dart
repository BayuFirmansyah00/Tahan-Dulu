import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/providers/tahandulu_controller.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_form_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_link_screen.dart';

class _FakePurchaseDecisionRepository implements PurchaseDecisionRepository {
  final List<PurchaseConsideration> _items = [];
  Map<String, dynamic>? mockMetadata;
  String mockUploadedImageRef = 'wishlists/test/uploaded_image.jpg';
  bool extractMetadataCalled = false;
  bool uploadImageCalled = false;

  @override
  Future<List<PurchaseConsideration>> getConsiderations() async => List.of(_items);

  @override
  Future<PurchaseConsideration> addConsideration(PurchaseConsideration item) async {
    _items.add(item);
    return item;
  }

  @override
  Future<PurchaseConsideration> updateConsideration(PurchaseConsideration item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) _items[idx] = item;
    return item;
  }

  @override
  Future<void> deleteConsideration(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<Map<String, dynamic>> extractMetadata(String url) async {
    extractMetadataCalled = true;
    return mockMetadata ?? {
      'title': 'Mechanical Keyboard RGB',
      'price': 450000.0,
      'image_url': 'https://images.unsplash.com/photo-keyboard',
      'original_url': url,
      'extracted': true,
    };
  }

  @override
  Future<String> uploadImage(String filePath) async {
    uploadImageCalled = true;
    return mockUploadedImageRef;
  }

  @override
  Future<Map<String, dynamic>> getPurchaseAnalysis(String id) async {
    return {
      'flexible_budget': 1500000.0,
      'remaining_pengeluaran_bebas': 1500000.0,
      'safe_daily_spending': 50000.0,
      'today_remaining': 50000.0,
      'has_accounts': true,
      'accounts_count': 1,
      'total_liquid_balance': 3000000.0,
      'budget_sufficient': true,
      'balance_sufficient': true,
      'is_bridge_mode': false,
      'recommendation': 'ready',
      'recommendation_title': 'Kondisi Finansial Mendukung',
      'recommendation_reason': 'Budget dan saldo mencukupi.',
    };
  }

  @override
  Future<Map<String, dynamic>> recordPurchase(
    String id, {
    required int accountId,
    String? information,
    String? idempotencyKey,
  }) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(status: ConsiderationStatus.bought);
    }
    return {'success': true};
  }

  @override
  void clear() {
    _items.clear();
  }
}

Widget _buildTestApp({
  required Widget child,
  required PurchaseDecisionRepository repository,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: AppRoutes.tahanDuluForm,
        builder: (context, state) => const TahanDuluFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.tahanDuluLink,
        builder: (context, state) => const TahanDuluLinkScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tahanDulu}/:id',
        builder: (context, state) => Scaffold(
          body: Text('Analysis Screen for ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      purchaseDecisionRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('Tahan Dulu Link Produk & Upload Foto Tests', () {
    late _FakePurchaseDecisionRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakePurchaseDecisionRepository();
    });

    testWidgets('LINK-01: Metadata tersedia -> prefill otomatis ke form screen', (
      tester,
    ) async {
      fakeRepo.mockMetadata = {
        'title': 'Sepatu Sneakers Running Pro',
        'price': 350000.0,
        'image_url': 'https://example.com/shoes.jpg',
        'original_url': 'https://tokopedia.com/product/shoes',
        'extracted': true,
      };

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluLinkScreen(),
          repository: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Masukkan URL produk
      final urlField = find.byType(TextField);
      expect(urlField, findsOneWidget);
      await tester.enterText(urlField, 'https://tokopedia.com/product/shoes');
      await tester.pumpAndSettle();

      // Tap Lanjutkan
      final continueButton = find.text(AppStrings.continueAction);
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Harus berpindah ke form screen dan metadata terisi
      expect(fakeRepo.extractMetadataCalled, isTrue);
      expect(find.text(AppStrings.addItemTitle), findsOneWidget);
      expect(find.text('Sepatu Sneakers Running Pro'), findsOneWidget);
      expect(find.text('350.000'), findsOneWidget);
      expect(find.text('https://tokopedia.com/product/shoes'), findsOneWidget);
    });

    testWidgets('LINK-02: Metadata gagal -> fallback manual dengan URL tetap terisi', (
      tester,
    ) async {
      fakeRepo.mockMetadata = {
        'title': null,
        'price': null,
        'image_url': null,
        'original_url': 'https://shopee.co.id/unknown-product',
        'extracted': false,
      };

      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluLinkScreen(),
          repository: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final urlField = find.byType(TextField);
      await tester.enterText(urlField, 'https://shopee.co.id/unknown-product');
      await tester.pumpAndSettle();

      final continueButton = find.text(AppStrings.continueAction);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Halaman form tetap terbuka (tidak buntu) dan URL tetap tersimpan
      expect(find.text(AppStrings.addItemTitle), findsOneWidget);
      expect(find.text('https://shopee.co.id/unknown-product'), findsOneWidget);
      // Nama dan harga kosong siap diisi manual oleh user
      expect(find.text(AppStrings.productNameHint), findsOneWidget);
    });

    testWidgets('LINK-03: Validasi URL tidak valid mencegah navigasi', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const TahanDuluLinkScreen(),
          repository: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final urlField = find.byType(TextField);
      await tester.enterText(urlField, 'bukan-url-valid');
      await tester.pumpAndSettle();

      final continueButton = find.text(AppStrings.continueAction);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Muncul pesan error dan tetap di layar link
      expect(find.text(AppStrings.productUrlInvalid), findsOneWidget);
      expect(find.text('Tempel link produk'), findsOneWidget);
    });

    testWidgets('PHOTO-01: Form menampilkan preview foto dan memungkinkan ganti/hapus', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      // Inisialisasi draft dengan foto remote
      container.read(tahanDuluControllerProvider.notifier).prefillDraft(
        itemName: 'Kamera DSLR Canon',
        price: 8500000,
        imageRef: 'https://example.com/camera.jpg',
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TahanDuluFormScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.tahanDulu}/:id',
            builder: (context, state) => Scaffold(
              body: Text('Analysis Screen for ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tombol edit & hapus foto muncul
      expect(find.byTooltip('Ganti Foto'), findsOneWidget);
      expect(find.byTooltip('Hapus Foto'), findsOneWidget);

      // Tap hapus foto
      await tester.tap(find.byTooltip('Hapus Foto'));
      await tester.pumpAndSettle();

      // Sekarang tombol "Tambah Foto Produk (Opsional)" muncul
      expect(find.text('Tambah Foto Produk (Opsional)'), findsOneWidget);
      expect(container.read(tahanDuluControllerProvider).imageRef, isNull);
    });

    testWidgets('FLOW-01: Simpan draf dari Form berhasil dan mengarah ke Analisis', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          purchaseDecisionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      container.read(tahanDuluControllerProvider.notifier).prefillDraft(
        itemName: 'Smart Watch Series 9',
        price: 6500000,
        category: ProductCategory.electronics,
        productUrl: 'https://apple.com/watch',
        imageRef: 'https://example.com/watch.jpg',
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TahanDuluFormScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.tahanDulu}/:id',
            builder: (context, state) => Scaffold(
              body: Text('Analysis Screen for ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll ke tombol analisis
      final analyzeButton = find.text(AppStrings.analyzeAction);
      await tester.ensureVisible(analyzeButton);
      await tester.pumpAndSettle();

      await tester.tap(analyzeButton);
      await tester.pumpAndSettle();

      // Verifikasi berhasil disimpan di repository dan pindah ke Analysis Screen
      final items = await fakeRepo.getConsiderations();
      expect(items.length, 1);
      expect(items.first.itemName, 'Smart Watch Series 9');
      expect(items.first.price, 6500000);
      expect(items.first.imageRef, 'https://example.com/watch.jpg');
      expect(find.textContaining('Analysis Screen for'), findsOneWidget);
    });
  });
}
