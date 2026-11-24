import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/transactions/data/services/receipt_ocr_service.dart';
import 'package:tahan_dulu/features/transactions/data/services/speech_recognition_service.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/native_input_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_record_method_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_voice_screen.dart';

class _MockTransactionRepository implements TransactionRepository {
  AppTransaction? lastSaved;

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    lastSaved = transaction;
    return transaction;
  }

  @override
  Future<List<AppTransaction>> getRecentTransactions() async => [];

  @override
  Future<AppTransaction> getTransactionById(String id) async =>
      throw UnimplementedError();

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async =>
      transaction;

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    dynamic instrumentId,
    int? perPage,
    int? page,
  }) async =>
      [];
}

class MockSpeechRecognitionService implements SpeechRecognitionService {
  MockSpeechRecognitionService({
    this.hasPermission = true,
    this.requestPermissionResult = true,
    this.permanentlyDenied = false,
    this.available = true,
    this.localeResult = 'id_ID',
    this.startListeningSuccess = true,
    this.simulatedWords = 'Makan siang dua puluh lima ribu menggunakan BCA',
  });

  bool hasPermission;
  bool requestPermissionResult;
  bool permanentlyDenied;
  bool available;
  String? localeResult;
  bool startListeningSuccess;
  String simulatedWords;
  bool listening = false;
  int stopListeningCalls = 0;
  int cancelListeningCalls = 0;
  int openSettingsCalls = 0;

  @override
  bool get isListening => listening;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> checkMicrophonePermission() async => hasPermission;

  @override
  Future<bool> requestMicrophonePermission() async {
    hasPermission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<bool> isMicrophonePermanentlyDenied() async => permanentlyDenied;

  @override
  Future<bool> openPermissionSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (!available) {
      onError?.call('Speech recognition not available on this device');
      return false;
    }
    return true;
  }

  @override
  Future<String?> findIndonesianLocale() async => localeResult;

  @override
  Future<bool> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (!startListeningSuccess) return false;
    listening = true;
    onResult(simulatedWords, true);
    listening = false;
    return true;
  }

  @override
  Future<void> stopListening() async {
    stopListeningCalls++;
    listening = false;
  }

  @override
  Future<void> cancelListening() async {
    cancelListeningCalls++;
    listening = false;
  }

  @override
  void dispose() {
    listening = false;
  }
}

class MockReceiptOcrService implements ReceiptOcrService {
  MockReceiptOcrService({
    this.cameraImagePath,
    this.galleryImagePath,
    this.recognizedTextResult = '',
    this.shouldThrowOnOcr = false,
  });

  String? cameraImagePath;
  String? galleryImagePath;
  String recognizedTextResult;
  bool shouldThrowOnOcr;
  final List<String> deletedTempImages = [];
  final Set<String> registeredTempFiles = {};

  @override
  Future<String?> pickImageFromCamera() async {
    if (cameraImagePath != null) {
      registeredTempFiles.add(cameraImagePath!);
    }
    return cameraImagePath;
  }

  @override
  Future<String?> pickImageFromGallery() async => galleryImagePath;

  @override
  Future<String> recognizeText(String imagePath) async {
    if (shouldThrowOnOcr) {
      throw Exception('OCR engine failure');
    }
    return recognizedTextResult;
  }

  @override
  Future<void> deleteTempImage(String? imagePath) async {
    if (imagePath != null && registeredTempFiles.contains(imagePath)) {
      deletedTempImages.add(imagePath);
      registeredTempFiles.remove(imagePath);
    }
  }

  @override
  Future<void> cleanupAllTempImages() async {
    deletedTempImages.addAll(registeredTempFiles);
    registeredTempFiles.clear();
  }

  @override
  void dispose() {
    cleanupAllTempImages();
  }
}

GoRouter _createTestRouter({required Widget child}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (context, state) =>
            const Scaffold(body: Text('Form Add Screen')),
      ),
      GoRoute(
        path: AppRoutes.transactionVoice,
        builder: (context, state) => const Scaffold(body: Text('Voice Screen')),
      ),
      GoRoute(
        path: AppRoutes.transactionScan,
        builder: (context, state) => const Scaffold(body: Text('Scan Screen')),
      ),
    ],
  );
}

Widget _createTestApp({required Widget child, List overrides = const []}) {
  final router = _createTestRouter(child: child);
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final sampleAccounts = [
    const FinancialAccount(
      id: 'acc-1',
      name: 'BCA',
      type: AccountType.bank,
      balance: 5000000,
      institutionName: 'Bank Central Asia',
    ),
    const FinancialAccount(
      id: 'acc-2',
      name: 'Mandiri',
      type: AccountType.bank,
      balance: 2000000,
      institutionName: 'Bank Mandiri',
    ),
  ];

  group('TransactionRecordMethodScreen Widget Tests', () {
    testWidgets('Renders all three transaction recording methods', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TransactionRecordMethodScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilih Metode Catat'), findsOneWidget);
      expect(find.text('Catat Transaksi'), findsOneWidget);
      expect(find.text('Lebih Mudah'), findsOneWidget);
      expect(
        find.text('Pilih cara mencatat yang paling nyaman buatmu.'),
        findsOneWidget,
      );
      expect(find.text('Input Manual'), findsOneWidget);
      expect(find.text('Input Suara'), findsOneWidget);
      expect(find.text('Scan Struk'), findsOneWidget);

      expect(find.text('Catat transaksi secara langsung'), findsOneWidget);
      expect(find.text('Cukup ucapkan transaksimu'), findsOneWidget);
      expect(find.text('Pindai struk secara otomatis'), findsOneWidget);
      expect(
        find.text(
          'Semua transaksi bisa diperiksa dan diedit sebelum disimpan.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Input Manual navigates to Form and resets draft', (
      tester,
    ) async {
      final container = ProviderContainer();
      container.read(transactionFormProvider.notifier).setAmount(999999);

      final router = _createTestRouter(
        child: const TransactionRecordMethodScreen(),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Input Manual'));

      expect(find.text('Form Add Screen'), findsOneWidget);
      expect(container.read(transactionFormProvider).amount, equals(0));
    });

    testWidgets(
      'INT-04: Tapping Input Suara navigates to Voice Screen and resets existing draft',
      (tester) async {
        final container = ProviderContainer();
        container.read(transactionFormProvider.notifier).setAmount(750000);

        final router = _createTestRouter(
          child: const TransactionRecordMethodScreen(),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Input Suara'));

        expect(find.text('Voice Screen'), findsOneWidget);
        expect(container.read(transactionFormProvider).amount, equals(0));
      },
    );

    testWidgets(
      'INT-04: Tapping Scan Struk navigates to Scan Screen and resets existing draft',
      (tester) async {
        final container = ProviderContainer();
        container.read(transactionFormProvider.notifier).setAmount(320000);

        final router = _createTestRouter(
          child: const TransactionRecordMethodScreen(),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Scan Struk'));

        expect(find.text('Scan Screen'), findsOneWidget);
        expect(container.read(transactionFormProvider).amount, equals(0));
      },
    );
  });

  group('TransactionVoiceScreen Widget & Native Service Tests', () {
    testWidgets('Renders voice UI with mic button and sample chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(
          overrides: [
            accountsProvider.overrideWith(
              (ref) => Future.value(sampleAccounts),
            ),
          ],
          child: const TransactionVoiceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Input Suara'), findsOneWidget);
      expect(find.text('Sebutkan transaksimu'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Atau coba contoh ucapan berikut:'), findsOneWidget);
      expect(
        find.text('Makan siang dua puluh lima ribu menggunakan BCA'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Microphone permission granted starts listening and extracts transaction',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService(
          hasPermission: false,
          requestPermissionResult: true,
          available: true,
          simulatedWords: 'Beli bensin lima puluh ribu pakai Mandiri',
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap microphone
        await _tapVisible(tester, find.byIcon(Icons.mic_rounded));

        // Transcription & parsed result should appear
        expect(
          find.text('"Beli bensin lima puluh ribu pakai Mandiri"'),
          findsOneWidget,
        );
        expect(find.text('Rp 50.000'), findsOneWidget);
        expect(find.text('Mandiri'), findsOneWidget);
        expect(find.text('Lanjutkan ke Form Transaksi'), findsOneWidget);
      },
    );

    testWidgets(
      'Microphone permission denied displays error and guidance dialog',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService(
          hasPermission: false,
          requestPermissionResult: false, // User denies permission
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap microphone
        await _tapVisible(tester, find.byIcon(Icons.mic_rounded));

        // Permission dialog should appear
        expect(find.text('Izin Mikrofon Diperlukan'), findsOneWidget);
        expect(find.text('Tutup'), findsOneWidget);
        await _tapVisible(tester, find.text('Tutup'));

        // Error message on screen
        expect(find.textContaining('Izin mikrofon diperlukan'), findsOneWidget);
      },
    );

    testWidgets('Speech recognition unavailable shows clear warning', (
      tester,
    ) async {
      final mockSpeech = MockSpeechRecognitionService(
        hasPermission: true,
        available: false, // Speech recognition unsupported
      );

      await tester.pumpWidget(
        _createTestApp(
          overrides: [
            accountsProvider.overrideWith(
              (ref) => Future.value(sampleAccounts),
            ),
            speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
          ],
          child: const TransactionVoiceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byIcon(Icons.mic_rounded));

      expect(
        find.textContaining('Pengenalan suara tidak didukung atau belum siap'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Empty speech transcription displays no speech detected message',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService(
          hasPermission: true,
          available: true,
          simulatedWords: '', // No speech detected
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.byIcon(Icons.mic_rounded));

        expect(find.textContaining('Suara tidak terdengar'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping sample voice chip parses and allows editing transcription',
      (tester) async {
        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.text('Makan siang dua puluh lima ribu menggunakan BCA'),
        );

        expect(
          find.text('"Makan siang dua puluh lima ribu menggunakan BCA"'),
          findsOneWidget,
        );
        expect(find.text('Rp 25.000'), findsOneWidget);

        // Edit transcription
        await _tapVisible(tester, find.byTooltip('Sunting'));
        expect(find.byType(TextField), findsOneWidget);

        // Save edited transcription
        await _tapVisible(tester, find.byTooltip('Simpan'));
        expect(find.text('Lanjutkan ke Form Transaksi'), findsOneWidget);

        // Navigate to form
        await _tapVisible(tester, find.text('Lanjutkan ke Form Transaksi'));
        expect(find.text('Form Add Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'INT-05: Disposing TransactionVoiceScreen cancels speech recognition service',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService();

        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(mockSpeech.cancelListeningCalls, equals(0));

        // Unmount TransactionVoiceScreen by replacing with an empty SizedBox
        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              accountsProvider.overrideWith(
                (ref) => Future.value(sampleAccounts),
              ),
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();

        // cancelListening should have been called upon dispose
        expect(mockSpeech.cancelListeningCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'B3-06: Microphone permission permanently denied shows dialog with Buka Pengaturan button',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService(
          hasPermission: false,
          requestPermissionResult: false,
          permanentlyDenied: true,
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [
              speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
            ],
            child: const TransactionVoiceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.byIcon(Icons.mic_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Izin Mikrofon Diperlukan'), findsOneWidget);
        expect(find.text('Buka Pengaturan'), findsOneWidget);

        await tester.tap(find.text('Buka Pengaturan'));
        await tester.pumpAndSettle();

        expect(mockSpeech.openSettingsCalls, 1);
      },
    );

    testWidgets(
      'B3-04: Confirming voice transaction sets draft title to cleaned description',
      (tester) async {
        final mockSpeech = MockSpeechRecognitionService(
          simulatedWords: 'Beli bensin lima puluh ribu pakai BCA',
        );

        final container = ProviderContainer(
          overrides: [
            accountsProvider.overrideWith(
              (ref) => Future.value(sampleAccounts),
            ),
            speechRecognitionServiceProvider.overrideWithValue(mockSpeech),
          ],
        );

        final router = _createTestRouter(child: const TransactionVoiceScreen());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.byIcon(Icons.mic_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Lanjutkan ke Form Transaksi'), findsOneWidget);
        await _tapVisible(tester, find.text('Lanjutkan ke Form Transaksi'));
        await tester.pumpAndSettle();

        final draft = container.read(transactionFormProvider);
        expect(draft.title, 'Beli bensin');
        expect(draft.note, 'Beli bensin');
        expect(draft.amount, 50000.0);
      },
    );
  });

  group('TransactionScanScreen Widget & OCR Service Tests', () {
    testWidgets(
      'Renders receipt scan UI with hero, camera, gallery, and steps',
      (tester) async {
        await tester.pumpWidget(
          _createTestApp(child: const TransactionScanScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scan Struk'), findsOneWidget);
        expect(find.text('Catat dari struk,'), findsOneWidget);
        expect(find.text('lebih praktis.'), findsOneWidget);
        expect(find.text('Pilih sumber struk'), findsOneWidget);
        expect(find.text('Kamera'), findsOneWidget);
        expect(find.text('Galeri'), findsOneWidget);
        expect(find.text('Cara Kerja'), findsOneWidget);
        expect(find.text('Ambil foto'), findsOneWidget);
        expect(find.text('Baca data'), findsOneWidget);
        expect(find.text('Periksa hasil'), findsOneWidget);
        expect(
          find.text(
            'Struk diproses di perangkat. Hasil dapat diperiksa sebelum disimpan.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Camera capture runs OCR and populates receipt details', (
      tester,
    ) async {
      const ocrOutput = '''SUPERINDO SUPERMARKET
TANGGAL: 2026-10-30
SUBTOTAL 55.000
ONGKOS PACKING 10.000
GRAND TOTAL 65.000''';

      final mockOcr = MockReceiptOcrService(
        cameraImagePath: 'C:/fake/path/struk.jpg',
        recognizedTextResult: ocrOutput,
      );

      await tester.pumpWidget(
        _createTestApp(
          overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
          child: const TransactionScanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Kamera
      await _tapVisible(tester, find.text('Kamera'));

      // Extracted details
      expect(find.text('SUPERINDO SUPERMARKET'), findsOneWidget);
      expect(find.text('Rp 65.000'), findsOneWidget);
      expect(find.text('Rp 55.000'), findsOneWidget); // Subtotal
      expect(find.text('Gunakan Data Struk di Form'), findsOneWidget);

      // Tap continue to form
      await _tapVisible(tester, find.text('Gunakan Data Struk di Form'));
      expect(find.text('Form Add Screen'), findsOneWidget);
    });

    testWidgets('Gallery selection cancelled by user does nothing gracefully', (
      tester,
    ) async {
      final mockOcr = MockReceiptOcrService(
        galleryImagePath: null, // User cancelled gallery picker
      );

      await tester.pumpWidget(
        _createTestApp(
          overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
          child: const TransactionScanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Galeri'));

      expect(find.text('Pilih sumber struk'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('OCR engine failure displays clear error banner', (
      tester,
    ) async {
      final mockOcr = MockReceiptOcrService(
        cameraImagePath: 'C:/fake/path/corrupt.jpg',
        shouldThrowOnOcr: true,
      );

      await tester.pumpWidget(
        _createTestApp(
          overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
          child: const TransactionScanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Kamera'));

      expect(
        find.textContaining('Gagal membaca struk dengan OCR'),
        findsOneWidget,
      );
    });

    testWidgets('OCR empty text output displays unreadable image warning', (
      tester,
    ) async {
      final mockOcr = MockReceiptOcrService(
        cameraImagePath: 'C:/fake/path/blank.jpg',
        recognizedTextResult: '    ', // Blank OCR text
      );

      await tester.pumpWidget(
        _createTestApp(
          overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
          child: const TransactionScanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Kamera'));

      expect(
        find.textContaining('Teks struk tidak terbaca atau buram'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Loading sample Indomaret receipt extracts merchant and grand total',
      (tester) async {
        final mockOcr = MockReceiptOcrService(
          cameraImagePath: 'C:/fake/path/indomaret.jpg',
          recognizedTextResult: TransactionScanScreen.sampleIndomaret,
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const TransactionScanScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Kamera'));

        expect(find.text('INDOMARET POINT'), findsOneWidget);
        expect(find.text('Total Akhir Pembayaran'), findsOneWidget);
        expect(find.text('Rp 25.000'), findsWidgets);
        expect(find.text('Gunakan Data Struk di Form'), findsOneWidget);

        await _tapVisible(tester, find.text('Gunakan Data Struk di Form'));
        expect(find.text('Form Add Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Loading sample Superindo receipt prioritizes grand total over subtotal',
      (tester) async {
        final mockOcr = MockReceiptOcrService(
          cameraImagePath: 'C:/fake/path/superindo.jpg',
          recognizedTextResult: TransactionScanScreen.sampleSuperindo,
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const TransactionScanScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Kamera'));

        expect(find.text('SUPERINDO SUPERMARKET'), findsOneWidget);
        expect(find.text('Total Akhir Pembayaran'), findsOneWidget);
        expect(
          find.text('Rp 65.000'),
          findsWidgets,
        ); // Grand Total appears in header & details
        expect(find.text('Rp 55.000'), findsOneWidget); // Subtotal
        expect(find.text('Gunakan Data Struk di Form'), findsOneWidget);

        await _tapVisible(tester, find.text('Gunakan Data Struk di Form'));
        expect(find.text('Form Add Screen'), findsOneWidget);
      },
    );

    testWidgets('Programmatic loadSampleReceipt populates receipt details', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TransactionScanScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(TransactionScanScreen)) as dynamic;
      state.loadSampleReceipt(TransactionScanScreen.sampleIndomaret);
      await tester.pumpAndSettle();

      expect(find.text('INDOMARET POINT'), findsOneWidget);
      expect(find.text('Total Akhir Pembayaran'), findsOneWidget);
      expect(find.text('Rp 25.000'), findsWidgets);
    });

    testWidgets(
      'B3-04: Confirming scan transaction sets draft title to merchant name without duplicating merchant in note',
      (tester) async {
        final mockOcr = MockReceiptOcrService(
          cameraImagePath: 'C:/fake/path/indomaret_sample.jpg',
          recognizedTextResult: TransactionScanScreen.sampleIndomaret,
        );

        final container = ProviderContainer(
          overrides: [
            accountsProvider.overrideWith(
              (ref) => Future.value(sampleAccounts),
            ),
            receiptOcrServiceProvider.overrideWithValue(mockOcr),
          ],
        );

        final router = _createTestRouter(child: const TransactionScanScreen());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Kamera'));
        expect(find.text('Gunakan Data Struk di Form'), findsOneWidget);

        await _tapVisible(tester, find.text('Gunakan Data Struk di Form'));
        await tester.pumpAndSettle();

        final draft = container.read(transactionFormProvider);
        expect(draft.title, 'INDOMARET POINT');
        expect(draft.amount, 25000.0);
        // Merchant must NOT be duplicated inside note
        expect(draft.note.contains('INDOMARET POINT'), isFalse);
        expect(draft.note.contains('Item:'), isTrue);
      },
    );

    testWidgets(
      'B3-05: Disposing TransactionScanScreen deletes temporary camera image',
      (tester) async {
        const testPath = 'C:/fake/path/temp_camera_photo.jpg';
        final mockOcr = MockReceiptOcrService(
          cameraImagePath: testPath,
          recognizedTextResult: TransactionScanScreen.sampleIndomaret,
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const TransactionScanScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Kamera'));
        expect(mockOcr.registeredTempFiles.contains(testPath), isTrue);

        // Replace scan screen to trigger dispose
        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();

        expect(mockOcr.deletedTempImages.contains(testPath), isTrue);
      },
    );

    testWidgets(
      'B3-05: Picking gallery image does not delete it when screen is disposed',
      (tester) async {
        const galleryPath = 'C:/user/gallery/receipt_orig.jpg';
        final mockOcr = MockReceiptOcrService(
          galleryImagePath: galleryPath,
          recognizedTextResult: TransactionScanScreen.sampleIndomaret,
        );

        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const TransactionScanScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Galeri'));
        expect(mockOcr.registeredTempFiles.isEmpty, isTrue);

        // Replace scan screen to trigger dispose
        await tester.pumpWidget(
          _createTestApp(
            overrides: [receiptOcrServiceProvider.overrideWithValue(mockOcr)],
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();

        expect(mockOcr.deletedTempImages.contains(galleryPath), isFalse);
      },
    );
  });

  group('TransactionFormController Title & Save Fallback Tests', () {
    test('B3-04: save() uses explicit title and clamps to 255 chars if very long', () async {
      final mockRepo = _MockTransactionRepository();
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
          accountsProvider.overrideWith(
            (ref) => Future.value(sampleAccounts),
          ),
        ],
      );
      await container.read(accountsProvider.future);

      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.expense);
      notifier.setAmount(50000);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('acc-1');
      notifier.setDate(DateTime(2026, 11, 8));
      final longTitle = 'Supermarket ' * 30; // ~360 chars
      notifier.setTitle(longTitle);

      final success = await notifier.save();
      expect(success, isTrue);
      expect(mockRepo.lastSaved, isNotNull);
      expect(mockRepo.lastSaved!.title.length, lessThanOrEqualTo(255));
      expect(mockRepo.lastSaved!.title.startsWith('Supermarket'), isTrue);
      expect(mockRepo.lastSaved!.category, 'Makanan');
    });

    test('B3-04: save() falls back to categoryLabel when title is empty', () async {
      final mockRepo = _MockTransactionRepository();
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepo),
          accountsProvider.overrideWith(
            (ref) => Future.value(sampleAccounts),
          ),
        ],
      );
      await container.read(accountsProvider.future);

      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setType(TransactionType.expense);
      notifier.setAmount(20000);
      notifier.setCategory(TransactionCategory.transport);
      notifier.setAccount('acc-2');
      notifier.setDate(DateTime(2026, 11, 8));
      // title remains empty

      final success = await notifier.save();
      expect(success, isTrue);
      expect(mockRepo.lastSaved, isNotNull);
      expect(mockRepo.lastSaved!.title, 'Transportasi');
      expect(mockRepo.lastSaved!.category, 'Transportasi');
    });
  });
}
