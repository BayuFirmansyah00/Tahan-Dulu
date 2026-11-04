import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/transactions/data/services/receipt_ocr_service.dart';
import 'package:tahan_dulu/features/transactions/data/services/speech_recognition_service.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/native_input_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_record_method_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_scan_screen.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_voice_screen.dart';

class MockSpeechRecognitionService implements SpeechRecognitionService {
  MockSpeechRecognitionService({
    this.hasPermission = true,
    this.requestPermissionResult = true,
    this.available = true,
    this.localeResult = 'id_ID',
    this.startListeningSuccess = true,
    this.simulatedWords = 'Makan siang dua puluh lima ribu menggunakan BCA',
  });

  bool hasPermission;
  bool requestPermissionResult;
  bool available;
  String? localeResult;
  bool startListeningSuccess;
  String simulatedWords;
  bool listening = false;

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
    listening = false;
  }

  @override
  Future<void> cancelListening() async {
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

  @override
  Future<String?> pickImageFromCamera() async => cameraImagePath;

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
  void dispose() {}
}

GoRouter _createTestRouter({
  required Widget child,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: AppRoutes.transactionAdd,
        builder: (context, state) =>
            const Scaffold(body: Text('Form Add Screen')),
      ),
      GoRoute(
        path: AppRoutes.transactionVoice,
        builder: (context, state) =>
            const Scaffold(body: Text('Voice Screen')),
      ),
      GoRoute(
        path: AppRoutes.transactionScan,
        builder: (context, state) =>
            const Scaffold(body: Text('Scan Screen')),
      ),
    ],
  );
}

Widget _createTestApp({
  required Widget child,
  List overrides = const [],
}) {
  final router = _createTestRouter(child: child);
  return ProviderScope(
    overrides: overrides.cast(),
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
      expect(
        find.text('Bagaimana kamu ingin mencatat transaksi?'),
        findsOneWidget,
      );
      expect(find.text('Input Manual'), findsOneWidget);
      expect(find.text('Input Suara'), findsOneWidget);
      expect(find.text('Scan Struk'), findsOneWidget);

      expect(
        find.text(
          'Catat pemasukan atau pengeluaran secara langsung dengan formulir lengkap.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sebutkan transaksi dan biarkan aplikasi membantu mengisi detailnya secara otomatis.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Pindai struk belanja untuk mengisi detail transaksi pengeluaran secara instan.',
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

    testWidgets('Tapping Input Suara navigates to Voice Screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TransactionRecordMethodScreen()),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Input Suara'));

      expect(find.text('Voice Screen'), findsOneWidget);
    });

    testWidgets('Tapping Scan Struk navigates to Scan Screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createTestApp(child: const TransactionRecordMethodScreen()),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Scan Struk'));

      expect(find.text('Scan Screen'), findsOneWidget);
    });
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

    testWidgets(
      'Speech recognition unavailable shows clear warning',
      (tester) async {
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
      },
    );

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
  });

  group('TransactionScanScreen Widget & OCR Service Tests', () {
    testWidgets(
      'Renders receipt scan UI with camera, gallery, and sample options',
      (tester) async {
        await tester.pumpWidget(
          _createTestApp(child: const TransactionScanScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scan Struk'), findsOneWidget);
        expect(find.text('Pindai Struk Belanja'), findsOneWidget);
        expect(find.text('Kamera'), findsOneWidget);
        expect(find.text('Galeri'), findsOneWidget);
        expect(find.text('Contoh Indomaret'), findsOneWidget);
        expect(find.text('Contoh Superindo'), findsOneWidget);
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

    testWidgets(
      'Gallery selection cancelled by user does nothing gracefully',
      (tester) async {
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

        expect(find.text('Pindai Struk Belanja'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

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
        await tester.pumpWidget(
          _createTestApp(child: const TransactionScanScreen()),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Contoh Indomaret'));

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
        await tester.pumpWidget(
          _createTestApp(child: const TransactionScanScreen()),
        );
        await tester.pumpAndSettle();

        await _tapVisible(tester, find.text('Contoh Superindo'));

        expect(find.text('SUPERINDO SUPERMARKET'), findsOneWidget);
        expect(find.text('Total Akhir Pembayaran'), findsOneWidget);
        expect(find.text('Rp 65.000'), findsWidgets); // Grand Total appears in header & details
        expect(find.text('Rp 55.000'), findsOneWidget); // Subtotal
        expect(find.text('Gunakan Data Struk di Form'), findsOneWidget);

        await _tapVisible(tester, find.text('Gunakan Data Struk di Form'));
        expect(find.text('Form Add Screen'), findsOneWidget);
      },
    );
  });
}
