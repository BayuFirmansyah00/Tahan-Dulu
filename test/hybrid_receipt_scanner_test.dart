import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/features/transactions/data/services/hybrid_receipt_scanner_service.dart';
import 'package:tahan_dulu/features/transactions/data/services/receipt_ocr_service.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/native_input_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';

class _FakeReceiptOcrService implements ReceiptOcrService {
  _FakeReceiptOcrService({this.pickedPath, this.text = ''});

  final String? pickedPath;
  final String text;
  int recognizeCalls = 0;

  @override
  Future<String?> pickImageFromCamera() async => pickedPath;

  @override
  Future<String?> pickImageFromGallery() async => pickedPath;

  @override
  Future<String> recognizeText(String imagePath) async {
    recognizeCalls++;
    return text;
  }

  @override
  Future<void> deleteTempImage(String? imagePath) async {}

  @override
  Future<void> cleanupAllTempImages() async {}

  @override
  void dispose() {}
}

class _FakeHybridScannerService implements HybridReceiptScannerService {
  _FakeHybridScannerService({
    required this.isEnabled,
    this.result,
    this.error,
  });

  @override
  final bool isEnabled;
  final HybridReceiptScanResult? result;
  final Object? error;
  bool? lastAllowVisionFallback;

  @override
  Future<HybridReceiptScanResult> scanReceiptImage(
    String imagePath, {
    bool allowExternalAi = false,
    bool allowVisionFallback = false,
  }) async {
    lastAllowVisionFallback = allowVisionFallback;
    if (error != null) throw error!;
    return result!;
  }
}

Widget _wrapRouter({
  required List<dynamic> overrides,
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: '/scan',
    routes: [
      GoRoute(
        path: '/scan',
        builder: (context, state) => const TransactionScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Form Add Screen')),
        ),
      ),
    ],
  );

  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('HybridReceiptScanner Flutter Integration Tests', () {
    test('HybridReceiptScanResult.fromJson parses full schema accurately', () {
      final result = HybridReceiptScanResult.fromJson({
        'merchant_name': 'WARUNG NASI NUSANTARA',
        'receipt_date': '2026-11-22',
        'receipt_time': '19:40',
        'currency': 'IDR',
        'items': [
          {
            'name': 'AYAM BAKAR MADU',
            'quantity': 2,
            'unit_price': 35000,
            'line_total': 70000,
            'confidence': 0.96,
            'evidence_text': 'AYAM BAKAR MADU 2 x 35.000 70.000',
          },
        ],
        'subtotal': 70000,
        'discount': 5000,
        'tax': 6500,
        'service_charge': 3500,
        'rounding': -100,
        'grand_total': 74900,
        'cash_paid': 100000,
        'change': 25100,
        'payment_method': 'Tunai',
        'suggested_category': 'Makanan',
        'validation_warnings': [
          {
            'code': 'LOW_OCR_CONFIDENCE',
            'severity': 'warning',
            'message': 'Periksa kembali nominal.',
          },
        ],
        'requires_review': true,
        'engine': 'rapidocr_ppocrv5_latin',
        'mean_ocr_confidence': 0.91,
        'source_evidence': {'raw_text': 'WARUNG NASI NUSANTARA'},
      });

      expect(result.merchantName, 'WARUNG NASI NUSANTARA');
      expect(result.receiptDate, DateTime(2026, 11, 22));
      expect(result.grandTotal, 74900);
      expect(result.rounding, -100);
      expect(result.cashPaid, 100000);
      expect(result.change, 25100);
      expect(result.suggestedCategory, 'Makanan');
      expect(result.items.length, 1);
      expect(result.items.first.quantity, 2);
      expect(result.validationWarnings.length, 1);
      expect(result.requiresReview, isTrue);
    });

    testWidgets(
      'Hybrid scanner displays warnings, items, inline edit, and prefills draft without auto-saving',
      (tester) async {
        final fakeOcr = _FakeReceiptOcrService(
          pickedPath: 'C:/fake/receipt_hybrid.jpg',
          text: 'SHOULD NOT RUN',
        );
        final fakeHybrid = _FakeHybridScannerService(
          isEnabled: true,
          result: HybridReceiptScanResult(
            rawText: 'ALFAMART\nROTI 2 x 10.000 20.000\nTOTAL BAYAR 20.000',
            merchantName: 'ALFAMART HYBRID',
            receiptDate: DateTime(2026, 11, 25),
            receiptTime: '14:15',
            items: const [
              HybridReceiptItem(
                name: 'ROTI TAWAR',
                quantity: 2,
                unitPrice: 10000,
                lineTotal: 20000,
              ),
            ],
            subtotal: 20000,
            grandTotal: 20000,
            cashPaid: 50000,
            change: 30000,
            paymentMethod: 'Tunai',
            suggestedCategory: 'Belanja',
            validationWarnings: const [
              ReceiptValidationWarning(
                code: 'TEST_WARN',
                severity: 'warning',
                message: 'Periksa kembali diskon pada struk.',
              ),
            ],
            requiresReview: true,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            receiptOcrServiceProvider.overrideWithValue(fakeOcr),
            hybridReceiptScannerServiceProvider.overrideWithValue(fakeHybrid),
          ],
        );

        await tester.pumpWidget(_wrapRouter(overrides: [], container: container));
        await tester.pumpAndSettle();

        final kamera = find.text('Kamera');
        await tester.ensureVisible(kamera);
        await tester.tap(kamera);
        await tester.pumpAndSettle();

        expect(fakeOcr.recognizeCalls, 0);
        expect(fakeHybrid.lastAllowVisionFallback, isFalse);
        expect(find.text('ALFAMART HYBRID'), findsOneWidget);
        expect(find.text('Periksa kembali diskon pada struk.'), findsOneWidget);
        expect(find.text('Saran Kategori'), findsOneWidget);
        expect(find.text('Belanja'), findsOneWidget);

        // Inline edit merchant & total before confirming
        final editBtn = find.text('Edit');
        await tester.ensureVisible(editBtn);
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Nama Toko / Merchant'),
          'ALFAMART EDITED',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Total Akhir Pembayaran'),
          '25000',
        );
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();

        final confirmBtn = find.text('Gunakan Data Struk di Form');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        final draft = container.read(transactionFormProvider);
        expect(draft.title, 'ALFAMART EDITED');
        expect(draft.amount, 25000.0);
        expect(draft.attachmentPath, 'C:/fake/receipt_hybrid.jpg');
        expect(draft.category, isNull);
        expect(draft.accountId, isNull);
        expect(find.text('Form Add Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Hybrid scanner failure falls back cleanly to on-device ML Kit OCR',
      (tester) async {
        final fakeOcr = _FakeReceiptOcrService(
          pickedPath: 'C:/fake/receipt_fallback.jpg',
          text: TransactionScanScreen.sampleIndomaret,
        );
        final fakeHybrid = _FakeHybridScannerService(
          isEnabled: true,
          error: const HybridScannerUnavailableException('Service 503'),
        );

        await tester.pumpWidget(
          _wrapRouter(
            overrides: [
              receiptOcrServiceProvider.overrideWithValue(fakeOcr),
              hybridReceiptScannerServiceProvider.overrideWithValue(fakeHybrid),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final kamera = find.text('Kamera');
        await tester.ensureVisible(kamera);
        await tester.tap(kamera);
        await tester.pumpAndSettle();

        expect(fakeOcr.recognizeCalls, 1);
        expect(find.text('INDOMARET POINT'), findsOneWidget);
        expect(
          find.textContaining('Menggunakan OCR perangkat sebagai cadangan'),
          findsOneWidget,
        );
      },
    );
  });
}
