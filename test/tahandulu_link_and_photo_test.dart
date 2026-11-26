import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/tahandulu/data/services/product_ocr_service.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/providers/tahandulu_controller.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_add_screen.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/screens/tahandulu_form_screen.dart';

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
    required String accountId,
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
  group('Tahan Dulu Upload Foto Tests', () {
    late _FakePurchaseDecisionRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakePurchaseDecisionRepository();
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

    test('OCR-01: NativeProductOcrService.parseProductText mengenali teks screenshot Shopee', () {
      const mockRawText = '''
Shopee Mall
Earphone TWS Bluetooth 5.3 Waterproof
Rp 189.000
Rp 350.000
Beli Sekarang
Gratis Ongkir
''';
      final result = NativeProductOcrService.parseProductText(mockRawText);
      expect(result.hasDetectedInfo, isTrue);
      expect(result.marketplace, 'Shopee');
      expect(result.itemName, 'Earphone TWS Bluetooth 5.3 Waterproof');
      expect(result.price, 350000.0);
    });

    test('OCR-02: NativeProductOcrService.parseProductText mengenali Tokopedia dan membersihkan tombol UI', () {
      const mockRawText = '''
Tokopedia Official
Tas Ransel Laptop Anti Air USB Charger
Chat Penjual
Tambah ke Keranjang
Rp 275.000
Ulasan (4.9)
''';
      final result = NativeProductOcrService.parseProductText(mockRawText);
      expect(result.hasDetectedInfo, isTrue);
      expect(result.marketplace, 'Tokopedia');
      expect(result.itemName, 'Tas Ransel Laptop Anti Air USB Charger');
      expect(result.price, 275000.0);
    });

    test('OCR-03: NativeProductOcrService.parseProductText pada foto fisik tanpa harga tidak menebak harga', () {
      const mockRawText = '''
PHOTO_DSC_001
MADE IN INDONESIA
''';
      final result = NativeProductOcrService.parseProductText(mockRawText);
      expect(result.price, isNull);
      expect(result.marketplace, isNull);
    });

    for (final width in [360.0, 393.0, 412.0]) {
      testWidgets('RESPONSIVE: TahanDuluAddScreen responsif pada lebar ${width}dp', (tester) async {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _buildTestApp(
            child: const TahanDuluAddScreen(),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.addItemTitle), findsOneWidget);
        expect(find.text(AppStrings.methodManual), findsOneWidget);
        expect(find.text(AppStrings.methodPhoto), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
