import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/transactions/data/services/hybrid_receipt_scanner_service.dart';
import 'package:tahan_dulu/features/transactions/data/services/receipt_ocr_service.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/native_input_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';

class _PickerOnlyReceiptService implements ReceiptOcrService {
  _PickerOnlyReceiptService({
    required this.cameraPath,
    required this.galleryPath,
  });

  final String cameraPath;
  final String galleryPath;
  int mlKitCalls = 0;

  @override
  Future<String?> pickImageFromCamera() async => cameraPath;

  @override
  Future<String?> pickImageFromGallery() async => galleryPath;

  @override
  Future<String> recognizeText(String imagePath) async {
    mlKitCalls++;
    return '';
  }

  @override
  Future<void> deleteTempImage(String? imagePath) async {}

  @override
  Future<void> cleanupAllTempImages() async {}

  @override
  void dispose() {}
}

void main() {
  final baseUrl = Platform.environment['E2E_LARAVEL_BASE_URL'];
  final token = Platform.environment['E2E_SANCTUM_TOKEN'];
  final instrumentId = Platform.environment['E2E_INSTRUMENT_ID'];
  final cameraImagePath = Platform.environment['E2E_CAMERA_IMAGE'];
  final galleryImagePath = Platform.environment['E2E_GALLERY_IMAGE'];

  final isConfigured =
      baseUrl != null &&
      baseUrl.isNotEmpty &&
      token != null &&
      token.isNotEmpty &&
      instrumentId != null &&
      instrumentId.isNotEmpty &&
      cameraImagePath != null &&
      galleryImagePath != null;

  testWidgets(
    'Real E2E: Flutter -> Laravel -> Python FastAPI OCR -> Editable Preview -> Transaction + Attachment + Idempotency',
    skip: !isConfigured,
    (tester) async {
      // Allow real HTTP calls inside flutter_test when running live E2E
      HttpOverrides.global = null;

      final client = ApiClient(baseUrl: baseUrl!);
      final tokenStore = MemoryTokenStore();
      await tokenStore.saveToken(token!);

      final realHybrid = RemoteHybridReceiptScannerService(
        client: client,
        tokens: tokenStore,
        enabledOverride: true,
      );
      final realTxRepo = RemoteTransactionRepository(
        client: client,
        tokens: tokenStore,
      );
      final picker = _PickerOnlyReceiptService(
        cameraPath: cameraImagePath!,
        galleryPath: galleryImagePath!,
      );

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(tokenStore),
          hybridReceiptScannerServiceProvider.overrideWithValue(realHybrid),
          receiptOcrServiceProvider.overrideWithValue(picker),
          transactionRepositoryProvider.overrideWithValue(realTxRepo),
          accountsProvider.overrideWith(
            (ref) async => [
              FinancialAccount(
                id: instrumentId!,
                name: 'BCA E2E',
                type: AccountType.bank,
                balance: 2000000,
              ),
            ],
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/scan',
        routes: [
          GoRoute(
            path: '/scan',
            builder: (context, state) => const TransactionScanScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactionAdd,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Form Add Screen'))),
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

      // 1. Test Gallery upload (restaurant receipt with PB1, service, rounding)
      await tester.runAsync(() async {
        final galeriBtn = find.text('Galeri');
        await tester.ensureVisible(galeriBtn);
        await tester.tap(galeriBtn);
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await tester.pumpAndSettle();

      expect(picker.mlKitCalls, 0);
      expect(find.text('WARUNG NASI NUSANTARA'), findsOneWidget);
      expect(find.text('Rp 124.700'), findsWidgets);

      // 2. Test Camera upload (minimarket perspective receipt) + inline edit + transaction save
      await tester.runAsync(() async {
        final camBtn = find.text('Kamera');
        await tester.ensureVisible(camBtn);
        await tester.tap(camBtn);
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await tester.pumpAndSettle();

      expect(find.text('ALFAMART SUDIRMAN 12'), findsOneWidget);
      expect(find.text('Rp 30.000'), findsWidgets);

      // Editable preview before confirmation
      final editBtn = find.text('Edit');
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Toko / Merchant'),
        'ALFAMART SUDIRMAN 12 VERIFIED',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Gunakan Data Struk di Form');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify prefill without auto-creating transaction
      final draft = container.read(transactionFormProvider);
      expect(draft.title, 'ALFAMART SUDIRMAN 12 VERIFIED');
      expect(draft.amount, 30000.0);
      expect(draft.attachmentPath, cameraImagePath);
      expect(draft.category, isNull);
      expect(draft.accountId, isNull);

      // Ensure accountsProvider FutureProvider has resolved before saving
      await tester.runAsync(() async {
        await container.read(accountsProvider.future);
      });

      // User manually chooses category & account, then saves
      final formNotifier = container.read(transactionFormProvider.notifier);
      formNotifier.setCategory(TransactionCategory.shopping);
      formNotifier.setAccount(instrumentId);

      late bool savedOk;
      await tester.runAsync(() async {
        savedOk = await formNotifier.save();
      });
      expect(savedOk, isTrue);

      final savedTx = formNotifier.lastSaved;
      expect(savedTx, isNotNull);
      expect(savedTx!.title, 'ALFAMART SUDIRMAN 12 VERIFIED');
      expect(savedTx.amount, 30000.0);

      // Verify idempotency retry returns identical transaction without duplication
      late AppTransaction retryTx;
      await tester.runAsync(() async {
        retryTx = await realTxRepo.addTransaction(
          AppTransaction(
            id: 'retry-id',
            title: savedTx.title,
            amount: savedTx.amount,
            type: savedTx.type,
            date: draft.date!,
            category: savedTx.category,
            accountId: instrumentId,
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
            idempotencyKey: draft.idempotencyKey,
          ),
        );
      });
      expect(retryTx.id, savedTx.id);

      // Fetch created transaction from real Laravel API to confirm attachment & persistence
      late AppTransaction fetched;
      await tester.runAsync(() async {
        fetched = await realTxRepo.getTransactionById(savedTx.id);
      });
      expect(fetched.attachments.length, 1);

      client.close();
    },
  );
}
