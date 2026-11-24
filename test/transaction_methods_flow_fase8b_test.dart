import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/transactions/data/services/receipt_ocr_service.dart';
import 'package:tahan_dulu/features/transactions/data/services/speech_recognition_service.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/native_input_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_record_method_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_review_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_voice_screen.dart';

class _MockSpeechService implements SpeechRecognitionService {
  _MockSpeechService({
    this.words = 'Catat pengeluaran makan siang 25 ribu pakai BCA.',
  });

  String words;
  bool listening = false;
  int cancelCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => listening;

  @override
  Future<bool> checkMicrophonePermission() async => true;

  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<bool> isMicrophonePermanentlyDenied() async => false;

  @override
  Future<bool> openPermissionSettings() async => true;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async =>
      true;

  @override
  Future<String?> findIndonesianLocale() async => 'id_ID';

  @override
  Future<bool> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    String? localeId,
  }) async {
    listening = true;
    onResult(words, true);
    return true;
  }

  @override
  Future<void> stopListening() async {
    listening = false;
  }

  @override
  Future<void> cancelListening() async {
    cancelCalls++;
    listening = false;
  }

  @override
  void dispose() {
    listening = false;
  }
}

class _MockOcrService implements ReceiptOcrService {
  _MockOcrService({required this.recognizedText});

  String recognizedText;

  @override
  Future<String?> pickImageFromCamera() async => 'mock/path/camera.jpg';

  @override
  Future<String?> pickImageFromGallery() async => 'mock/path/gallery.jpg';

  @override
  Future<String> recognizeText(String imagePath) async => recognizedText;

  @override
  Future<void> deleteTempImage(String? imagePath) async {}

  @override
  Future<void> cleanupAllTempImages() async {}

  @override
  void dispose() {}
}

class _InMemoryTransactionRepo implements TransactionRepository {
  final List<AppTransaction> items = [];

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    items.insert(0, transaction);
    return transaction;
  }

  @override
  Future<List<AppTransaction>> getRecentTransactions() async => List.of(items);

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    dynamic instrumentId,
    int? perPage,
    int? page,
  }) async =>
      List.of(items);

  @override
  Future<TransactionPaginationResult> getPaginatedTransactions({
    String? type,
    String? category,
    String? instrumentId,
    int? perPage,
    int? page,
  }) async {
    return TransactionPaginationResult(
      items: List.of(items),
      currentPage: 1,
      lastPage: 1,
      perPage: perPage ?? 20,
      total: items.length,
      hasNextPage: false,
    );
  }

  @override
  Future<AppTransaction> getTransactionById(String id) async =>
      items.firstWhere((e) => e.id == id);

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async {
    final idx = items.indexWhere((e) => e.id == transaction.id);
    if (idx != -1) items[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<String> uploadReceiptAttachment(String transactionId, String filePath) async => '';

  @override
  Future<void> deleteReceiptAttachment(String transactionId, String attachmentId) async {}
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.transactionRecordMethod,
    routes: [
      GoRoute(
        path: AppRoutes.transactionRecordMethod,
        builder: (context, state) => const TransactionRecordMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionVoice,
        builder: (context, state) => const TransactionVoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionScan,
        builder: (context, state) => const TransactionScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionReview,
        builder: (context, state) => const TransactionReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionSuccess,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Halaman Sukses Transaksi')),
        ),
      ),
    ],
  );
}

Widget _buildApp({
  required GoRouter router,
  required List<FinancialAccount> accounts,
  TransactionRepository? repo,
  SpeechRecognitionService? speechService,
  ReceiptOcrService? ocrService,
}) {
  return ProviderScope(
    overrides: [
      accountsProvider.overrideWith((ref) => Future.value(accounts)),
      if (repo != null)
        transactionRepositoryProvider.overrideWithValue(repo),
      if (speechService != null)
        speechRecognitionServiceProvider.overrideWithValue(speechService),
      if (ocrService != null)
        receiptOcrServiceProvider.overrideWithValue(ocrService),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final testAccounts = [
    const FinancialAccount(
      id: 'acc-bca',
      name: 'BCA',
      type: AccountType.bank,
      balance: 5000000,
      institutionName: 'Bank Central Asia',
    ),
    const FinancialAccount(
      id: 'acc-mandiri',
      name: 'Mandiri',
      type: AccountType.bank,
      balance: 3000000,
      institutionName: 'Bank Mandiri',
    ),
  ];

  group('Fase 8B: Three-Method Transaction Flow Integration Tests', () {
    testWidgets('Metode 1: Manual Input -> Review -> Simpan', (tester) async {
      final repo = _InMemoryTransactionRepo();
      final router = _createRouter();

      await tester.pumpWidget(
        _buildApp(
          router: router,
          accounts: testAccounts,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pilih Input Manual
      await _tap(tester, find.text('Input Manual'));
      expect(find.text(AppStrings.addTransaction), findsOneWidget);

      // Pastikan banner Voice/Scan tidak muncul saat manual
      expect(find.text('Data Terisi dari Input Suara'), findsNothing);
      expect(find.text('Data Terisi dari Scan Struk'), findsNothing);

      // 2. Isi form: Nominal 50.000
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '50000');
      await tester.pumpAndSettle();

      // 3. Pilih Kategori: Makanan
      await _tap(tester, find.text('Makanan'));

      // 4. Pilih Rekening: BCA
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.textContaining('BCA').last);

      // 5. Periksa Transaksi (ke layar Review)
      await _tap(tester, find.text(AppStrings.reviewAction));
      expect(find.text(AppStrings.reviewTitle), findsOneWidget);
      expect(find.textContaining('50.000'), findsWidgets);

      // 6. Simpan Transaksi
      await _tap(tester, find.text(AppStrings.saveTransaction));
      expect(find.text('Halaman Sukses Transaksi'), findsOneWidget);

      // Verifikasi repositori tersimpan tepat 1 kali
      expect(repo.items.length, equals(1));
      expect(repo.items.first.amount, equals(50000.0));
      expect(repo.items.first.accountId, equals('acc-bca'));
      expect(repo.items.first.type, equals(TransactionType.expense));
      expect(repo.items.first.idempotencyKey, isNotEmpty);
    });

    testWidgets('Metode 2: Voice Recognition -> Auto-fill Form -> Edit -> Simpan', (tester) async {
      final repo = _InMemoryTransactionRepo();
      final router = _createRouter();
      final mockSpeech = _MockSpeechService(
        words: 'Catat pengeluaran makan siang 25 ribu pakai BCA.',
      );

      await tester.pumpWidget(
        _buildApp(
          router: router,
          accounts: testAccounts,
          repo: repo,
          speechService: mockSpeech,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pilih Input Suara
      await _tap(tester, find.text('Input Suara'));
      expect(find.text('Input Suara'), findsOneWidget);

      // 2. Tekan mic untuk merekam
      await _tap(tester, find.byIcon(Icons.mic_rounded));
      expect(find.textContaining('makan siang 25 ribu'), findsOneWidget);

      // 3. Konfirmasi & Lanjutkan ke Form Transaksi
      await _tap(tester, find.text('Lanjutkan ke Form Transaksi'));
      expect(find.text(AppStrings.addTransaction), findsOneWidget);

      // Banner konteks suara harus muncul
      expect(find.text('Data Terisi dari Input Suara'), findsOneWidget);

      // Field terisi otomatis tanpa perlu mengetik ulang
      expect(find.text('25.000'), findsOneWidget);
      expect(find.text('Makan siang'), findsWidgets);

      // 4. Lanjut ke Review
      await _tap(tester, find.text(AppStrings.reviewAction));
      expect(find.text(AppStrings.reviewTitle), findsOneWidget);
      expect(find.textContaining('25.000'), findsWidgets);

      // 5. Simpan
      await _tap(tester, find.text(AppStrings.saveTransaction));
      expect(find.text('Halaman Sukses Transaksi'), findsOneWidget);

      expect(repo.items.length, equals(1));
      expect(repo.items.first.amount, equals(25000.0));
      expect(repo.items.first.title, equals('Makan siang'));
      expect(repo.items.first.accountId, equals('acc-bca'));
    });

    testWidgets('Metode 3: Receipt OCR Scan -> Auto-fill Form -> Pilih Akun -> Simpan', (tester) async {
      final repo = _InMemoryTransactionRepo();
      final router = _createRouter();
      const sampleReceipt = '''
SUPERMARKET NUSANTARA
02/11/2026 14:30
-----------------------------
BERAS PREMIUM 5KG    75.000
MINYAK GORENG 2L     25.000
-----------------------------
Subtotal: Rp100.000
Diskon: Rp10.000
PPN: Rp9.900
Total Bayar: Rp99.900
TUNAI: Rp100.000
KEMBALIAN: Rp100
TERIMA KASIH
''';
      final mockOcr = _MockOcrService(recognizedText: sampleReceipt);

      await tester.pumpWidget(
        _buildApp(
          router: router,
          accounts: testAccounts,
          repo: repo,
          ocrService: mockOcr,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pilih Scan Struk
      await _tap(tester, find.text('Scan Struk'));
      expect(find.text('Scan Struk'), findsOneWidget);

      // 2. Ambil dari kamera
      await _tap(tester, find.text('Kamera'));
      expect(find.text('Informasi Struk yang Dikenali'), findsOneWidget);
      expect(find.text('SUPERMARKET NUSANTARA'), findsOneWidget);
      expect(find.textContaining('99.900'), findsWidgets);

      // 3. Lanjutkan ke formulir
      await _tap(tester, find.text('Gunakan Data Struk di Form'));
      expect(find.text(AppStrings.addTransaction), findsOneWidget);

      // Banner konteks struk muncul
      expect(find.text('Data Terisi dari Scan Struk'), findsOneWidget);

      // Nominal final otomatis 99.900
      expect(find.text('99.900'), findsOneWidget);

      // Kategori belum dipilih oleh parser (wajib dipilih pengguna)
      // Pengguna memilih Belanja
      await _tap(tester, find.text('Belanja'));

      // Rekening belum dipilih oleh parser (wajib dipilih pengguna)
      // Pengguna memilih Mandiri
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.textContaining('Mandiri').last);

      // 4. Periksa Transaksi
      await _tap(tester, find.text(AppStrings.reviewAction));
      expect(find.text(AppStrings.reviewTitle), findsOneWidget);
      expect(find.textContaining('99.900'), findsWidgets);

      // 5. Simpan
      await _tap(tester, find.text(AppStrings.saveTransaction));
      expect(find.text('Halaman Sukses Transaksi'), findsOneWidget);

      expect(repo.items.length, equals(1));
      expect(repo.items.first.amount, equals(99900.0));
      expect(repo.items.first.title, equals('SUPERMARKET NUSANTARA'));
      expect(repo.items.first.accountId, equals('acc-mandiri'));
    });

    testWidgets('Responsive Form Testing: 360dp, 393dp, dan 412dp', (tester) async {
      for (final width in [360.0, 393.0, 412.0]) {
        tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final router = _createRouter();
        await tester.pumpWidget(
          _buildApp(
            router: router,
            accounts: testAccounts,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pilih Metode Catat'), findsOneWidget);
        expect(find.text('Input Manual'), findsOneWidget);
        expect(find.text('Input Suara'), findsOneWidget);
        expect(find.text('Scan Struk'), findsOneWidget);
      }
    });
  });
}
